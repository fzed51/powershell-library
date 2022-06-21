$URL = "https://fzed51.github.io/powershell-library"

$RegistryLIbrary = $URL + "/library/"
$PowershellDirectory = Split-Path $profile
$PowershellModuleDirectory = Join-Path $PowershellDirectory "Modules"
$InstalledModuleFile = Join-Path $PowershellDirectory "installed-module.json"

# RECUPERATION DU CATALOGUE
$handleWeb = Invoke-WebRequest ($URL + "/modules_catalog.json")
$catalog = ($handleWeb.content | ConvertFrom-Json)

# RECUPERATION DES MODULES INSTALLES
$Installed = Get-Content $InstalledModuleFile | ConvertFrom-Json
if ($Null -eq $Installed) {
    $Installed = @()
}
if ($Installed.GetType().Name -eq "PSCustomObject") {
    $Installed = @($Installed)
}

function updateModule {
    Param(
        $Old, 
        $New,
        $Collection
    )

    $Temps = New-Guid
    Rename-Item -Path (Join-Path $PowershellModuleDirectory $Old.name) -NewName $Temps
    
    $Collection = $Collection | Where-Object { $_.id -ne $Old.id }
    if ($Null -eq $Collection) {
        $Collection = @()
    }
    if ($Collection.GetType().Name -eq "PSCustomObject") {
        $Collection = @($Collection)
    }

    try {
        Invoke-WebRequest ($RegistryLIbrary + $New.name ) -OutFile (Join-Path $PowershellModuleDirectory $New.name)
        Remove-Item (Join-Path $PowershellModuleDirectory $Temps)
        Write-Host ("{0} a été mis à jour " -f $Old.name) -NoNewline
        Write-Host $Old.version -NoNewline -ForegroundColor DarkGreen
        Write-Host  " -> " -NoNewline 
        Write-Host $New.version -NoNewline -ForegroundColor Green
        $Collection = $Collection + $New        
    }
    catch {
        Rename-Item -Path (Join-Path $PowershellModuleDirectory $Temps) -NewName $Old.name
        $Collection = $Collection + $Old
    }

    return $Collection
}

$NewInstalled = $Installed.Clone()
$Installed | ForEach-Object {
    $InstalledModule = $_
    $catalog `
    | Where-Object { $_.id -eq $InstalledModule.id -and $_.version -ne $InstalledModule.version } `
    | ForEach-Object {
        $NewInstalled = updateModule -Old $InstalledModule -New $_ -Collection $NewInstalled
    }
}

$NewInstalled | ConvertTo-Json | Set-Content $InstalledModuleFile -Encoding ascii