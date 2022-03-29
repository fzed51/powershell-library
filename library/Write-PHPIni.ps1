[CmdletBinding()]
param (
    [Parameter(Mandatory = $true,
        Position = 0)]
    [hashtable]$Data,
    [Parameter(Mandatory = $true,
        Position = 1,
        HelpMessage = "Chemin ver le fichier ini à écrire.")]
    [ValidateScript( {
            (test-path $_ -IsValid) -and "$_".EndsWith('.ini')
        })]
    [string]$Path
)

process {
    [string]$IniString = ""
    $Data.GetEnumerator() | ForEach-Object {
        [string]$CurentSection = $_.Name
        [HashTable]$SectionData = $_.Value
        [string]$SectionString = "[$CurentSection]`n"
        try {
            $SectionData.GetEnumerator() | ForEach-Object {
                $CurentKey = $_.Name
                $Value = $_.Value
                $Value | ForEach-Object {
                    $SectionString += "$CurentKey = $_`n"
                }
            }
            $IniString += $SectionString + "`n"
        }
        catch {
            Write-Warning "La section $CurentSection n'a pas de donnée"
        }
        finally {
            $SectionString = ""
        }
    }
    $IniString | Set-Content -Path $Path -Encoding UTF8 -Force
}