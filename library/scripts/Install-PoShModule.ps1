$URL = "https://fzed51.github.io/powershell-library"
$handleWeb = Invoke-WebRequest ($URL + "/modules_catalog.json")
$catalog = ($handleWeb.content | ConvertFrom-Json)

$RegistryLIbrary = $URL + "/library/modules/"
$PowershellDirectory = Split-Path $profile
$PowershellModuleDirectory = Join-Path $PowershellDirectory "Modules"
$InstalledModuleFile = Join-Path $PowershellDirectory "installed-module.json"

$Index = 1
$catalog | ForEach-Object {
    Write-Host ("{0} - {1}" -f $Index, $_.name)
    $Index ++
}

$Rep = Read-Host "No du script à installer"
if ($Rep -notmatch "\d+") {
    # FIN DU SCRIPT
    return ;
}
[int]$NScript = $Rep

$Module = $catalog[$NScript - 1];
Write-Host ("Vous allez installer le module {0}" -f $Module.name) 

if (-not (Test-Path $PowershellModuleDirectory -PathType Container)) {
    New-Item $PowershellModuleDirectory -Force | Out-Null
}
# Test du dossier module dans la variable d'environement PSModulePath
[string[]]$EnvPSModulePath = `
([System.Environment]::GetEnvironmentVariable('PSModulePath', 'user')).split(';') `
| ForEach-Object { $_.TrimEnd('/\') }
if ($EnvPSModulePath -notcontains $PowershellModuleDirectory.TrimEnd('/\')) {
    [System.Environment]::SetEnvironmentVariable('PSModulePath', (
        ($PowershellModuleDirectory + ";" + ($EnvPSModulePath -join ";"))
        ), 'user')
    Write-Host ("Le dossier {0} a été enregistré dans les variables d'environement" -f $PowershellModuleDirectory)
}

Invoke-WebRequest ($RegistryLIbrary + $Module.name ) -OutFile (Join-Path $PowershellModuleDirectory $Module.name)

if (Test-Path $InstalledModuleFile -PathType Leaf) {
    $Installed = Get-Content $InstalledModuleFile | ConvertFrom-Json
    if ($Null -eq $Installed) {
        $Installed = @()
    }
    if ($Installed.GetType().Name -eq "PSCustomObject") {
        $Installed = @($Installed)
    } 
    $Installed = $Installed | Where-Object { $_.id -ne $Module.id }
    if ($Null -eq $Installed) {
        $Installed = @()
    }
    if ($Installed.GetType().Name -eq "PSCustomObject") {
        $Installed = @($Installed)
    } 

    $Installed = $Installed + $Module

    $Installed | ConvertTo-Json | Set-Content $InstalledModuleFile -Encoding ascii
}
else {
    Write-Error "Un problème est survenu lors du téléchargement du fichier" -Category ResourceUnavailable -ErrorAction Stop
}