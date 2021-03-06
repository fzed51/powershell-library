<#
.SYNOPSIS
    Lance le serveur PHP de dev
.DESCRIPTION
    Démarre une instance du serveur de développement de PHP avec des paramètres
    enregistré dans l'emplacement courent.
.EXAMPLE
    PS C:\> Start-ServeurPHP.ps1
    Execute le serveur avec les paramètre local, ou executre le serveur avec
    les paramètres standart et cré un fichier de paramétrage en local.
.EXAMPLE
    PS C:\> Start-ServeurPHP.ps1 -Port 8888 -UpdateParamFile
    Modifie le port d'écoute du serveur en modifiant le fichier de paramètre
    local.
#>
[CmdletBinding()]
param (
    [string] $Domaine,
    [int]    $Port,
    [string] $DocumentRoot,
    [switch] $XDebug,
    [switch] $UpdateParamFile = $false,
    [switch] $Open
)
    
begin {
    $php = Get-Command php -ErrorAction Stop
    $ParamFileName = "serveur.json"
    $ParamFilePresent = $false
    $Param = @{
        "Domaine"="127.0.0.1";
        "Port"=80;
        "DocumentRoot"='.';
        "XDebug"=$false
    }

    if(Test-Path $ParamFileName){
        $fileParam = Get-Content $ParamFileName -Encoding UTF8 | ConvertFrom-Json
        if($fileParam.Domaine) {$Param.Domaine = $fileParam.Domaine}
        if($fileParam.Port) {$Param.Port = $fileParam.Port}
        if($fileParam.DocumentRoot) {$Param.DocumentRoot = $fileParam.DocumentRoot}
        if($fileParam.XDebug) {$Param.XDebug = $fileParam.XDebug}
        $ParamFilePresent = $true
    } 

    if($PSBoundParameters.Domaine) {$Param.Domaine = $PSBoundParameters.Domaine}
    if($PSBoundParameters.Port) {$Param.Port = $PSBoundParameters.Port}
    if($PSBoundParameters.DocumentRoot) {$Param.DocumentRoot = $PSBoundParameters.DocumentRoot}
    if($PSBoundParameters.XDebug) {$Param.XDebug = $true}

    if($UpdateParamFile -or !$ParamFilePresent){
        $Param | ConvertTo-Json | Set-Content $ParamFileName -Encoding UTF8
    }
}
    
process {

    if ($Open) {
        $StartBrowser = {
            Param( [string] $Url)
            Start-Sleep -s 1
            Start-Process $Url
        }
        Start-Job $StartBrowser -ArgumentList "http://$($Param.Domaine):$($Param.Port)" | Out-Null
    }

    if ($XDebug) {
        &$php -dxdebug.default_enable=on -dxdebug.remote_enable=on -dxdebug.remote_autostart=on -dxdebug.remote_connect_back=on -dxdebug.cli_color=2 -S $($Param.Domaine + ":" + $Param.Port) -t $($Param.DocumentRoot) 
    } else {
        &$php -S $($Param.Domaine + ":" + $Param.Port) -t $($Param.DocumentRoot)
    }


}