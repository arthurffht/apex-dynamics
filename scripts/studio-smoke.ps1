[CmdletBinding()]
param([string]$StudioExecutable,[int]$TimeoutSeconds=180)
# Compatibility entry point; the suite and runner are maintained in one place.
& (Join-Path $PSScriptRoot 'studio-test.ps1') -Suite Smoke -StudioExecutable $StudioExecutable -TimeoutSeconds $TimeoutSeconds
