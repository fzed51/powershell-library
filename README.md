# Powershell library

## Installation

```powershell
New-Item -Type Directory -Force (Join-Path (Split-Path $PROFILE) "Scripts") | Out-Null
wget "https://raw.githubusercontent.com/fzed51/powershell-library/main/library/Install-PoShScript.ps1" -OutFile (Join-Path (Join-Path (Split-Path $PROFILE) "Scripts") "Install-PoShScript.ps1")
```