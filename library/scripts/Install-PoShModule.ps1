$URL = "https://fzed51.github.io/powershell-library"
$handleWeb = Invoke-WebRequest ($URL + "/modules_catalog.json")
$catalog = ($handleWeb.content | ConvertFrom-Json)

function Join-Url {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Parent,
        [Parameter()]
        [String]
        $Child
    )
    return $Parent.TrimEnd('/') + '/' + $Child.TrimStart('/')
}

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

# CREATION DU DOSSIER 
$DirectoryModule = Join-Path $PowershellModuleDirectory $Module.name
$UrlModule = Join-Url $RegistryLIbrary  $Module.name

if (Test-Path  $DirectoryModule -PathType Container) {
    $ErrorMsg = "Le module {0} semble déjà être installé" -f $Module.name
    Write-Error -ErrorAction Stop -Category OperationStopped $ErrorMsg
}
New-Item  $DirectoryModule -Type Directory -ErrorAction SilentlyContinue
$Module.files | ForEach-Object {
    $DirectoryModuleFile = Join-Path $DirectoryModule (Split-Path $_)
    If ($DirectoryModuleFile -ne '' -and (-not (Test-Path $DirectoryModuleFile))) {
        New-Item $DirectoryModuleFile -Type Directory 
    }
    $UrlFile = Join-Url $UrlModule $_
    $PathFile = Join-Path $DirectoryModule $_
    Write-Host  $UrlFile, '->' , $PathFile
    Invoke-WebRequest $UrlFile -OutFile  $PathFile -ErrorAction Stop
}
New-ModuleManifest `
    -Path (Join-Path $DirectoryModule ("{0}.psd1" -f $Module.name) ) `
    -Guid $Module.id `
    -Author 'fzed51' `
    -CompanyName 'none' `
    -ModuleVersion $Module.version `
    -FileList $Module.files `
    -RootModule $Module.files[0] `
    -FunctionsToExport $Module.functionsn


if (Test-Path $InstalledModuleFile -PathType Leaf) {
    $Installed = Get-Content $InstalledModuleFile | ConvertFrom-Json
    if ($Null -eq $Installed) {
        $Installed = @()
    }
    if ($Installed.GetType().Name -eq "PSCustomObject") {
        $Installed = @($Installed)
    } 
}
else {
    $Installed = @()
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