[CmdletBinding()]
param(
    [Parameter(Position=0)][ValidateSet('doctor','build','check','test','studio','dev','stop','status','mode','sync','research','audit','setup-agents','publish','references')][string]$Command='status',
    [ValidateSet('Server','Client')][string]$Mode,
    [string]$Query,
    [string]$Message='Checkpoint verified development changes',
    [switch]$AutoCheckpoint,
    [switch]$StudioChecks,
    [switch]$Execute,
    [string]$Evidence,
    [ValidateSet('Smoke','Regression','Research','Multiplayer','Audit','Foundation')][string]$Suite='Foundation'
)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'scripts/lib/Project.psm1') -Force
Initialize-ApexEnvironment
Push-Location $PSScriptRoot
try {
    switch ($Command) {
        'doctor' { & ./scripts/doctor.ps1 }
        'status' {
            git status --short --branch
            if (Test-Path .local/dev-session.json) { Get-Content .local/dev-session.json }
            if (Test-Path .local/generated/source-snapshot.json) { (Get-Content .local/generated/source-snapshot.json -Raw | ConvertFrom-Json).fingerprint }
        }
        'build' {
            & ./scripts/build.ps1
        }
        'check' { & ./scripts/check.ps1 }
        'test' { & ./scripts/check.ps1; & ./scripts/studio-test.ps1 -Suite $Suite }
        'studio' { & ./scripts/studio-test.ps1 -Suite $Suite }
        'mode' {
            if (-not $Mode) { throw 'Specify -Mode Server or -Mode Client' }
            $path=Join-Path $PSScriptRoot 'src/config/Runtime.luau'
            $source=[IO.File]::ReadAllText($path)
            $source=[regex]::Replace($source,'simulationHost = "(Server|Client)"','simulationHost = "'+$Mode+'"')
            [IO.File]::WriteAllText($path,$source)
            & ./apex.ps1 build
            Write-Output "Simulation host: $Mode. Restart play mode after Rojo synchronizes; this is ordinary ownership, not rollback Server Authority."
        }
        'dev' { & ./scripts/dev.ps1 -AutoCheckpoint:$AutoCheckpoint -StudioChecks:$StudioChecks }
        'stop' { & ./scripts/dev.ps1 -Stop }
        'sync' { & ./scripts/sync.ps1 -Message $Message -StudioChecks:$StudioChecks }
        'audit' { & ./scripts/audit-studio.ps1 }
        'publish' { & ./scripts/publish.ps1 -Execute:$Execute -Evidence $Evidence }
        'setup-agents' { & ./scripts/setup-agent-tools.ps1; & ./scripts/fetch-references.ps1; & ./scripts/configure-agents.ps1 }
        'references' { & ./scripts/fetch-references.ps1 }
        'research' {
            if (-not $Query) { throw 'Specify -Query with a research term or equation ID' }
            Get-ChildItem docs/research,docs/adr -File -Recurse | Where-Object Extension -EQ '.md' | Select-String -SimpleMatch $Query | Select-Object -First 12 Path,LineNumber,Line
            if (Test-Path .local/research/roblox-vehicle-physics-kb/docs) {
                Get-ChildItem .local/research/roblox-vehicle-physics-kb/docs -Filter '*.md' | Select-String -SimpleMatch $Query | Select-Object -First 12 Path,LineNumber,Line
            }
        }
    }
} finally { Pop-Location }
