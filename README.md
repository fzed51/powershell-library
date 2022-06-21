# Powershell library

## Historique

- Le 2022-06-21, sortie de la version 2 de la librairy, mise en place de la gestino des modules

## Installation

```powershell
New-Item -Type Directory -Force (Join-Path (Split-Path $PROFILE) "Scripts") | Out-Null
wget "https://fzed51.github.io/powershell-library/library/scripts/Install-PoShScript.ps1" -OutFile (Join-Path (Join-Path (Split-Path $PROFILE) "Scripts") "Install-PoShScript.ps1")
```

