$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
$verification = Enter-ApexVerification
$env:Path = "$(Join-Path $env:USERPROFILE '.rokit\bin');$env:Path"
Push-Location $projectRoot
try {
    & (Join-Path $PSScriptRoot 'setup-types.ps1')
    & (Join-Path $PSScriptRoot 'generate-project.ps1')
    [IO.Directory]::CreateDirectory((Join-Path $projectRoot 'build')) | Out-Null
    stylua --check src tests examples
    if ($LASTEXITCODE -ne 0) { throw 'Formatting check failed' }
    selene src tests examples
    if ($LASTEXITCODE -ne 0) { throw 'Lint failed' }
    luau-lsp analyze --platform=standard src/core src/presets src/config src/foundation tests/run.luau tests/foundation.luau
    if ($LASTEXITCODE -ne 0) { throw 'Pure Luau type check failed' }
    rojo sourcemap .local/generated/active.project.json --absolute --output sourcemap.json
    if ($LASTEXITCODE -ne 0) { throw 'Sourcemap generation failed' }
    luau-lsp analyze --platform=roblox --definitions=.local/definitions/roblox.d.luau --sourcemap=sourcemap.json src examples tests/studio
    if ($LASTEXITCODE -ne 0) { throw 'Roblox Luau type check failed' }
    lune run tests/run
    if ($LASTEXITCODE -ne 0) { throw 'Physics tests failed' }
    lune run tests/foundation
    if ($LASTEXITCODE -ne 0) { throw 'Foundation tests failed' }
    & (Join-Path $PSScriptRoot 'build.ps1') -Generated
    lune run tests/build
    if ($LASTEXITCODE -ne 0) { throw 'Build inspection failed' }
    & (Join-Path $projectRoot 'tests/harness.ps1')
    Write-Output 'All offline checks passed. Studio validation is a separate gate.'
} finally { Pop-Location; $verification.Dispose() }
