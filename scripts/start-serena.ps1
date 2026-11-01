$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
Set-Location $root
& serena start-mcp-server --context codex --project $root --agent-interface tools --enable-web-dashboard false --open-web-dashboard false --enable-gui-log-window false
exit $LASTEXITCODE
