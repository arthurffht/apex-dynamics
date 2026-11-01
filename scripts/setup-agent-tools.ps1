[CmdletBinding()]
param([string]$PythonExecutable)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pins = Get-Content -LiteralPath (Join-Path $projectRoot 'config/agent-tools.json') -Raw | ConvertFrom-Json
$uvDirectory = Join-Path $env:LOCALAPPDATA 'ApexDynamics\tools\uv'
[IO.Directory]::CreateDirectory($uvDirectory) | Out-Null
$uv = Join-Path $uvDirectory 'uv.exe'
$uvVersion=if(Test-Path -LiteralPath $uv){& $uv --version}else{''}
if ($uvVersion -notmatch ('^uv '+[regex]::Escape($pins.uv.version)+'(?:\s|$)')) {
    $zip = Join-Path $uvDirectory 'uv.zip'
    Invoke-WebRequest $pins.uv.url -OutFile $zip
    if ((Get-FileHash -LiteralPath $zip).Hash.ToLowerInvariant() -ne $pins.uv.sha256) { throw 'uv checksum mismatch' }
    Expand-Archive -LiteralPath $zip -DestinationPath $uvDirectory -Force
}
if (-not $PythonExecutable) {
    $managed=Join-Path $env:APPDATA 'uv/python'
    $pythonPattern=[regex]::Escape('cpython-'+$pins.serena.python+'-')
    $candidate=Get-ChildItem -LiteralPath $managed -Filter python.exe -Recurse -ErrorAction SilentlyContinue | Where-Object FullName -Match $pythonPattern | Select-Object -First 1
    if ($candidate) { $PythonExecutable=$candidate.FullName }
}
if ($PythonExecutable) { & $uv tool install --no-managed-python --python $PythonExecutable "serena-agent==$($pins.serena.version)" }
else { & $uv tool install --python $pins.serena.python "serena-agent==$($pins.serena.version)" }
if ($LASTEXITCODE -ne 0) { throw 'Serena installation failed' }
$toolBin = (& $uv tool dir --bin).Trim()
$env:Path = "$uvDirectory;$toolBin;$(Join-Path $env:USERPROFILE '.rokit\bin');$env:Path"
$existing = [Environment]::GetEnvironmentVariable('Path','User')
$segments = @($existing -split ';' | Where-Object { $_ })
foreach ($directory in @($uvDirectory,$toolBin)) {
    if ($segments -notcontains $directory) { $segments += $directory }
}
[Environment]::SetEnvironmentVariable('Path',($segments -join ';'),'User')
& (Join-Path $toolBin 'serena.exe') --help
if ($LASTEXITCODE -ne 0) { throw 'Serena verification failed' }
Write-Output 'Agent tools installed. Project MCP configuration is generated separately.'
