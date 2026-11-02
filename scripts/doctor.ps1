$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
$checks=@()
foreach ($tool in @('git','gh','rokit','rojo','stylua','selene','lune','luau-lsp','wally','serena')) {
    $command=Get-Command $tool -ErrorAction SilentlyContinue
    $checks += @{name=$tool;available=($null -ne $command);path=if($command){$command.Source}else{$null}}
}
$studio=$null
try { $studio=Get-ApexStudio } catch {}
$status=& git -C $root status --porcelain
$branch=& git -C $root branch --show-current
$mcpLauncher=Join-Path $env:LOCALAPPDATA 'Roblox/mcp.bat'
$snapshot=Get-ApexSourceSnapshot
$result=[ordered]@{schemaVersion=1;tools=$checks;studioInstalled=($null -ne $studio);studioPath=$studio;mcpLauncherInstalled=(Test-Path -LiteralPath $mcpLauncher);mcpConnected='Check list_roblox_studios through the current connector; executable presence is not a connection';branch=$branch;workingTreeClean=([string]::IsNullOrWhiteSpace(($status -join '')));sourceFingerprint=$snapshot.fingerprint;engineProfile=(Get-Content (Join-Path $root 'config/engine.json') -Raw | ConvertFrom-Json);cloud='Not configured; local place is canonical';generatedPlaceExists=(Test-Path (Join-Path $root 'build/ApexDynamicsSandbox.rbxlx'))}
$directory=Join-Path $root '.local/diagnostics'
[IO.Directory]::CreateDirectory($directory) | Out-Null
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $directory 'doctor.json') -Encoding utf8
$result | ConvertTo-Json -Depth 8
