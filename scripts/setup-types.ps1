$ErrorActionPreference = 'Stop'
$definitionPath = Join-Path (Split-Path -Parent $PSScriptRoot) '.local\definitions\roblox.d.luau'
$expectedHash = '2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080'
if (Test-Path -LiteralPath $definitionPath) {
    if ((Get-FileHash -LiteralPath $definitionPath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expectedHash) { return }
}
[IO.Directory]::CreateDirectory((Split-Path -Parent $definitionPath)) | Out-Null
Invoke-WebRequest 'https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau' -OutFile $definitionPath
if ((Get-FileHash -LiteralPath $definitionPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) {
    throw 'Roblox type definition checksum mismatch'
}
