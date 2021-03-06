<# 
.DESCRIPTION 
 Récupère les fichiers utiliser pour l'écran de verouillage enregistré dans le dossier de cache. 
#> 

[CmdletBinding()]
param (
    $Destination = $((Get-Location).Path) ,
    [switch]$test
)

Begin {

    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    function GetImageInfo {
        Param(
            [string]$Path
        )
        process {
            $Path = Resolve-Path -Path $Path | Select-Object -First 1 -ExpandProperty Path
            $img = [System.Drawing.Image]::FromFile($Path)
            $Size = $img.Size
            $img.Dispose()
            return $Size
        }
    }

    function poucent {
        Param([int]$a, [int]$b)
        if ($b -eq 0) {
            return 0
        }
        return [System.Math]::Min(
            100, 
            [System.Math]::Round(100 * $a / $b)
        )
    }

    function Test-Jpeg {
        Param($Path)
        $head = Get-Content $path -Encoding Byte -TotalCount 4
        # jpeg au format JIFF
        if ($head[0] -eq 255 -and $head[1] -eq 216 -and $head[2] -eq 255 -and $head[3] -eq 224) { return $True }
        # jpeg au format EXIF
        if ($head[0] -eq 255 -and $head[1] -eq 216 -and $head[2] -eq 255 -and $head[3] -eq 225) { return $True }
        return $False
    }
}
Process {

    [int]$nbAction = 2
    [int]$nbActionDone = 0

    [string]$ContentManagerPath = ""
    try {
        $ContentManagerPath = Resolve-Path ($env:APPDATA + "/../Local/Packages/Microsoft.Windows.ContentDeliveryManager*/LocalState/Assets") -ErrorAction Stop
    }
    catch {
        Write-Error "Impossible d'importer les images du Content Manager de Microsoft. Le chemin du manager n'existe pas." -Category ObjectNotFound -ErrorAction Stop
    }

    Write-Progress -Activity "Scan des photos existantes" -PercentComplete $(poucent $nbActionDone $nbAction)

    [int]$nbIdem = 0
    [array]$ListePhoto = Get-ChildItem $Destination -Recurse -File
    $nbActionDone++
    $nbAction = $nbAction + $ListePhoto.Count
    Write-Progress -Activity "Scan des photos existantes" -PercentComplete $(poucent $nbActionDone $nbAction)

    [array]$ListeUnique = Get-ChildItem $Destination -Recurse -File | ForEach-Object {
        $nbActionDone++
        Write-Progress -Activity "Scan des photos existantes" -PercentComplete $(poucent $nbActionDone $nbAction)
        $_ | Get-FileHash
    }

    Write-Progress -Activity "Scan des photos à copier" -PercentComplete $(poucent $nbActionDone $nbAction)
    [array]$listeImages = Get-ChildItem $ContentManagerPath | Where-Object {
        Test-Jpeg $_.FullName -and $_.length -gt (350 * 1Kb)
    } | Where-Object {
        $size = (GetImageInfo -Path $_.FullName)
        $size.width -gt $size.height -and $size.height -ge 1080
    } | Where-Object {
        $fileHash = (Get-FileHash $_.FullName).Hash
        if ( $fileHash -notin $ListeUnique.Hash ) {
            $True
        }
        else {
            $nbIdem++
            if ($VerbosePreference -eq 'Continue') {
                $oldFile = $ListeUnique | Where-Object { $_.Hash -eq $fileHash } | Resolve-Path -Relative
                Write-Verbose "Une photo est déjà présente sous le nom $oldFile"
            }
            $False
        }
    }
    $nbActionDone++
    $nbAction = $nbAction + $listeImages.Count
    [int]$i = 1
    $listeImages | Where-Object { $_ -ne $null } | Copy-Item -Destination $Destination -PassThru -WhatIf:$test | ForEach-Object {
        $nbActionDone++
        Write-Progress -Activity "copie des photos" -PercentComplete $(poucent $nbActionDone $nbAction)
        if (!$test) {
            $_ | Rename-Item -NewName $("image_{0}-{1}.jpg" -f $(Get-Date -Format "yyyyMMdd"), $i++)
        }
    }

    Write-Host -no $nbIdem -ForegroundColor DarkCyan
    Write-Host " fichier(s) non copié car déjà présent."
    Write-Host -no ($listeImages.Count) -ForegroundColor Cyan
    Write-Host " fichier(s) copié(s)."

}

End {
    Start-Sleep -Seconds 1
}
