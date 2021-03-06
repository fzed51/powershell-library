<#
.DESCRIPTION 
 Regarde periodiquement si des fichiers sont modifies, si c'est le cas il execute une commande 
 #>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String[]]
    $Path,
    $Commande,
    $Extension = "*.php",
    [Alias('Clear', "c")]
    [switch]$ClearScreen,
    [int]$Delay = 1
)

function GetHash {
    Param (
        $Path, 
        $Extension
    )
    return $Path`
    | Get-ChildItem -Filter $Extension -Recurse -File `
    | Get-FileHash
}

[array]$liste = @()

do {

    [array]$newListe = GetHash -Path $Path -Extension $Extension

    [array]$diff = Compare-Object $liste $newListe -Property Hash, Path -PassThru `
    | Select-Object -Property Path -Unique

    if ( $diff.Count -gt 0) {
        $liste = $newListe
        if ($ClearScreen) { Clear-Host }
        Write-Host $(Get-Date) -ForegroundColor white -NoNewline
        Write-Host " --> " -ForegroundColor DarkGray -NoNewline
        if ($diff.Count -gt 1) {
            Write-Host "$($diff.Count) fichiers" -ForegroundColor blue
        }
        else {
            Write-Host $diff.Path -ForegroundColor blue
        }
        &$Commande
    }

    Start-Sleep -s $Delay

} while ($true) 