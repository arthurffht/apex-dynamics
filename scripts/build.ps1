[CmdletBinding()]
param([switch]$Generated)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
$verification=if(-not $Generated){Enter-ApexVerification}else{$null}
Push-Location $root
try {
    if (-not $Generated) { & ./scripts/generate-project.ps1 }
    $before=Get-ApexSourceSnapshot
    [IO.Directory]::CreateDirectory((Join-Path $root 'build')) | Out-Null
    Invoke-ApexTool rojo @('build','.local/generated/active.project.json','-o','build/ApexDynamicsSandbox.rbxlx')
    Invoke-ApexTool rojo @('build','package.project.json','-o','build/ApexDynamics.rbxm')
    if ((Get-ApexSourceSnapshot).fingerprint -ne $before.fingerprint) { throw 'Source changed during build; artifacts are not verified' }
    $artifacts=@('build/ApexDynamicsSandbox.rbxlx','build/ApexDynamics.rbxm') | ForEach-Object { @{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash.ToLowerInvariant()} }
    @{fingerprint=$before.fingerprint;artifacts=@($artifacts)} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath .local/build-receipt.json -Encoding utf8
} finally { Pop-Location; if($verification){$verification.Dispose()} }
