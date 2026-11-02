[CmdletBinding()]
param([switch]$AutoCheckpoint,[switch]$StudioChecks)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
Set-Location $root
$last=''
$healthPath=Join-Path $root '.local/dev-health.json'
$nextTransportCheck=[DateTime]::MinValue
$transport=$null
while ($true) {
    Start-Sleep -Milliseconds 1500
    if([DateTime]::UtcNow -ge $nextTransportCheck){
        $transport=Get-ApexTransportState
        $nextTransportCheck=[DateTime]::UtcNow.AddSeconds(15)
        if(-not $transport.healthy){
            $health=if(Test-Path -LiteralPath $healthPath){Get-Content -LiteralPath $healthPath -Raw | ConvertFrom-Json -AsHashtable}else{@{}}
            $health.success=$false
            $health.transportHealthy=$false
            $health.transportErrors=@($transport.errors)
            $health.transportCheckedAtUtc=[DateTime]::UtcNow.ToString('o')
            $health | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $healthPath -Encoding utf8
        }
    }
    if(-not $transport.healthy){continue}
    $current=Get-ApexWorktreeFingerprint
    if ($current -eq $last) { continue }
    Start-Sleep -Milliseconds 1500
    $stable=Get-ApexWorktreeFingerprint
    if ($stable -ne $current) { continue }
    try {
        if ($AutoCheckpoint) { & ./scripts/sync.ps1 -StudioChecks:$StudioChecks }
        else { & ./scripts/check.ps1; if ($StudioChecks) { & ./scripts/studio-test.ps1 -Suite Foundation } }
        if ((Get-ApexWorktreeFingerprint) -ne $stable) { throw 'Files changed during background verification; result cancelled' }
        $transport=Get-ApexTransportState
        if(-not $transport.healthy){throw ($transport.errors -join '; ')}
        $health=@{success=$true;verifiedAtUtc=[DateTime]::UtcNow.ToString('o');fingerprint=$stable;githubCheckpoints=[bool]$AutoCheckpoint;studioChecks=[bool]$StudioChecks}
    } catch {
        $health=@{success=$false;verifiedAtUtc=[DateTime]::UtcNow.ToString('o');fingerprint=$stable;error=$_.Exception.Message;githubCheckpoints=[bool]$AutoCheckpoint;studioChecks=[bool]$StudioChecks}
    }
    $health.transportHealthy=$transport.healthy
    $health | ConvertTo-Json | Set-Content -LiteralPath $healthPath -Encoding utf8
    $last=$stable
}
