function Set-Env {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [string[]]$Value,
        [ValidateSet('machine', 'user', 'process')]
        [string]$Scope = 'process'
    )

    begin {
        [string]$StrValue = ''
    }
    process {
        $StrValue = ($StrValue + ";" + ($Value -join ";")).TrimStart(';')
    }
    end {
        Write-Host $StrValue -fo Cyan
        [System.Environment]::SetEnvironmentVariable($Name, $StrValue, $Scope)
    }

}


function Get-Env {
    [OutputType([string], [string[]])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [ValidateSet('machine', 'user', 'process')]
        [string]$Scope = 'process',
        [switch]$List,
        [string[]]$Default = $null
    )

    if ($List) {
        $var = [System.Environment]::GetEnvironmentVariable($Name, $Scope)
        return [string[]] $var.split(';')
        
    }
    [string][System.Environment]::GetEnvironmentVariable($Name, $Scope)

}

function Add-EnvList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [string[]]$Value,
        [ValidateSet('machine', 'user', 'process')]
        [string]$Scope = 'process'
    )
    Begin {
        [String[]]$List = Get-Env $Name -List -Scope $Scope
    }
    Process {
        $List = $List + $Value
    }
    End {
        Set-Env -Scope $Scope -Name $Name -Value $List
    }
}

function Test-Env {
    [OutputType([boolean])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [string[]]$Value,
        [ValidateSet('machine', 'user', 'process')]
        [string]$Scope = 'process'
    )
    Begin {
        [string]$StrValue = ""
    }
    Process {
        $StrValue = ($StrValue + ";" + ($Value -join ";")).TrimStart(';')
    }
    End {
        [string]$Stored = Get-Env -Scope $Scope -Name $Name
        return $Stored -eq $StrValue
    }

}
function Test-EnvList {
    [OutputType([boolean])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true)]
        [string]$Value,
        [ValidateSet('machine', 'user', 'process')]
        [string]$Scope = 'process'
    )
    
    [string[]]$Stored = Get-Env -Scope $Scope -Name $Name -List
    return $Stored -contains $Value

}

Export-ModuleMember -Function Set-Env, Get-Env, Add-EnvList, Test-Env, Test-EnvList