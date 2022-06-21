$URL = "https://fzed51.github.io/powershell-library"
$handleWeb = Invoke-WebRequest ($URL + "/catalog.json")
$catalog = ($handleWeb.content | ConvertFrom-Json)

$RegistryLIbrary = $URL + "/library/"
$PowershellDirectory = Split-Path $profile
$PowershellScriptDirectory = Join-Path $PowershellDirectory "Scripts"
$InstalledScriptFile = Join-Path $PowershellDirectory "installed-script.json"

$Index = 1
$catalog | ForEach-Object {
    Write-Host ("{0} - {1}" -f $Index, $_.name)
    $Index ++
}

[int]$NScript = Read-Host "No du script à installer"

$Script = $catalog[$NScript - 1];
Write-Host ("Vous allez installer {0}" -f $Script.name) 

if (-not (Test-Path $PowershellScriptDirectory -PathType Container)) {
    New-Item $PowershellScriptDirectory -Force | Out-Null
}

Invoke-WebRequest ($RegistryLIbrary + $Script.name ) -OutFile (Join-Path $PowershellScriptDirectory $Script.name)

if (Test-Path $InstalledScriptFile -PathType Leaf) {
    $Installed = Get-Content $InstalledScriptFile | ConvertFrom-Json
    if ($Null -eq $Installed) {
        $Installed = @()
    }
    if ($Installed.GetType().Name -eq "PSCustomObject") {
        $Installed = @($Installed)
    } 
}
$Installed = $Installed | Where-Object { $_.id -ne $Script.id }
if ($Null -eq $Installed) {
    $Installed = @()
}
if ($Installed.GetType().Name -eq "PSCustomObject") {
    $Installed = @($Installed)
} 

$Installed = $Installed + $Script

$Installed | ConvertTo-Json | Set-Content $InstalledScriptFile -Encoding ascii