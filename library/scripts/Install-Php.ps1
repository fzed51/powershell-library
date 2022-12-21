[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $Version,
    [switch]
    $NotThreadSafe,
    [switch]
    $X86
)

if ($X86) {
    $Archi = "x86"
}
else {
    $Archi = "x64"
}

if ($NotThreadSafe) {
    $Nts = "-nts"
}
else {
    $Nts = ""
}

# TODO : Ajouter une selection du vs en fonction de la version
#   ex :
#     vs = vs15
#     si version >= 8.0.0 alors vs = vs16
$PhpName = "php-$Version$Nts-Win32-vs16-$Archi"
$TmpFile = Join-Path $Env:Tmp "$PhpName.zip"
$Link = "https://windows.php.net/downloads/releases/$PhpName.zip"


Write-Host "Temp file : " , $TmpFile

Invoke-WebRequest -Uri $Link -OutFile $TmpFile

# Preparation du dossier d'installation

# TODO : Essayer de récupérer PhpDirectory en récuperant la source de
#    la commande php
$PhpDirectory = Join-Path $env:ProgramFiles "php"
$PhpDirectoryRun = Join-Path $PhpDirectory "php"
$PhpDirectoryVersion = Join-Path $PhpDirectory $PhpName

if (-not (Test-Path -PathType Container -Path $PhpName)) {
    New-Item $PhpDirectory -ItemType Directory -Force | Out-Null
}

Get-Command '7z.exe' -ErrorAction Stop | Out-Null
New-Item $PhpDirectoryVersion -ItemType Directory -Force | Out-Null

7z.exe x -o"$PhpDirectoryVersion" $TmpFile

if (-not (Test-Path $PhpDirectoryRun)) {
    New-Item -ItemType Junction $PhpDirectoryRun -Value $PhpDirectoryVersion `
    | Out-Null
}

$PhpCmd = Get-Command 'php' -ErrorAction SilentlyContinue
if (-not $PhpCmd) {
    $PathUser = [System.Environment]::GetEnvironmentVariable('Path', 'user')
    $PathUser = (($PathUser -split ';') + $PhpDirectoryRun) -join ';'
    [System.Environment]::SetEnvironmentVariable('Path', $PathUser, 'user')
}

Remove-Item $TmpFile