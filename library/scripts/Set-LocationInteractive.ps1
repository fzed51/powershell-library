[CmdletBinding(DefaultParameterSetName = 'SetLocation')]
param (
    [Parameter(
        Mandatory = $true,
        ParameterSetName = "SetLocation",
        Position = 1,
        ValueFromPipeline = $true,
        HelpMessage = "New location."
    )]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string]
    $Location,
    [Parameter(
        Mandatory = $true,
        ParameterSetName = "Install"
    )]
    [switch]
    $InstallAlias
)

function InstallAlias {
    if ($Null -ne (get-alias cdi -erroraction Ignore)) {
        Write-Error "L'alias existe déjà" -Category OperationStopped -ErrorAction Stop
    }
    $MyPath = Get-Item $MyInvocation.MyCommand
    @"
    New-Alias -Name cdi -Value $MyPath
"@ | Add-Content $PROFILE
}


function SetLocation {
    Param(
        [string]
        $Location
    )
    
    $Location = $Location.Replace('\', '/')

    if ($Location -imatch "^([a-z]:)?(.*)$") {
        [string]$Drive = $Matches[1]
        [string]$Path = $Matches[2]

        $Path = $Path.replace('//', '/')
        $Path = $Path.replace('/', '*/')
        $Path = $Path.replace('~*/', '~/')
        $Path = $Path.replace('.*/', './')

        if (-not $Path.EndsWith("/")) {
            $Path = $Path + "*"
        }

        if ($Path.StartsWith("*/")) {
            $Path = $Path.TrimStart('*')
        }

        Write-Host ($Drive + $Path) -ForegroundColor DarkGray
        $Solutions = Resolve-Path ($Drive + $Path)

        if ($Solutions.Length -eq 1) {
            Set-Location $Solutions[0].Path
        }
    }
}

if ($InstallAlias) {
    InstallAlias
}
else {
    SetLocation $Location
}
