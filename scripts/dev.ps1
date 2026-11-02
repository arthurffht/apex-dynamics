[CmdletBinding()]
param([switch]$AutoCheckpoint,[switch]$StudioChecks,[switch]$Stop)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
$sessionPath=Join-Path $root '.local/dev-session.json'
if ($Stop) {
    if (-not (Test-Path -LiteralPath $sessionPath)) { Write-Output 'No project development session recorded'; return }
    $session=Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
    foreach ($owned in $session.processes) {
        $process=Get-CimInstance Win32_Process -Filter "ProcessId = $($owned.id)" -ErrorAction SilentlyContinue
        if ($process -and $process.CommandLine.Contains($owned.expectedArgument)) {
            $target=Get-Process -Id $owned.id -ErrorAction Stop
            $target.Kill($true)
        } elseif ($process) { throw 'Recorded PID belongs to another command; refusing to stop it' }
    }
    $session.status='stopped'
    $session | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
    Write-Output 'Project-owned development processes stopped'
    return
}
$logs=Join-Path $root '.local/logs'
[IO.Directory]::CreateDirectory($logs) | Out-Null
$watchScript=Join-Path $root 'scripts/watch.ps1'
function Start-ProjectWatcher {
    $watchArgs=@('-NoProfile','-File',('"'+$watchScript+'"'))
    if ($AutoCheckpoint) { $watchArgs+='-AutoCheckpoint' }
    if ($StudioChecks) { $watchArgs+='-StudioChecks' }
    Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $watchArgs -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs 'watch.out.log') -RedirectStandardError (Join-Path $logs 'watch.err.log') -PassThru
}
if (Test-Path -LiteralPath $sessionPath) {
    $session=Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
    if ($session.status -eq 'running') {
        $alive=@($session.processes | Where-Object { Get-Process -Id $_.id -ErrorAction SilentlyContinue })
        if ($alive.Count -gt 0) {
            foreach ($owned in $session.processes) {
                $process=Get-CimInstance Win32_Process -Filter "ProcessId = $($owned.id)" -ErrorAction SilentlyContinue
                if (-not $process -or -not $process.CommandLine.Contains($owned.expectedArgument)) { throw 'Development session is partial or belongs to another command; inspect it before using stop/dev' }
            }
            $watcher=@($session.processes | Where-Object kind -EQ 'watch')
            if ($watcher.Count -ne 1) { throw 'Expected exactly one project watcher' }
            $old=Get-Process -Id $watcher[0].id -ErrorAction Stop
            $old.Kill($true)
            $old.WaitForExit()
            $replacement=Start-ProjectWatcher
            $session.processes=@($session.processes | Where-Object kind -NE 'watch')+@(@{id=$replacement.Id;expectedArgument=$watchScript;kind='watch'})
            $session.autoCheckpoint=[bool]$AutoCheckpoint
            $session | Add-Member studioChecks ([bool]$StudioChecks) -Force
            $session | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
            Write-Output 'Verification options updated; existing Rojo and sourcemap processes preserved.'
            return
        }
    }
}
try { $null=Invoke-RestMethod http://127.0.0.1:34872/api/rojo -TimeoutSec 1; throw 'Port 34872 already serves a Rojo session; inspect it before starting another' }
catch { if ($_.Exception.Message -like 'Port 34872*') { throw } }
& (Join-Path $PSScriptRoot 'generate-project.ps1')
$project=Join-Path $root '.local/generated/active.project.json'
$rojo=Get-ApexRojoExecutable
$rojoProcess=Start-Process -FilePath $rojo -ArgumentList @('serve',('"'+$project+'"'),'--address','127.0.0.1') -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs 'rojo.out.log') -RedirectStandardError (Join-Path $logs 'rojo.err.log') -PassThru
$sourcemap=Join-Path $root 'sourcemap.json'
$mapProcess=Start-Process -FilePath $rojo -ArgumentList @('sourcemap',('"'+$project+'"'),'--absolute','--watch','--output',('"'+$sourcemap+'"')) -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs 'sourcemap.out.log') -RedirectStandardError (Join-Path $logs 'sourcemap.err.log') -PassThru
$watchProcess=Start-ProjectWatcher
$session=@{status='running';root=$root;startedAtUtc=[DateTime]::UtcNow.ToString('o');autoCheckpoint=[bool]$AutoCheckpoint;studioChecks=[bool]$StudioChecks;endpoint='http://127.0.0.1:34872';processes=@(@{id=$rojoProcess.Id;expectedArgument=$project;kind='rojo'},@{id=$mapProcess.Id;expectedArgument=$project;kind='sourcemap'},@{id=$watchProcess.Id;expectedArgument=$watchScript;kind='watch'})}
$session | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
$ready=$false
for ($attempt=0;$attempt -lt 10;$attempt++) {
    try { $response=Invoke-RestMethod http://127.0.0.1:34872/api/rojo -TimeoutSec 1; $ready=$true; break } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ready) { & (Join-Path $PSScriptRoot 'dev.ps1') -Stop; throw 'Rojo failed to start; inspect .local/logs' }
Write-Output 'Rojo is serving the local-only project at 127.0.0.1:34872. Connect its Studio plugin once; live source changes then synchronize through Rojo.'
Write-Output "Background validation active. Verified GitHub checkpoints: $([bool]$AutoCheckpoint). Main is never automatically merged or force-pushed."
