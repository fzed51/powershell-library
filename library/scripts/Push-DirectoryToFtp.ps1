<#
.SYNOPSIS
    Envoie le dossier local sur un serveur ftp
.DESCRIPTION
    Envoie le dossier local sur un serveur ftp
#>

[CmdletBinding()]
param (
    [string] $SrvSftp,
    [string] $User,
    [string] $Source = ".",
    [string] $Destination = ""
)

Get-Command psftp.exe -ErrorAction Stop | Out-Null

function ConvertFrom-SecureStringToPlain {
    param( [Parameter(Mandatory = $true)][System.Security.SecureString] $SecurePassword)
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    $PlainTextPassword
}

Push-Location
Set-Location $Source
$Names = Get-ChildItem -Recurse -Name
$Items = $Names | ForEach-Object {
    $i = Get-Item $_
    if ($i.PSIsContainer) {
        $type = "directory"
    }
    else {
        $type = "file"
    }
    New-Object psobject -Property @{name = $_; type = $type }
}


$pass = Read-Host "Mot de pass" -AsSecureString
$PassFile = New-TemporaryFile
try {
    ConvertFrom-SecureStringToPlain $pass | Set-Content $PassFile

    $Destination = $Destination.Replace('\', '/').TrimEnd('/')

    if ($Destination -ne ''){
        $origin = ''
        $Destination.split('\') | % { $_.split('/')} | % {
            $cmd = "mkdir {0}{1}" -f $origin, $_
            $origin = $origin + $_ + '/'
            $cmd
        } | psftp.exe -pwfile $PassFile.FullName ("{0}@{1}" -f $User, $SrvSftp)
        $Destination = $Destination + '/'
    }

    $Items | ForEach-Object {
        if ($_.type -eq "directory") {
            # $ls = ("ls {0}{1}" -f $Destination, $_.name.Replace('\', '/')) | psftp.exe -pwfile $PassFile.FullName ("{0}@{1}" -f $User, $SrvSftp)
            # Write-Host -ForegroundColor Cyan -Separator "`n" $ls
            ("mkdir {0}{1}" -f $Destination, $_.name.Replace('\', '/')) 
        }
        else {
            ("put {0} {1}{2}" -f $_.name, $Destination, $_.name.Replace('\', '/')) 
        }
    } | psftp.exe -pwfile $PassFile.FullName ("{0}@{1}" -f $User, $SrvSftp)
}
finally {
    Remove-Item $PassFile
}

Pop-Location