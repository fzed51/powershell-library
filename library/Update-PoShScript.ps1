$RegistryLIbrary = "https://raw.githubusercontent.com/fzed51/powershell-library/main/library/"
$PowershellDirectory = Split-Path $profile
$PowershellScriptDirectory = Join-Path $PowershellDirectory "Scripts"
$InstalledScriptFile = Join-Path $PowershellDirectory "installed-script.json"

# RECUPERATION DU CATALOGUE
$handleWeb = wget "https://raw.githubusercontent.com/fzed51/powershell-library/main/catalog.json"
$catalog = ($handleWeb.content | ConvertFrom-Json)

# RECUPERATION DES SCRIPTS INSTALLES
$Installed = Get-Content $InstalledScriptFile | ConvertFrom-Json
if ($Installed -eq $Null) {
    $Installed = @()
}
if ($Installed.GetType().Name -eq "PSCustomObject") {
    $Installed = @($Installed)
}

function updateScript {
    Param(
        $Old, 
        $New,
        $Collection
    )

    $Temps = New-Guid
    $OldScript = Join-Path $PowershellScriptDirectory $Old.name
    Move-Item $OldScript -Destination $Temps

    $Collection = $Collection | Where-Object { $_.id -ne $Old.id }
    if ($Null -eq $Collection) {
        $Collection = @()
    }
    if ($Collection.GetType().Name -eq "PSCustomObject") {
        $Collection = @($Collection)
    }

    try {
        Invoke-WebRequest ($RegistryLIbrary + $New.name ) -OutFile (Join-Path $PowershellScriptDirectory $New.name)
        Remove-Item $Temps
    }
    catch {
        Move-Item $Temps -Destination $OldScript
    }
    $Collection = $Collection + $New

    return $Collection
}

$Installed | ForEach-Object {
    $InstalledScript = $_
    $catalog `
    | Where-Object { $catalog.id -eq $InstalledScript.id -and $catalog.version -eq $InstalledScript.version } `
    | ForEach-Object {
        $Installed = updateScript -Old $InstalledScript -New $_ -Collection $Installed
    }
}

$Installed | ConvertTo-Json | Set-Content $InstalledScriptFile -Encoding ascii