# boxstarter-win10

## Usage
Running boxstarter is simple as running bellow command
```powershell
$url = "https://raw.githubusercontent.com/sbugalski/boxstarter-win10/initial/BoxStarter.ps1"
. { Invoke-WebRequest -useb $url } | Invoke-Expression
```
