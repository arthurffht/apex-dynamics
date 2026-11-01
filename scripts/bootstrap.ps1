[CmdletBinding()]
param([switch]$InstallStudioPlugin)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $rokitBin = Join-Path $env:USERPROFILE '.rokit\bin'
    $rokitExe = Join-Path $rokitBin 'rokit.exe'
    $expectedVersion = 'rokit 1.2.0'
    $installedVersion = if (Test-Path -LiteralPath $rokitExe) { & $rokitExe --version } else { '' }
    if ($installedVersion -ne $expectedVersion) {
        $downloadDirectory = Join-Path $projectRoot '.local\bootstrap'
        [IO.Directory]::CreateDirectory($downloadDirectory) | Out-Null
        $zip = Join-Path $downloadDirectory 'rokit-1.2.0-windows-x86_64.zip'
        $url = 'https://github.com/rojo-rbx/rokit/releases/download/v1.2.0/rokit-1.2.0-windows-x86_64.zip'
        Invoke-WebRequest $url -OutFile $zip
        $expected = 'f9ba1704014ff67d51e8005f605955c7c26d2429a5312a9419dc477fc310e96d'
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
            throw 'Rokit archive checksum mismatch'
        }
        Expand-Archive -LiteralPath $zip -DestinationPath $downloadDirectory -Force
        & (Join-Path $downloadDirectory 'rokit.exe') self-install
        if ($LASTEXITCODE -ne 0) { throw 'Rokit installation failed' }
    }
    $env:Path = "$rokitBin;$env:Path"
    # Trust only the publishers explicitly selected in the reviewed project manifest.
    & $rokitExe trust rojo-rbx/rojo JohnnyMorganz/StyLua Kampfkarren/selene lune-org/lune JohnnyMorganz/luau-lsp UpliftGames/wally
    if ($LASTEXITCODE -ne 0) { throw 'Rokit trust configuration failed' }
    & $rokitExe install
    if ($LASTEXITCODE -ne 0) { throw 'Toolchain installation failed' }
    if ($InstallStudioPlugin) {
        rojo plugin install
        if ($LASTEXITCODE -ne 0) { throw 'Rojo Studio plugin installation failed' }
    }
    & (Join-Path $PSScriptRoot 'setup-types.ps1')
    Write-Output 'Pinned toolchain installed. Run scripts/check.ps1 in this terminal.'
} finally { Pop-Location }
