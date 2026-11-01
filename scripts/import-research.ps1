[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$KnowledgeBaseZip,
    [Parameter(Mandatory=$true)][string]$ConsolidatedGuide,
    [Parameter(Mandatory=$true)][string]$MasterManual
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$researchRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '.local\research'))
[IO.Directory]::CreateDirectory($researchRoot) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $KnowledgeBaseZip).Path)
try {
    foreach ($entry in $archive.Entries) {
        $target = [IO.Path]::GetFullPath((Join-Path $researchRoot $entry.FullName))
        if (-not $target.StartsWith($researchRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Archive entry escapes research directory'
        }
    }
} finally { $archive.Dispose() }
Expand-Archive -LiteralPath $KnowledgeBaseZip -DestinationPath $researchRoot -Force
Copy-Item -LiteralPath $KnowledgeBaseZip,$ConsolidatedGuide,$MasterManual -Destination $researchRoot -Force
& node (Join-Path $PSScriptRoot 'index-research.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Research indexing failed' }
