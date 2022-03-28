$RegistryLIbrary = "https://fzed51.github.io/powershell-library/library/"
$PowershellDirectory = Split-Path $profile
$PowershellScriptDirectory = Join-Path $PowershellDirectory "Scripts"
$InstalledScriptFile = Join-Path $PowershellDirectory "installed-script.json"

# RECUPERATION DU CATALOGUE
$handleWeb = wget "https://fzed51.github.io/powershell-library/catalog.json"
$catalog = ($handleWeb.content | ConvertFrom-Json)

# RECUPERATION DES SCRIPTS INSTALLES
$Installed = Get-Content $InstalledScriptFile | ConvertFrom-Json
if ($Null -eq $Installed) {
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
    Rename-Item -Path (Join-Path $PowershellScriptDirectory $Old.name) -NewName $Temps
    
    $Collection = $Collection | Where-Object { $_.id -ne $Old.id }
    if ($Null -eq $Collection) {
        $Collection = @()
    }
    if ($Collection.GetType().Name -eq "PSCustomObject") {
        $Collection = @($Collection)
    }

    try {
        Invoke-WebRequest ($RegistryLIbrary + $New.name ) -OutFile (Join-Path $PowershellScriptDirectory $New.name)
        Remove-Item (Join-Path $PowershellScriptDirectory $Temps)
        Write-Host ("{0} a été mis à jour " -f $Old.name) -NoNewline
        Write-Host $Old.version -NoNewline -ForegroundColor DarkGreen
        Write-Host  " -> " -NoNewline 
        Write-Host $New.version -NoNewline -ForegroundColor Green
        
    }
    catch {
        Rename-Item -Path (Join-Path $PowershellScriptDirectory $Temps) -NewName $Old.name
    }
    $Collection = $Collection + $New

    return $Collection
}

$NewInstalled = $Installed.Clone()
$Installed | ForEach-Object {
    $InstalledScript = $_
    $catalog `
    | Where-Object { $_.id -eq $InstalledScript.id -and $_.version -ne $InstalledScript.version } `
    | ForEach-Object {
        $NewInstalled = updateScript -Old $InstalledScript -New $_ -Collection $NewInstalled
    }
}

$NewInstalled | ConvertTo-Json | Set-Content $InstalledScriptFile -Encoding ascii