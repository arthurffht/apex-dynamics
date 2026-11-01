[CmdletBinding()]
param([switch]$AutoCheckpoint)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
Set-Location $root
$last=Get-ApexWorktreeFingerprint
$healthPath=Join-Path $root '.local/dev-health.json'
while ($true) {
    Start-Sleep -Milliseconds 1500
    $current=Get-ApexWorktreeFingerprint
    if ($current -eq $last) { continue }
    Start-Sleep -Milliseconds 1500
    $stable=Get-ApexWorktreeFingerprint
    if ($stable -ne $current) { continue }
    try {
        if ($AutoCheckpoint) { & ./scripts/sync.ps1 }
        else { & ./scripts/check.ps1 }
        $health=@{success=$true;verifiedAtUtc=[DateTime]::UtcNow.ToString('o');fingerprint=$stable;githubCheckpoints=[bool]$AutoCheckpoint}
    } catch {
        $health=@{success=$false;verifiedAtUtc=[DateTime]::UtcNow.ToString('o');fingerprint=$stable;error=$_.Exception.Message;githubCheckpoints=[bool]$AutoCheckpoint}
    }
    $health | ConvertTo-Json | Set-Content -LiteralPath $healthPath -Encoding utf8
    $last=$stable
}
