[CmdletBinding()]
param([switch]$Execute,[string]$Evidence)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
Initialize-ApexEnvironment
$root=Get-ApexRoot
$targetFile=Join-Path $root '.local/cloud.json'
if (-not (Test-Path -LiteralPath $targetFile)) {
    if($Execute){throw 'Configure the owned staging place in .local/cloud.json first'}
    Write-Output 'Cloud is not configured. Local development remains canonical. Copy config/cloud.example.json to .local/cloud.json and select an owned staging place to prepare a release.'
    return
}
$target=Get-Content -LiteralPath $targetFile -Raw | ConvertFrom-Json
if($target.environment -ne 'staging'){throw 'This command supports staging only'}
$universeId=[UInt64]$target.universeId
$placeId=[UInt64]$target.placeId
if($universeId -eq 0 -or $placeId -eq 0){throw 'Universe and place IDs must be positive'}
$snapshot=Get-ApexSourceSnapshot
$plan=@{environment='staging';universeId=$universeId;placeId=$placeId;sourceFingerprint=$snapshot.fingerprint;artifact='build/ApexDynamicsSandbox.rbxlx';execute=[bool]$Execute}
if(-not $Execute){$plan | ConvertTo-Json; return}
if(-not $env:ROBLOX_API_KEY){throw 'ROBLOX_API_KEY is required in the process environment; do not store it in the repository'}
Push-Location $root
try{
    if((& git branch --show-current).Trim() -ne 'main' -or ((& git status --porcelain) -join '')){throw 'Publish a clean main commit only'}
    $head=(& git rev-parse HEAD).Trim()
    $repository=(& gh repo view --json nameWithOwner --jq .nameWithOwner).Trim()
    if($LASTEXITCODE -ne 0){throw 'Cannot resolve the GitHub repository'}
    $runs=& gh run list --workflow CI --branch main --commit $head --json conclusion,status --limit 1 | ConvertFrom-Json
    if($LASTEXITCODE -ne 0 -or @($runs).Count -eq 0 -or $runs[0].conclusion -ne 'success'){throw 'Current main commit does not have a passing CI run'}
    if(-not $Evidence){throw 'Supply -Evidence with a passing current Studio regression report'}
    $report=Get-Content -LiteralPath $Evidence -Raw | ConvertFrom-Json
    if(-not $report.requiredPassed -or $report.suite -notin @('Regression','Research') -or $report.sourceFingerprint -ne $snapshot.fingerprint){throw 'Studio evidence must pass and match this source fingerprint'}
    $receipt=Get-Content .local/build-receipt.json -Raw | ConvertFrom-Json
    $artifact=$receipt.artifacts | Where-Object path -EQ 'build/ApexDynamicsSandbox.rbxlx'
    $place=Join-Path $root $artifact.path
    if($receipt.fingerprint -ne $snapshot.fingerprint -or (Get-FileHash -LiteralPath $place).Hash.ToLowerInvariant() -ne $artifact.sha256){throw 'Build receipt or artifact is stale'}
    $endpoint="https://apis.roblox.com/universes/v1/$universeId/places/$placeId/versions?versionType=Published"
    $response=Invoke-RestMethod -Method Post -Uri $endpoint -Headers @{'x-api-key'=$env:ROBLOX_API_KEY} -ContentType 'application/xml' -InFile $place
    @{commit=$head;repository=$repository;sourceFingerprint=$snapshot.fingerprint;universeId=$universeId;placeId=$placeId;versionNumber=$response.versionNumber;artifactSha256=$artifact.sha256} | ConvertTo-Json | Set-Content .local/cloud-release.json
    Write-Output "Published staging version $($response.versionNumber). Receipt stored locally."
}finally{Pop-Location}
