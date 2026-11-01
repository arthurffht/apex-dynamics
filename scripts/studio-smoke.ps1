[CmdletBinding()]
param([string]$StudioExecutable, [int]$TimeoutSeconds = 120)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $StudioExecutable) {
    $candidate = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Roblox\Versions') -Filter RobloxStudioBeta.exe -Recurse |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $candidate) { throw 'Roblox Studio is not installed; supply -StudioExecutable.' }
    $StudioExecutable = $candidate.FullName
}
$place = Join-Path $projectRoot 'build\ApexDynamicsSandbox.rbxlx'
if (-not (Test-Path -LiteralPath $place)) { throw 'Build the sandbox with scripts/check.ps1 first.' }
$runner = Join-Path $projectRoot 'tests\studio\smoke.luau'
$runDirectory = Join-Path $projectRoot ('build\studio\' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
[IO.Directory]::CreateDirectory($runDirectory) | Out-Null
$log = Join-Path $runDirectory 'output.log'
$process = Start-Process -FilePath $StudioExecutable -ArgumentList @(
    '--task','RunScript','--localPlaceFile',('"'+$place+'"'),
    '--runScriptFile',('"'+$runner+'"'),'--outputFile',('"'+$log+'"'),'--quitAfterExecution'
) -WindowStyle Hidden -PassThru
$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
while (-not $process.WaitForExit(1000)) {
    if ([DateTime]::UtcNow -gt $deadline) {
        Stop-Process -Id $process.Id
        throw "Isolated Studio test timed out. Log: $log"
    }
}
if (-not (Test-Path -LiteralPath $log)) { throw "Studio produced no test log: $log" }
$lines = Get-Content -LiteralPath $log
$reportLine = $lines | Where-Object { $_.StartsWith('APEX_STUDIO_REPORT=') } | Select-Object -Last 1
if (-not $reportLine) {
    throw "Studio test did not produce a successful completion marker. Inspect: $log"
}
$reportText = $reportLine.Substring('APEX_STUDIO_REPORT='.Length)
$report = $reportText | ConvertFrom-Json
if (-not $report.success) { throw "Studio assertion failed: $($report.result)" }
if ($lines -notcontains 'APEX_STUDIO_SMOKE_PASS') { throw "Studio completion marker missing: $log" }
$reportText | Set-Content -LiteralPath (Join-Path $runDirectory 'report.json') -Encoding utf8
Write-Output $reportText
Write-Output "Studio static support smoke passed. Raw log: $log"
