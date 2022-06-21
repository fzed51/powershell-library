<#
.SYNOPSIS
    déplace un item et le remplace par un lien symbol menant vers sa copie
.DESCRIPTION
    déplace le contenu de l'item et le remplace l'item par un lien symbol menant vers la destiantion de sa copie
.EXAMPLE
    Move-Item
#>

[CmdletBinding()]
param (
    # Chemin de l'item
    [Parameter(Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Un ou plusieur chemin à déplacer.")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_ | Test-Path -PathType Container })]
    [string[]]
    $Item,
    # Destination
    [Parameter(Mandatory = $true,
        Position = 1 ,
        HelpMessage = "Chemin destination des éléments copiés.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_ | Test-Path -PathType Container })]
    [string]
    $Destination
)   
begin {
    $Identity = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    $IsAdmin = $Identity.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $IsAdmin) {
        Write-Error "Ce script nécésite une élévation supérieure." `
            -ErrorAction Stop `
            -Category PermissionDenied
    }

    function MoveAndReplaceItem {
        Param(
            [String] $Source,
            [String] $Destination
        )
        $SourceName = Get-Item $Source | Select-Object -ExpandProperty BaseName

        $ItemContent = Get-ChildItem $Source -Force

        if ($ItemContent -ne $null -and $ItemContent.Length -gt 0) {
            $ItemContent | ForEach-Object {
                $Element = $_
                $DestinationName = $Element.Name
                $Index = 1
                While (Test-Path (Join-Path $Destination $DestinationName)) {
                    $DestinationName = "{0}({1}){2}" -f $Element.BaseName, $Index, $Element.Extension
                    $Index++
                }
                $Element | Add-Member -Name 'DestinationName' -MemberType NoteProperty -Value $DestinationName
                $Element
            } | ForEach-Object {
                $_ | Move-Item -Destination (Join-Path $Destination $_.DestinationName)
            }
        }
        Remove-Item $Source
        New-Item $Source -ItemType SymbolicLink -Value $Destination
    }

}
    
process {
    $Item | ForEach-Object { MoveAndReplaceItem -Source $_ -Destination $Destination }    
}

End {}