$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
$uv=(Get-Command uv -ErrorAction Stop).Source
$tools=(& $uv tool dir).Trim()
$python=Join-Path $tools 'serena-agent/Scripts/python.exe'
& $python (Join-Path $PSScriptRoot 'configure-serena.py')
if ($LASTEXITCODE -ne 0) { throw 'Serena project settings could not be configured' }
$configuration=Join-Path $root '.codex/config.toml'
[IO.Directory]::CreateDirectory((Split-Path -Parent $configuration)) | Out-Null
if (Test-Path -LiteralPath $configuration) {
    $existing=[IO.File]::ReadAllText($configuration)
    if (-not $existing.StartsWith('# Generated Apex Dynamics MCP configuration')) { throw 'A project Codex configuration already exists; merge it explicitly instead of overwriting it' }
}
$shellPath=(Get-Process -Id $PID).Path.Replace('\','/')
$launcher=(Join-Path $root 'scripts/start-serena.ps1').Replace('\','/')
$content=@"
# Generated Apex Dynamics MCP configuration. Machine paths stay out of Git.
[mcp_servers.apex_serena]
command = '$shellPath'
args = ['-NoProfile', '-File', '$launcher']
startup_timeout_sec = 90
tool_timeout_sec = 90
"@
[IO.File]::WriteAllText($configuration,$content+"`n")
Write-Output 'Project Serena MCP configuration written. The existing user-level Roblox_Studio connector is reused. New MCP definitions are discovered when Codex starts a new trusted project session.'
