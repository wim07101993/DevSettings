param ($onlyFunctions)

# ---------------------------------------------------------
# ---------------------------------------------------------
#  FUNCTIONS
# ---------------------------------------------------------
# ---------------------------------------------------------

function AppendPath([String] $toAdd) {
    $regexAddPath = [regex]::Escape($toAdd)
    $originalPath = [System.Environment]::GetEnvironmentVariable('path', [System.EnvironmentVariableTarget]::User)

    $split = $originalPath -split ';'

    $alreadyContainsSegment = $FALSE
    $split | ForEach-Object {
        $alreadyContainsSegment = $alreadyContainsSegment -or ($_ -match "^$regexAddPath\\?")
    }

    if ($alreadyContainsSegment) {
        return
    }

    [System.Environment]::SetEnvironmentVariable('path', ($split + $toAdd) -join ';', [System.EnvironmentVariableTarget]::User)
}

function SetEnvironmentVariables {
    Write-Output "setting environment variables:"
    Write-Output " - source => $env:USERPROFILE\source"
    [System.Environment]::SetEnvironmentVariable('source', $env:USERPROFILE + "\source", [System.EnvironmentVariableTarget]::User)
    Write-Output " - repos => $env:USERPROFILE\source\repos"
    [System.Environment]::SetEnvironmentVariable('repos', $env:USERPROFILE + "\source\repos", [System.EnvironmentVariableTarget]::User)
    Write-Output " - mypath => $env:USERPROFILE\bin"
    [System.Environment]::SetEnvironmentVariable('mypath', $env:USERPROFILE + "\bin", [System.EnvironmentVariableTarget]::User)
    Write-Output " - choco tool path"
    [System.Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', "C:\tools", [System.EnvironmentVariableTarget]::User)
    
    Write-Output "appending $env:mypath to PATH"
    AppendPath $env:mypath
}

function InstallOhMyPosh {
    Write-Output "installing oh-my-posh"
    # install modules
    Install-Module posh-git -Scope CurrentUser
    Install-Module oh-my-posh -Scope CurrentUser
}

function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function IsChocolateyInstalled {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    $exists = $false
    try { 
        if (Get-Command 'choco') {
            $exists = $true 
        } 
    }
    catch { 
        $exists = $false 
    }
    finally { 
        $ErrorActionPreference = $oldPreference 
    }
    return $exists
}

function InstallFlutter {
    if (-not $env:ChocolateyToolsLocation) {
        SetEnvironmentVariables
    }

    $flutterDirectory = $env:ChocolateyToolsLocation + "\flutter"
    if (-not (Test-Path -Path ($flutterDirectory + "\bin\dart"))) {
        Write-Output "cloning flutter sdk"
        git clone https://github.com/flutter/flutter.git $flutterDirectory -b stable
    }
    Write-Output "appending flutter to path"

    AppendPath ($flutterDirectory + "\bin")
}

function InstallChocoPackages {
    if (IsChocolateyInstalled) {
        Write-Output "chocolatey already installed"
    }
    else {
        Write-Output "installing chocolatey"
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    
    # ide's / editors
    Write-Output "installing vscode, android studio, vim and notepad++"
    choco install vscode androidstudio vim notepadplusplus linqpad -y

    # sdk's
    Write-Output "installing netcore and golang flutter"
    choco install dotnetcore-sdk golang flutter -y

    # other dev stuff
    Write-Output "installing ms-terminal, git and sourcetree" # docker
    choco install microsoft-windows-terminal git sourcetree -y # docker-cli docker-desktop -y

    # social
    Write-Output "installing whatsapp and slack"
    choco install whatsapp slack -y

    # media
    Write-Output "installing vlc, spotify and gimp"
    choco install vlc spotify gimp -y

    # other
    Write-Output "installing powertoys"
    choco install powertoys putty googlechrome -y

    # fonts
    Write-Output "installing fira-code"
    choco install firacode -y

    # flutter
    InstallFlutter
}

function EnableWSL {
    Write-Output "enabling wsl"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
}

function SetMicrosoftTerminalSettings {
    Write-Output "setting ms-terminal settings"

    if (-not (Test-Path -Path $env:repos\DevSettings\WindowsTerminal\settings.json)) {
        git clone https://github.com/wim07101993/DevSettings
    }
    Copy-Item $env:repos\DevSettings\WindowsTerminal\settings.json $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
}

function SetPowerShellProfile {
    Write-Output "setting PowerShell profile"
    # Start the default settings
    Set-Prompt
    # Alternatively set the desired theme:
    Set-Theme RobbyRussell
}



# ---------------------------------------------------------
# ---------------------------------------------------------
#  SCRIPT START
# ---------------------------------------------------------
# ---------------------------------------------------------

if ($onlyFunctions) {
    Write-Output "skipping actual execution of script"
    return
}

SetEnvironmentVariables
InstallOhMyPosh

if (Test-Administrator) {
    InstallChocoPackages
    InstallFlutter
    # EnableWSL
} 
else {
    try {
        &Start-Process -FilePath powershell.exe -verb RunAs -ArgumentList "-NoExit $PSScriptRoot\setup.ps1"
    }
    catch {}
}

SetMicrosoftTerminalSettings
SetPowerShellProfile