$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/Project.psm1') -Force
$root=Get-ApexRoot
$snapshot=Get-ApexSourceSnapshot
$entries=@()
foreach ($file in $snapshot.files) {
    if (-not $file.path.EndsWith('.luau')) { continue }
    $instancePath=$null
    if ($file.path -match '^src/(core|roblox|presets|config)/(.+)\.luau$') {
        $groups=@{core='Core';roblox='Roblox';presets='Presets';config='Config'}
        $instancePath='ReplicatedStorage/ApexDynamics/'+$groups[$Matches[1]]+'/'+$Matches[2]
    } elseif ($file.path -eq 'examples/sandbox.server.luau') { $instancePath='ServerScriptService/ApexSandbox' }
    elseif ($file.path -eq 'examples/input.client.luau') { $instancePath='StarterPlayer/StarterPlayerScripts/ApexInput' }
    if ($instancePath) {
        $source=[IO.File]::ReadAllText((Join-Path $root $file.path)).Replace("`r`n","`n")
        $delimiter='='
        while ($source.Contains(']'+$delimiter+']')) { $delimiter+='=' }
        $entries += '{path="'+$instancePath+'",source=['+$delimiter+'['+$source+']'+$delimiter+']}'
    }
}
$script=@'
local expected = {ENTRIES}
local drift = {}
local checked = 0
local expectedPaths = {}
for _, record in expected do
    expectedPaths[record.path] = true
    local item = game
    for name in string.gmatch(record.path, "[^/]+") do
        item = if item then item:FindFirstChild(name) else nil
    end
    if not item then
        table.insert(drift, {path=record.path,reason="missing"})
    elseif string.gsub(item.Source, "\r\n", "\n") ~= record.source then
        table.insert(drift, {path=record.path,reason="source differs"})
    end
    checked += 1
end
local package = game:GetService("ReplicatedStorage"):FindFirstChild("ApexDynamics")
if package then
    for _, item in package:GetDescendants() do
        if item:IsA("LuaSourceContainer") then
            local path = string.gsub(item:GetFullName(),"%.","/")
            if not expectedPaths[path] and path ~= "ReplicatedStorage/ApexDynamics/Dev/BuildInfo" then
                table.insert(drift,{path=path,reason="unexpected managed script"})
            end
        end
    end
end
local runtime = workspace:FindFirstChild("ApexReferenceSedan")
local runtimeFingerprint = if runtime then runtime:GetAttribute("SourceFingerprint") else nil
local runtimeFresh = runtimeFingerprint == nil or runtimeFingerprint == "FINGERPRINT"
return {success=#drift==0, checked=checked, drift=drift, expectedFingerprint="FINGERPRINT",runtimeFingerprint=runtimeFingerprint,runtimeFresh=runtimeFresh,action=if runtimeFresh then "none" else "restart play to load the current modules"}
'@
$script=$script.Replace('ENTRIES',($entries -join ",`n")).Replace('FINGERPRINT',$snapshot.fingerprint)
$destination=Join-Path $root '.local/generated/studio-audit.luau'
[IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
[IO.File]::WriteAllText($destination,$script)
Write-Output $destination
