$URL = "https://fzed51.github.io/powershell-library"
$handleWeb = Invoke-WebRequest ($URL + "/scripts_catalog.json")
$catalog = ($handleWeb.content | ConvertFrom-Json)

$RegistryLIbrary = $URL + "/library/scripts/"
$PowershellDirectory = Split-Path $profile
$PowershellScriptDirectory = Join-Path $PowershellDirectory "Scripts"
$InstalledScriptFile = Join-Path $PowershellDirectory "installed-script.json"

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

$Script = $catalog[$NScript - 1];
Write-Host ("Vous allez installer {0}" -f $Script.name) 

if (-not (Test-Path $PowershellScriptDirectory -PathType Container)) {
    New-Item $PowershellScriptDirectory -Force | Out-Null
}
# Test du dossier scripts dans la variable d'environement Path
[string[]]$Path = `
([System.Environment]::GetEnvironmentVariable('PATH', 'user')).split(';') `
| ForEach-Object { $_.TrimEnd('/\') }
if ($Path -notcontains $PowershellScriptDirectory.TrimEnd('/\')) {
    [System.Environment]::SetEnvironmentVariable('PATH', (
        ($Path -join ";") + ";" + $PowershellScriptDirectory
        ), 'user')
    Write-Host ("Le dossier {0} a été enregistré dans les variables d'environement" -f $PowershellScriptDirectory)
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
    $Installed = $Installed | Where-Object { $_.id -ne $Script.id }
    if ($Null -eq $Installed) {
        $Installed = @()
    }
    if ($Installed.GetType().Name -eq "PSCustomObject") {
        $Installed = @($Installed)
    } 

    $Installed = $Installed + $Script

    $Installed | ConvertTo-Json | Set-Content $InstalledScriptFile -Encoding ascii
}
else {
    Write-Error "Un problème est survenu lors du téléchargement du fichier" -Category ResourceUnavailable -ErrorAction Stop
}