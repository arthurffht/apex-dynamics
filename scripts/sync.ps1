[CmdletBinding()]
param([string]$Message='Checkpoint verified development changes')
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
Push-Location $root
try {
    $before=Get-ApexWorktreeFingerprint
    $head=(& git rev-parse HEAD).Trim()
    & ./scripts/check.ps1
    if ((Get-ApexWorktreeFingerprint) -ne $before -or (& git rev-parse HEAD).Trim() -ne $head) { throw 'Files or HEAD changed during verification; checkpoint cancelled' }
    $branch=(& git branch --show-current).Trim()
    if (-not $branch) { throw 'Cannot synchronize a detached HEAD' }
    $dirty=(& git status --porcelain) -join ''
    if ($branch -eq 'main') {
        if (-not $dirty) { Write-Output 'Main is clean; no checkpoint needed'; return }
        $branch='work/checkpoint-'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
        Invoke-ApexTool git @('switch','-c',$branch)
    }
    if ($dirty) {
        Invoke-ApexTool git @('add','--all')
        Invoke-ApexTool git @('diff','--cached','--check')
        Invoke-ApexTool git @('commit','-m',$Message)
    }
    Invoke-ApexTool git @('push','--set-upstream','origin',$branch)
    $existing=& gh pr list --head $branch --state open --json number --jq 'length'
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect checkpoint pull requests' }
    if ($existing -eq '0') {
        $body=Join-Path $root '.local/checkpoint-pr.md'
        [IO.File]::WriteAllText($body,"Verified development checkpoint from the local workflow.`n`nFormat, lint, strict types, numerical invariants, and artifact checks passed before this commit. Studio and cloud validation are separate gates. This pull request keeps main reviewable and protected.`n")
        Invoke-ApexTool gh @('pr','create','--base','main','--head',$branch,'--title',$Message,'--body-file',$body)
    }
} finally { Pop-Location }
