[CmdletBinding()]
param([switch]$AutoCheckpoint,[switch]$StudioChecks)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
Set-Location $root
$last=''
$healthPath=Join-Path $root '.local/dev-health.json'
while ($true) {
    Start-Sleep -Milliseconds 1500
    $current=Get-ApexWorktreeFingerprint
    if ($current -eq $last) { continue }
    Start-Sleep -Milliseconds 1500
    $stable=Get-ApexWorktreeFingerprint
    if ($stable -ne $current) { continue }
    try {
        if ($AutoCheckpoint) { & ./scripts/sync.ps1 -StudioChecks:$StudioChecks }
        else { & ./scripts/check.ps1; if ($StudioChecks) { & ./scripts/studio-test.ps1 -Suite Foundation } }
        if ((Get-ApexWorktreeFingerprint) -ne $stable) { throw 'Files changed during background verification; result cancelled' }
        $health=@{success=$true;verifiedAtUtc=[DateTime]::UtcNow.ToString('o');fingerprint=$stable;githubCheckpoints=[bool]$AutoCheckpoint;studioChecks=[bool]$StudioChecks}
    } catch {
        $health=@{success=$false;verifiedAtUtc=[DateTime]::UtcNow.ToString('o');fingerprint=$stable;error=$_.Exception.Message;githubCheckpoints=[bool]$AutoCheckpoint;studioChecks=[bool]$StudioChecks}
    }
    $health | ConvertTo-Json | Set-Content -LiteralPath $healthPath -Encoding utf8
    $last=$stable
}
