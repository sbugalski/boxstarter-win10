# boxstarter-win10

## Usage

Running boxstarter is simple as running bellow command in PowerShell as administrator.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
$url = "https://raw.githubusercontent.com/sbugalski/boxstarter-win10/master/BoxStarter.ps1"
. { Invoke-WebRequest -useb $url } | Invoke-Expression
```
