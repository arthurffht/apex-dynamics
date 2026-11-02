[CmdletBinding()]
param([ValidateSet('Smoke','Regression','Research','Multiplayer','Audit','Foundation')][string]$Suite='Regression',[string]$StudioExecutable,[int]$TimeoutSeconds=180)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
$verification=Enter-ApexVerification
try {
$root=Get-ApexRoot
if (-not $StudioExecutable) { $StudioExecutable=Get-ApexStudio }
$place=Join-Path $root 'build/ApexDynamicsSandbox.rbxlx'
if (-not (Test-Path -LiteralPath $place)) { throw 'Build the sandbox first' }
$snapshot=Get-ApexSourceSnapshot
$built=Get-Content -LiteralPath (Join-Path $root '.local/generated/source-snapshot.json') -Raw | ConvertFrom-Json
if ($snapshot.fingerprint -ne $built.fingerprint) { throw 'Source changed after build; run apex.ps1 build or check first' }
$receipt=Get-Content -LiteralPath (Join-Path $root '.local/build-receipt.json') -Raw | ConvertFrom-Json
if ($receipt.fingerprint -ne $snapshot.fingerprint) { throw 'Build receipt does not match current source' }
foreach($artifact in $receipt.artifacts){
    if((Get-FileHash -LiteralPath (Join-Path $root $artifact.path)).Hash.ToLowerInvariant() -ne $artifact.sha256){throw 'Generated artifact drifted after build'}
}
$run=Join-Path $root ('build/studio/'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
[IO.Directory]::CreateDirectory($run) | Out-Null
$suiteFile=if($Suite -eq 'Multiplayer'){'tests/studio/multiplayer.server.luau'}elseif($Suite -eq 'Audit'){'tests/studio/audit.luau'}elseif($Suite -eq 'Foundation'){'tests/studio/foundation.server.luau'}else{'tests/studio/suite.server.luau'}
$source=[IO.File]::ReadAllText((Join-Path $root $suiteFile))
$harness=@{suitePath=$suiteFile;suiteSha256=(Get-FileHash -LiteralPath (Join-Path $root $suiteFile)).Hash.ToLowerInvariant();entrySha256=(Get-FileHash -LiteralPath (Join-Path $root 'tests/studio/entry.luau')).Hash.ToLowerInvariant();runnerSha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash.ToLowerInvariant();toolchainSha256=(Get-FileHash -LiteralPath (Join-Path $root 'rokit.toml')).Hash.ToLowerInvariant()}
$requestedEngine=Get-Content -LiteralPath (Join-Path $root 'config/engine.json') -Raw | ConvertFrom-Json
$delimiter='='
while ($source.Contains(']'+$delimiter+']')) { $delimiter+='=' }
$entry=[IO.File]::ReadAllText((Join-Path $root 'tests/studio/entry.luau'))
$entry=$entry.Replace('"" -- APEX_PROBE_SOURCE',('['+$delimiter+'['+$source+']'+$delimiter+']'))
$version=(Get-Item -LiteralPath $StudioExecutable).VersionInfo.FileVersion -replace ',\s*','.'
$entry=$entry.Replace('{ suite = "Regression", engineVersion = "unknown" } -- APEX_ARGS',('{ suite = "'+$Suite+'", engineVersion = "'+$version+'" }'))
if($Suite -eq 'Multiplayer'){
    $entry="workspace:SetAttribute('ApexReferenceEnabled',true)"+"`n"+$entry
    $entry=$entry.Replace('sandbox.Enabled = false -- APEX_SANDBOX_ENABLED','sandbox.Enabled = true')
    $entry=$entry.Replace('StudioTestService:ExecuteRunModeAsync(testArgs) -- APEX_MODE','StudioTestService:ExecuteMultiplayerTestAsync(2,testArgs)')
    $clientSource=[IO.File]::ReadAllText((Join-Path $root 'tests/studio/multiplayer.client.luau'))
    $harness.clientProbeSha256=(Get-FileHash -LiteralPath (Join-Path $root 'tests/studio/multiplayer.client.luau')).Hash.ToLowerInvariant()
    $clientSetup='local original = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("ApexInput"); if original then original.Enabled=false end'+"`n"+'local client=Instance.new("LocalScript"); client.Name="ApexClientProbe"; client.Source=[==['+$clientSource+']==]; client.Parent=game:GetService("StarterPlayer").StarterPlayerScripts'
    $entry=$entry.Replace('-- APEX_CLIENT_SETUP',$clientSetup)
}
if($Suite -eq 'Foundation'){$entry=$entry.Replace('laboratory.Enabled = false -- APEX_LAB_ENABLED','laboratory.Enabled = true')}
$keepalive=if($Suite -eq 'Smoke'){20}elseif($Suite -eq 'Research' -or $Suite -eq 'Multiplayer'){100}else{65}
$entry=$entry.Replace('task.wait(50) -- APEX_KEEPALIVE',"task.wait($keepalive)")
if($Suite -eq 'Audit'){
    $auditPath=& (Join-Path $PSScriptRoot 'audit-studio.ps1')
    $audit=[IO.File]::ReadAllText($auditPath)
    $harness.auditProbeSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($audit))).ToLowerInvariant()
    $auditDelimiter='===='
    while($audit.Contains(']'+$auditDelimiter+']')){$auditDelimiter+='='}
    $entry=$source.Replace('"" -- APEX_AUDIT_SOURCE',('['+$auditDelimiter+'['+$audit+']'+$auditDelimiter+']'))
}
$entryPath=Join-Path $run 'entry.luau'
[IO.File]::WriteAllText($entryPath,$entry)
$log=Join-Path $run 'output.log'
$process=Start-Process -FilePath $StudioExecutable -ArgumentList @('--task','RunScript','--localPlaceFile',('"'+$place+'"'),'--runScriptFile',('"'+$entryPath+'"'),'--outputFile',('"'+$log+'"'),'--quitAfterExecution') -WindowStyle Hidden -PassThru
$deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
while (-not $process.WaitForExit(1000)) {
    if ([DateTime]::UtcNow -gt $deadline) { $process.Kill($true); throw "Isolated Studio test timed out: $log" }
}
if (-not (Test-Path -LiteralPath $log)) { throw "Studio produced no log: $run" }
$lines=Get-Content -LiteralPath $log
$line=$lines | Where-Object { $_.StartsWith('APEX_TEST_REPORT=') } | Select-Object -Last 1
if (-not $line) { throw "No structured completion report; inspect $log" }
$report=$line.Substring('APEX_TEST_REPORT='.Length) | ConvertFrom-Json
if(-not $report.PSObject.Properties['sourceFingerprint']){$report | Add-Member sourceFingerprint $snapshot.fingerprint}
if(-not $report.PSObject.Properties['engineVersion']){$report | Add-Member engineVersion $version}
if(-not $report.PSObject.Properties['engineVersionSource']){$report | Add-Member engineVersionSource 'Studio executable file version'}
$report | Add-Member sourceSnapshot $snapshot
$report | Add-Member harness $harness
$report | Add-Member requestedEngineProfile $requestedEngine
$report | Add-Member testSuiteSha256 ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($source))).ToLowerInvariant())
$report | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $run 'report.json') -Encoding utf8
Write-Output "Studio $Suite report: $run"
$report.cases | Select-Object name,research,passed,error | Format-Table -AutoSize
if (-not $report.requiredPassed -or $lines -notcontains 'APEX_TEST_REQUIRED_PASS') { throw 'Required Studio regressions failed; raw evidence was preserved' }
if ($Suite -eq 'Research' -and -not $report.researchTargetsPassed) { throw 'Research targets failed; this is a measured limitation, not a passing fidelity claim' }
Write-Output 'Studio suite passed its declared gates'
} finally { $verification.Dispose() }
