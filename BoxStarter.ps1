#Requires -Version 3
#Requires -RunAsAdministrator

<#
$url = "https://raw.githubusercontent.com/sbugalski/boxstarter-win10/initial/BoxStarter.ps1"
. { Invoke-WebRequest -useb $url } | Invoke-Expression
#>

function Set-BoxstarterPrepare {
  [CmdletBinding()]
  param (
    [Parameter()]
    [Switch]
    $logoutput
  )

  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

  if ($logoutput) {
    Start-Transcript -OutputDirectory $env:USERPROFILE\Desktop
    get-date
  }

  # Create Powershell Profile, so chocolatey can append profile file. Later chocolatey commands are used.
  if (! (Test-Path $profile)) {
    New-Item -Path $profile -Type File -Force | Out-Null
  }

  # Install BoxStarter
  . { Invoke-WebRequest -useb https://boxstarter.org/bootstrapper.ps1 } | Invoke-Expression; Get-Boxstarter -Force

  # Load Chocolatey scripts
  . $profile

  ### Set Boxstarter ###
  $Boxstarter.RebootOk = $true # Allow reboots?
  #$Boxstarter.NoPassword = $false # Is this a machine with no login password?
  #$Boxstarter.AutoLogin = $true # Save my password securely and auto-login after a reboot

  ### Set Chocolatey
  choco feature enable --name=allowGlobalConfirmation
}

### Functions
function Uninstall-Boxstarter {
  # Remove the Chocolatey packages in a specific order!
  'Boxstarter.Azure', 'Boxstarter.TestRunner', 'Boxstarter.WindowsUpdate', 'Boxstarter',
  'Boxstarter.HyperV', 'Boxstarter.Chocolatey', 'Boxstarter.Bootstrapper', 'Boxstarter.WinConfig', 'BoxStarter.Common' |
  ForEach-Object { choco uninstall $_ -y }

  # Remove the Boxstarter data folder
  Remove-Item -Path (Join-Path -Path $env:ProgramData -ChildPath 'Boxstarter') -Recurse -Force

  # Remove Boxstarter from the path in both the current session and the system
  $env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notlike '*Boxstarter*' }) -join ';'
  [Environment]::SetEnvironmentVariable('PATH', $env:PATH, 'Machine')

  # Remove Boxstarter from the PSModulePath in both the current session and the system
  $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object { $_ -notlike '*Boxstarter*' }) -join ';'
  [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath, 'Machine')
}

function Set-Cleanup {
  Write-Host "Cleaning desktop shortcuts"
  Get-ChildItem -Path $env:PUBLIC\Desktop\*.lnk | Remove-Item
  Get-ChildItem -Path $env:USERPROFILE\Desktop\*.lnk | Remove-Item
  Get-ChildItem -Path $env:USERPROFILE\Desktop\*.ini | Remove-Item
  choco feature disable --name=allowGlobalConfirmation

  Get-Date
  Stop-Transcript -ErrorAction "SilentlyContinue"
  Uninstall-Boxstarter
}

function Install-ChocoApps ($packageArray) {
  foreach ($package in $packageArray) {
    choco install $package --limitoutput --ignoredependencies
  }

  if (Test-Path $profile) {
    RefreshEnv
  }
  else {
    # refreshenv doesn't work properly for Powershell, unless you set Chocolatey Profile https://github.com/chocolatey/choco/blob/master/src/chocolatey.resources/redirects/RefreshEnv.cmd#L11
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  }
}

function Set-ChocoPin ($packageArray) {
  <#
	Pin chocolatey package so it won't be auto updated when using choco upgrade
	#>
  foreach ($package in $packageArray) {
    choco pin add --name $package
  }
}

function Install-VsCodeExtensions ($packageArray) {
  foreach ($package in $packageArray) {
    codium --install-extension $package
  }
}

### Variables
### Tools
$chocoTools = @(
  '7zip.install',
  'sysinternals',
  'winscp.install',
  'putty.install',
  'teracopy',
  'yubikey-manager',
  'bulk-crap-uninstaller',
  'calibre',
  'ccleaner.portable',
  'ccenhancer.portable',
  'chocolateygui',
  'paint.net',
  'powertoys',
  'rdmfree',
  'rufus',
  'vlc',
  #'volume2.install',
  'keepass.install',
  'sharex',
  'adobereader',
  'fzf'
)

### Browsers
$chocoBrowsers = @(
  'googlechrome',
  'opera',
  'microsoft-edge'
)

### Cloud
$chocoCloud = @(
  'azure-cli',
  'microsoftazurestorageexplorer',
  'terraform',
  'ARMClient',
  'awscli',
  'azcopy10',
  'kubernetes-cli',
  'kubernetes-helm',
  'packer'
)

### Dev
$chocoDev = @(
  'microsoft-windows-terminal',
  'docker-desktop',
  #'rsat',
  'nodejs.install',
  'powershell-core',
  'azure-data-studio',
  #'python2',
  'python3',
  'golang',
  'gitkraken',
  'jetbrainstoolbox',
  'postman',
  'cascadiafonts'
)

### Editors
$chocoEditors = @(
  'notepadplusplus.install',
  'vscodium'
  #'vscode'
)

### Work
$chocoWork = @(
  'microsoft-teams.install',
  'office365business',
  'google-drive-file-stream'
  #'google-backup-and-sync'
)

$chocoLogi = @(
  'logitechgaming',
  'logitech-options'
)

### Games
$chocoGames = @(
  'steam',
  'discord',
  'spotify',
  'goggalaxy',
  'origin'
)

$chocoPin = @(
  'adobereader',
  $chocoBrowsers,
  $chocoGames,
  $chocoWork
)

$vsCodeExt = @(
  #'2gua.rainbow-brackets',
  'CoenraadS.bracket-pair-colorizer-2',
  'eamodio.gitlens',
  'christian-kohler.path-intellisense'
)

#### Main ####
Set-BoxstarterPrepare -logoutput

### Personalization ###
Disable-BingSearch
Disable-GameBarTips

Set-TaskbarOptions -Size Small -Dock Left -UnLock -Combine Always
Set-CornerNavigationOptions -EnableUsePowerShellOnWinX
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

### Windows features
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

### Install Chocolatey packages
choco install git --package-parameters="'/GitOnlyOnPath /WindowsTerminal /SChannel /NoAutoCrlf'"
choco install visualstudio2019enterprise --package-parameters "--add Microsoft.VisualStudio.Component.Git"
choco install openvpn --params "'/SELECT_LAUNCH=0'"
#choco install miniconda3 --params="'/AddToPath:0 /InstallationType=AllUsers /RegisterPython=1 /D=C:\Program Files\miniconda3'"

Install-ChocoApps $chocoTools
Install-ChocoApps $chocoBrowsers
Install-ChocoApps $chocoCloud
Install-ChocoApps $chocoDev
Install-ChocoApps $chocoEditors
Install-ChocoApps $chocoWork
Install-ChocoApps $chocoGames
Install-ChocoApps $chocoLogi
Set-ChocoPin $chocoPin
Install-VsCodeExtensions $vsCodeExt

### Powershell
Install-PackageProvider -Name NuGet -Force
Update-Module -Force
Install-Module -Name Az -Scope CurrentUser -Force
Install-Module posh-git -Scope CurrentUser -Force
Install-Module oh-my-posh -Scope CurrentUser -Force
Install-Module -Scope CurrentUser PSFzf

### Python PIP
python -m pip install --upgrade pip
#conda update conda
#python2 -m pip install --upgrade pip

### Configuration
# for some reason refreshenv does not affect git.exe
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
git config --global core.symlinks true
git config --global core.autocrlf input
git config --global core.eol lf
git config --global color.status auto
git config --global color.diff auto
git config --global color.branch auto
git config --global color.interactive auto
git config --global color.ui true
git config --global color.pager true
git config --global color.showbranch auto

Install-ChocolateyPinnedTaskBarItem -TargetFilePath "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
Install-ChocolateyPinnedTaskBarItem -TargetFilePath "${env:ProgramFiles}\Opera\launcher.exe"
Install-ChocolateyPinnedTaskBarItem -TargetFilePath "${env:ProgramFiles}\Microsoft VS Code\Code.exe"
Install-ChocolateyPinnedTaskBarItem -TargetFilePath "${$env:windir}\explorer.exe"

### Finish ###
Enable-UAC
Set-Cleanup
Install-WindowsUpdate -GetUpdatesFromMS -AcceptEula -SuppressReboots
