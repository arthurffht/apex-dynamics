$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
$env:Path = "$(Join-Path $env:USERPROFILE '.rokit\bin');$env:Path"
Push-Location $projectRoot
try {
    & (Join-Path $PSScriptRoot 'setup-types.ps1')
    [IO.Directory]::CreateDirectory((Join-Path $projectRoot 'build')) | Out-Null
    stylua --check src tests examples
    if ($LASTEXITCODE -ne 0) { throw 'Formatting check failed' }
    selene src tests examples
    if ($LASTEXITCODE -ne 0) { throw 'Lint failed' }
    luau-lsp analyze --platform=standard src/core src/presets tests/run.luau
    if ($LASTEXITCODE -ne 0) { throw 'Pure Luau type check failed' }
    rojo sourcemap default.project.json --output sourcemap.json
    if ($LASTEXITCODE -ne 0) { throw 'Sourcemap generation failed' }
    luau-lsp analyze --platform=roblox --definitions=.local/definitions/roblox.d.luau --sourcemap=sourcemap.json src examples
    if ($LASTEXITCODE -ne 0) { throw 'Roblox Luau type check failed' }
    lune run tests/run
    if ($LASTEXITCODE -ne 0) { throw 'Physics tests failed' }
    rojo build default.project.json -o build/ApexDynamicsSandbox.rbxlx
    if ($LASTEXITCODE -ne 0) { throw 'Sandbox build failed' }
    rojo build package.project.json -o build/ApexDynamics.rbxm
    if ($LASTEXITCODE -ne 0) { throw 'Library build failed' }
    lune run tests/build
    if ($LASTEXITCODE -ne 0) { throw 'Build inspection failed' }
    Write-Output 'All offline checks passed. Studio validation is a separate gate.'
} finally { Pop-Location }
