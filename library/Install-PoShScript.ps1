$handleWeb = wget "https://raw.githubusercontent.com/fzed51/powershell-library/main/catalog.json"
$catalog = ($handleWeb.content | ConvertFrom-Json)

$RegistryLIbrary = "https://raw.githubusercontent.com/fzed51/powershell-library/main/library/"
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

wget ($RegistryLIbrary + $Script.name ) -OutFile (Join-Path $PowershellScriptDirectory $Script.name)

if (Test-Path $InstalledScriptFile -PathType Leaf) {
    $Installed = Get-Content $InstalledScriptFile | ConvertFrom-Json
    if ($Installed -eq $Null) {
        $Installed = @()
    }
    if ($Installed.GetType().Name -eq "PSCustomObject") {
        $Installed = @($Installed)
    } 
}
$Installed = $Installed | ? { $_.name -ne $Script.name }
$Installed = $Installed + $Script

$Installed | ConvertTo-Json | Set-Content $InstalledScriptFile -Encoding ascii