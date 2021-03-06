[CmdletBinding()]
param(
    [Parameter()]
    [switch]$List
)

DynamicParam {
    $PackageFile = '.\package.json'
    $ComposerFile = '.\composer.json'
    [bool]$IsNpm = $false
    # RECUPERATION DE LA LISTE DES NOM DE SCRIPT
    $ScriptsName = @()
    if (Test-Path $PackageFile) {
        $IsNpm = $true
        $ScriptsName = Get-Content $PackageFile `
        | ConvertFrom-Json `
        | Select-Object -ExpandProperty scripts `
        | Get-Member `
        | Where-Object { $_.MemberType -eq 'NoteProperty' } `
        | Select-Object -ExpandProperty Name
    }
    elseif (Test-Path $ComposerFile) {
        $ScriptsName = Get-Content $ComposerFile `
        | ConvertFrom-Json `
        | Select-Object -ExpandProperty scripts `
        | Get-Member `
        | Where-Object { $_.MemberType -eq 'NoteProperty' } `
        | Select-Object -ExpandProperty Name
    }
    if ((-not $List)) {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # DECLARATION DU PARAMETRE ScriptName
        $scriptAttribute = New-Object System.Management.Automation.ParameterAttribute
        $scriptAttribute.Position = 1
        $scriptAttribute.Mandatory = $true
        $scriptAttribute.HelpMessage = "Nom du script a executer"
        $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($scriptAttribute)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ScriptsName)
        $attributeCollection.Add($ValidateSetAttribute)
        $scriptParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ScriptName', [string], $attributeCollection)
        $paramDictionary.Add('ScriptName', $scriptParam)
        # DECLARATION DU PARAMETRE UseNpm
        if ($IsNpm) {
            $scriptAttributeSwitch = New-Object System.Management.Automation.ParameterAttribute
            $attributeCollectionSwitch = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollectionSwitch.Add($scriptAttributeSwitch)
            $scriptParamSwitch = New-Object System.Management.Automation.RuntimeDefinedParameter('UseNpm', [switch], $attributeCollectionSwitch)
            $paramDictionary.Add('UseNpm', $scriptParamSwitch)
        }
        return $paramDictionary
    }
}

Begin {
    # RECUPERATION DES SCRIPT EN FONCTION DES FICHIERS DE CONFIGURATION
    function getScripts () {
        $Package = '.\package.json'
        $Composer = '.\composer.json'
        if (Test-Path $Package) {
            return Get-Content $Package `
            | ConvertFrom-Json `
            | Select-Object -ExpandProperty scripts
        }
        elseif (Test-Path $Composer) {
            return Get-Content $Composer `
            | ConvertFrom-Json `
            | Select-Object -ExpandProperty scripts
        }
        return [PSCustomObject]@{}
    }
    # RECUPERATION DES NOM DE SCRIPTS
    function getScriptsName () {
        return getScripts `
        | Get-Member `
        | Where-Object { $_.MemberType -eq 'NoteProperty' } `
        | Select-Object -ExpandProperty Name
    }
    [bool]$Script:UseNpm = $PSBoundParameters['UseNpm'] -or $false
    [string]$Script:ScriptName = $PSBoundParameters['ScriptName']

    # RECUPERATION DES COMMANDE EN FONCTION DES FICHIERS DE CONFIGURATION
    function getRunner () {
        $Package = '.\package.json'
        $Composer = '.\composer.json'
        $npmLock = '.\package-lock.json'
        $yarnLock = '.\yarn.lock'
        if (Test-Path $Package) {
            if ((-not $Script:UseNpm) -and (Test-Path $npmLock) -and (Test-Path $yarnLock)) {
                if (`
                    (Get-Item $npmLock | Select-Object -ExpandProperty LastWriteTime) `
                        -lt (Get-Item $yarnLock | Select-Object -ExpandProperty LastWriteTime)`
                ) {
                    Write-Verbose 'runner : yarn'
                    $Runner = Get-Command yarn -ErrorAction SilentlyContinue
                    if ($Null -eq $Runner) {
                        Write-Verbose 'runner : npm'
                        $Runner = Get-Command npm -ErrorAction Stop
                    }
                }
                else {
                    Write-Verbose 'runner : npm'
                    $Runner = Get-Command npm -ErrorAction Stop
                }
                return $Runner
            }
            if ((-not $Script:UseNpm) -and (Test-Path $yarnLock)) {
                Write-Verbose 'runner : yarn'
                $Runner = Get-Command yarn -ErrorAction SilentlyContinue
                if ($Null -eq $Runner) {
                    Write-Verbose 'runner : npm'
                    $Runner = Get-Command npm -ErrorAction Stop
                }
                return $Runner
            }
            Write-Verbose 'runner : npm'
            return Get-Command npm -ErrorAction Stop
        }
        if (Test-Path $Composer) {
            Write-Verbose 'runner : composer'
            return Get-Command composer -ErrorAction Stop
        }
    }
}

Process {
    if ($List) {
        $Scripts = getScripts
        getScriptsName | ForEach-Object {
            Write-Host ($_ + " : ") -ForegroundColor Yellow -NoNewline
            Write-Host ($Scripts.$_) -Separator ' && '
        }
    }

    $Scripts = getScriptsName
    if ($ScriptName -in $Scripts) {
        $Runner = getRunner
        &$Runner run $ScriptName
    }
}
