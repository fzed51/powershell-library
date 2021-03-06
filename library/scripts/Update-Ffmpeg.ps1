<#
.SYNOPSIS
    Script de mise à jour de ffmpeg
.DESCRIPTION
    Script de mise à jour de ffmpeg, Après téléchargement de la dernière archive de ffmpeg, le script compare les version et met à jour ffmpeg si il y a besoin.
.EXAMPLE
    PS C:\> Update-Ffmpeg
    ise à jour de ffmpeg
#>
[CmdletBinding()]
param (
    [switch]$Setup
)

begin {
    # http://ffmpeg.zeranoe.com/builds/win64/shared/ffmpeg-latest-win64-shared.7z

    
    $7z = Get-Command '7z' -ea Stop
    function WritePassFail {
        Param (
            [switch] $Pass,
            [switch] $fail
        )
        if($Host.UI.RawUI.MaxWindowSize -ne $null){
            [int]$width = $Host.UI.RawUI.MaxWindowSize.Width
            [int]$posX = $Host.UI.RawUI.CursorPosition.X
            [int]$rest = $width - $posX - 7
            if($rest -lt 1){
                Write-Host ''
                $rest = $width - 7
            }
            Write-Host ("." * $rest) -NoNewline -ForegroundColor darkgray
        } else {
            Write-Host "..." -NoNewline -ForegroundColor darkgray
        }
        Write-Host "[" -NoNewline -ForegroundColor darkgray
        if($pass -or (-not $fail)){
            Write-Host "pass" -NoNewline -ForegroundColor DarkGreen
        } else {
            Write-Host "fail" -NoNewline -ForegroundColor DarkRed
        }
        Write-Host "]"    -ForegroundColor darkgray
    }

    [string]$ServeurDownload = "http://ffmpeg.zeranoe.com/builds/win64/shared/"
    [string]$ArchiveFfmpeg = "ffmpeg-latest-win64-shared"
    [string]$extensionArchive = ".zip"
}

process {
    Push-Location
    Set-Location ~
    Set-Location $env:TEMP

    Write-Host "Téléchargement de la dernière versin de ffmpeg." -ForegroundColor DarkGray
    Write-Host "> $($ServeurDownload+$ArchiveFfmpeg+$extensionArchive)" -NoNewline -ForegroundColor DarkGray
    Invoke-WebRequest -Uri ($ServeurDownload+$ArchiveFfmpeg+$extensionArchive) -OutFile ($ArchiveFfmpeg+$extensionArchive) -ErrorAction Stop
    WritePassFail -Pass

    Write-Host "Décompression du fichier téléchargé." -NoNewline -ForegroundColor DarkGray
    if( Test-Path $ArchiveFfmpeg -PathType Container ){
        remove-item $ArchiveFfmpeg -Recurse -Force
    }
    &$7z x ($ArchiveFfmpeg+$extensionArchive) | Out-Null
    WritePassFail -Pass

    Write-Host "Test des versions de ffmpeg." -ForegroundColor DarkGray
    $ffmpeg = Get-Command 'ffmpeg.exe' -ErrorAction Stop
    $newFfmpeg = Get-Command "./$ArchiveFfmpeg/bin/ffmpeg.exe"
    $newVersion = &$newFfmpeg -version |Select-String version | Select-Object -First 1
    $version = &$ffmpeg -version |Select-String version | Select-Object -First 1
    Write-Host "Version actuelle de ffmpg : " -ForegroundColor DarkGray
    Write-Host $version.ToString() -ForegroundColor Gray
    if( $newVersion.ToString() -gt $version.ToString() ){
        $dossierBase = Resolve-Path (Join-Path ($ffmpeg.Source | Split-path -parent) -ChildPath '..')
        Remove-Item -Path $dossierBase -Recurse -Force
        get-item "ffmpeg-latest-win64-shared" | Move-Item -Destination $dossierBase
        Write-Host "Nouvelle version de ffmpg : " -ForegroundColor DarkGray
        Write-Host $newVersion.ToString() -ForegroundColor Gray
        Write-host "ffmpeg a été mis à jour" -ForegroundColor green
    } else {
        Write-host "ffmpeg est à jour" -ForegroundColor DarkYellow
    }
    Pop-Location
}

end {
}
