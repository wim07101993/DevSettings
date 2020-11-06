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
    echo "setting environment variables:"
    echo " - source => $env:USERPROFILE\source"
    [System.Environment]::SetEnvironmentVariable('source', $env:USERPROFILE + "\source", [System.EnvironmentVariableTarget]::User)
    echo " - repos => $env:USERPROFILE\source\repos"
    [System.Environment]::SetEnvironmentVariable('repos', $env:USERPROFILE + "\source\repos", [System.EnvironmentVariableTarget]::User)
    echo " - mypath => $env:USERPROFILE\bin"
    [System.Environment]::SetEnvironmentVariable('mypath', $env:USERPROFILE + "\bin", [System.EnvironmentVariableTarget]::User)

    echo "appending $env:mypath to PATH"
    AppendPath $env:mypath
}

function InstallOh-My-Posh {
    echo "installing oh-my-posh"
    # install modules
    Install-Module posh-git -Scope CurrentUser
    Install-Module oh-my-posh -Scope CurrentUser

    echo "setting prompt and theme"
    # Start the default settings
    Set-Prompt
    # Alternatively set the desired theme:
    Set-Theme RobbyRussell
}

function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function IsChocolateyInstalled {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    $exists = $false
    try 
    { 
        if (Get-Command 'choco') 
        {
            $exists = $true 
        } 
    }
    catch 
    { 
        $exis = $false 
    }
    finally 
    { 
        $ErrorActionPreference = $oldPreference 
    }
    return $exists
}

function InstallFlutter {
    $flutterDirectory = $env:repos + "\flutter"
    if (-not (Test-Path -Path ($flutterDirectory + "\bin\dart")))
    {
        echo "cloning flutter sdk"
        git clone https://github.com/flutter/flutter.git $flutterDirectory -b stable
    }
    echo "appending flutter to path"

    AppendPath ($flutterDirectory + "\bin")
}

function InstallChocoPackages {
    if (IsChocolateyInstalled) 
    {
        echo "chocolatey already installed"
    }
    else
    {
        echo "installing chocolatey"
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    
    # ide's / editors
    echo "installing vscode, android studio and notepad++"
    choco install vscode androidstudio notepadplusplus -y

    # sdk's
    echo "installing netcore and golang"
    choco install dotnetcore-sdk golang -y

    # other dev stuff
    echo "installing ms-terminal, git and sourcetree" # docker
    choco install microsoft-windows-terminal git sourcetree -y # docker-cli docker-desktop -y

    # social
    echo "installing whatsapp and slack"
    choco install whatsapp slack -y

    # media
    echo "installing vlc, spotify and gimp"
    choco install vlc spotify gimp -y

    # other
    echo "installing powertoys"
    choco install powertoys putty -y

    # fonts
    echo "installing fira-code"
    choco install firacode

    # flutter
    InstallFlutter
}

function SetMicrosoftTerminalSettings {
    echo "setting ms-terminal settings"

    if (-not (Test-Path -Path $env:repos\DevSettings\WindowsTerminal\settings.json)) 
    {
        git clone https://github.com/wim07101993/DevSettings
    }
    cp $env:repos\DevSettings\WindowsTerminal\settings.json $env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
}

function EnableWSL {
    echo "enabling wsl"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
}




# ---------------------------------------------------------
# ---------------------------------------------------------
#  SCRIPT START
# ---------------------------------------------------------
# ---------------------------------------------------------

if ($onlyFunctions)
{
    echo "skipping actual execution of script"
    return
}

SetEnvironmentVariables
InstallOh-My-Posh

if (Test-Administrator)
{
    InstallChocoPackages
    InstallFlutter
    # EnableWSL
} 
else 
{
    try
    {
        &Start-Process -FilePath powershell.exe -verb RunAs -ArgumentList "-NoExit $PSScriptRoot\setup.ps1"
    }
    catch{}
}

SetMicrosoftTerminalSettings

