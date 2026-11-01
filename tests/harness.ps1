$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot '../scripts/lib/Project.psm1') -Force
$root=Get-ApexRoot
$assertions=0
function Assert-Harness([bool]$Condition,[string]$Message){
    $script:assertions++
    if(-not $Condition){throw $Message}
}
$files=@(Get-ChildItem (Join-Path $root 'scripts'),(Join-Path $root 'tests') -Filter '*.ps1' -File -Recurse)
$files+=Get-Item (Join-Path $root 'apex.ps1')
foreach($file in $files){
    $tokens=$null;$errors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    Assert-Harness ($errors.Count -eq 0) "PowerShell parse error: $($file.Name): $errors"
}
$baseline=Get-ApexWorktreeFingerprint
$id=[Guid]::NewGuid().ToString('N')
$ignored=Join-Path $root ('.local/harness-'+$id+'.txt')
$candidate=Join-Path $root ('tests/harness-'+$id+'.txt')
$profile=Join-Path $root ('.local/profile-'+$id+'.json')
try{
    [IO.File]::WriteAllText($ignored,'local credential/cache fixture')
    Assert-Harness ((Get-ApexWorktreeFingerprint) -eq $baseline) 'Ignored data changed the checkpoint fingerprint'
    [IO.File]::WriteAllText($candidate,'alpha')
    $first=Get-ApexWorktreeFingerprint
    Assert-Harness ($first -ne $baseline) 'Untracked project changes were missed'
    [IO.File]::WriteAllText($candidate,'beta!')
    Assert-Harness ((Get-ApexWorktreeFingerprint) -ne $first) 'Same-size edits were missed'
    $before=(Get-FileHash (Join-Path $root '.local/generated/active.project.json')).Hash
    [IO.File]::WriteAllText($profile,'{"authorityMode":"Server","fixedSimulation":"Enabled","physicsSteppingMethod":"Fixed"}')
    $rejected=$false
    try{& (Join-Path $root 'scripts/generate-project.ps1') -EngineProfile $profile}catch{$rejected=$true}
    Assert-Harness $rejected 'Unsupported rollback profile was silently accepted'
    Assert-Harness ((Get-FileHash (Join-Path $root '.local/generated/active.project.json')).Hash -eq $before) 'Rejected profile mutated the active project'
}finally{
    foreach($owned in @($ignored,$candidate,$profile)){
        $absolute=[IO.Path]::GetFullPath($owned)
        if(-not $absolute.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe harness fixture path'}
        if(Test-Path -LiteralPath $absolute){Remove-Item -LiteralPath $absolute}
    }
}
Assert-Harness ((Get-ApexWorktreeFingerprint) -eq $baseline) 'Harness fixtures did not restore the worktree'
Write-Output "PASS development harness: $assertions assertions, parser checks, ignored-input isolation, edit detection, and unsupported-profile rejection"
