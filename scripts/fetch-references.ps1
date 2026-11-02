$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
$root=Get-ApexRoot
$referenceRoot=[IO.Path]::GetFullPath((Join-Path $root '.local/references'))
[IO.Directory]::CreateDirectory($referenceRoot) | Out-Null
$pins=Get-Content (Join-Path $root 'config/agent-tools.json') -Raw | ConvertFrom-Json
foreach($reference in $pins.references){
    if($reference.name -notmatch '^[a-z0-9-]+$' -or $reference.repository -notmatch '^https://github\.com/[^/]+/[^/]+\.git$' -or $reference.commit -notmatch '^[a-f0-9]{40}$'){throw 'Invalid pinned reference'}
    $destination=[IO.Path]::GetFullPath((Join-Path $referenceRoot $reference.name))
    if(-not $destination.StartsWith($referenceRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Reference path escaped its workspace'}
    if(Test-Path -LiteralPath $destination){
        $origin=(& git -C $destination remote get-url origin).Trim()
        if($LASTEXITCODE -ne 0 -or $origin -ne $reference.repository){throw 'Existing reference has a different origin; preserving it'}
        if(((& git -C $destination status --porcelain) -join '')){throw 'Existing reference has local changes; preserving it'}
    }else{Invoke-ApexTool git @('clone','--no-checkout','--filter=blob:none',$reference.repository,$destination)}
    Invoke-ApexTool git @('-C',$destination,'fetch','--depth','1','origin',$reference.commit)
    Invoke-ApexTool git @('-C',$destination,'checkout','--detach',$reference.commit)
    Write-Output "Pinned reference ready: $($reference.name) $($reference.commit)"
}
