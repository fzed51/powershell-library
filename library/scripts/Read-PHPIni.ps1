[CmdletBinding()]
param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = "Chemin d'un fichier.")]
    [Alias("PSPath", "FullName")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-path $_ })]
    [string]
    $Path
)

begin {
    function addData {
        Param(
            [hashtable]$Data,
            [string]$Section,
            [string]$Key,
            [string]$Value
        )
        if ((controlSection $Data $Section) -eq 0) {
            $Data[$Section] = @{ }
        }
        if ((controlKey $Data $Section $Key) -eq 0) {
            $Data[$Section][$Key] = @()
        }
        $Data[$Section][$Key] += $Value
    }
    function controlSection {
        Param(
            [hashtable]$data,
            [string]$Section
        )
        if ($data.ContainsKey($Section)) {
            return 1
        }
        return 0
    }
    function controlKey {
        Param(
            [hashtable]$data,
            [string]$Section,
            [string]$Key
        )
        if ($data[$Section].ContainsKey($Key)) {
            return 1
        }
        return 0
    }
}

process {
    $Data = @{ }
    $CurentSection = "unknow"
    Get-Content $Path | Where-Object {
        "$_".trim().length -gt 0 -and -not("$_".trim().StartsWith(';'))
    } | ForEach-Object {
        $line = "$_".trim()
        switch -regex ($line) {
            "^\[(.*)\]$" {
                # Write-Host "[$($Matches[1])]"
                $CurentSection = $Matches[1].trim()
            }
            "^([^=]*)\s*\=\s*(.*)$" {
                # Write-Host "$($Matches[1]) = $($Matches[2])"
                addData $Data $CurentSection $Matches[1].Trim() $Matches[2].Trim()
            }
            Default {
                Write-Host $_ -ForegroundColor Red
            }
        }
    }
}

end {
    $Data
}

