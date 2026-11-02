$ErrorActionPreference = 'Stop'
function Get-ApexRoot { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
function Enter-ApexVerification {
    param([ValidateRange(0,600)][int]$TimeoutSeconds=300)
    $directory=Join-Path (Get-ApexRoot) '.local'
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $path=Join-Path $directory 'verification.lock'
    $deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ($true) {
        try { return [IO.File]::Open($path,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
        catch [IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) { throw [TimeoutException]::new('Another project verification owns the artifact lock') }
            Start-Sleep -Milliseconds 250
        }
    }
}
function Initialize-ApexEnvironment {
    $paths = @((Join-Path $env:USERPROFILE '.rokit\bin'),(Join-Path $env:LOCALAPPDATA 'ApexDynamics\tools\gh\bin'),(Join-Path $env:LOCALAPPDATA 'ApexDynamics\tools\uv'),(Join-Path $env:USERPROFILE '.local\bin'))
    $env:Path = ($paths -join ';') + ';' + $env:Path
}
function Invoke-ApexTool {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}
function Get-ApexStudio {
    $studio = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Roblox\Versions') -Filter RobloxStudioBeta.exe -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $studio) { throw 'Roblox Studio is not installed' }
    $studio.FullName
}
function Get-ApexSourceSnapshot {
    $root = Get-ApexRoot
    $files = @()
    foreach ($directory in @('src','examples','config')) {
        $files += Get-ChildItem -LiteralPath (Join-Path $root $directory) -File -Recurse | Where-Object { $_.Extension -in '.luau','.json' }
    }
    $files += Get-Item -LiteralPath (Join-Path $root 'default.project.json'),(Join-Path $root 'package.project.json'),(Join-Path $root 'laboratory.project.json')
    $records = @($files | Sort-Object FullName | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/')
        $content = [IO.File]::ReadAllText($_.FullName).Replace("`r`n","`n")
        $bytes = [Text.Encoding]::UTF8.GetBytes($content)
        $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
        [ordered]@{path=$relative;sha256=$digest}
    })
    $joined = ($records | ForEach-Object { "$($_.path)=$($_.sha256)" }) -join "`n"
    $fingerprint = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($joined))).ToLowerInvariant()
    [PSCustomObject]@{fingerprint=$fingerprint;files=$records}
}
function Get-ApexWorktreeFingerprint {
    $root=Get-ApexRoot
    $paths=(& git -C $root ls-files --cached --others --exclude-standard) | Sort-Object -Unique
    $records=foreach ($path in $paths) {
        $full=Join-Path $root $path
        if (Test-Path -LiteralPath $full -PathType Leaf) { "$path=$((Get-FileHash -LiteralPath $full).Hash)" }
        else { "$path=DELETED" }
    }
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($records -join "`n")))).ToLowerInvariant()
}
Export-ModuleMember -Function Get-ApexRoot,Initialize-ApexEnvironment,Invoke-ApexTool,Get-ApexStudio,Get-ApexSourceSnapshot,Get-ApexWorktreeFingerprint,Enter-ApexVerification
