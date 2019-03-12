<#
.SYNOPSIS
  Azure Update Management on Premises Installation Prerequisites

.DESCRIPTION
  Azure Update Management on Premises Installation Prerequisites

.INPUTS
	0_Configuration.ps1

.OUTPUTS Log File
  The script log file stored in C:\Temp\OnPremises_Prereq.log

.NOTES
  Version:        1.0
  Author:         Marco Mannoni
  Creation Date:  06.03.2019
  Purpose/Change: Initial script development

.CHANGES
08.03.2019	Script changes
09.03.2019	Script changes
12.03.2019	Script changes
#>

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#region Functions

function WriteInfo($message){
    Write-Host $message
}

function WriteInfoHighlighted($message){
Write-Host $message -ForegroundColor Cyan
}

function WriteSuccess($message){
Write-Host $message -ForegroundColor Green
}

function WriteError($message){
Write-Host $message -ForegroundColor Red
}

function WriteErrorAndExit($message){
Write-Host $message -ForegroundColor Red
Write-Host "Press enter to continue ..."
Stop-Transcript
Read-Host | Out-Null
Exit
}

#endregion


#---------------------------------------------------------[Script Parameters]------------------------------------------------------
# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit
}

$InstallRoot = 'C:\Sys\'

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#region Initializtion


# grab Time and start Transcript
Start-Transcript -Path "$InstallRoot\1_Prereq.log"
$StartDateTime = get-date
WriteInfo "Script started at $StartDateTime"


#set TLS 1.2 for github downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# Checking Folder Structure
WriteInfoHighlighted "Checking folder structure"
"UpdateManagement\Agents\Windows","UpdateManagement\Agents\Linux","UpdateManagement\OMSGateway\","UpdateManagement\Temp\"  | ForEach-Object {
    if (!( Test-Path "$InstallRoot\$_" )) { New-Item -Type Directory -Path "$InstallRoot\$_" } }

#endregion


#-----------------------------------------------------------[Execution]------------------------------------------------------------


#region Download Software & Scripts

# Downloading Windows Agent
WriteInfoHighlighted "Windows Agent presence"
If ( Test-Path -Path "$InstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe" ) {
    WriteSuccess "`t Windows Agent is present, skipping download"
}else{ 
    WriteInfo "`t Windows Agent not present - Downloading Windows Agent"
    try {
        $url = 'https://go.microsoft.com/fwlink/?LinkId=828603'    
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download Windows Agent!"
    }
    # Extracting Windows Agent
    
        $Command = "$InstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe"
        $Parameter = "/Q /T:$InstallRoot\UpdateManagement\Agents\Windows\MMA /C"
        $Prms = $Parameter.Split("")
        & "$Command" $Prms
        $waitextract = (Get-Process MMASetup-AMD64).Id
        Wait-Process -Id $waitextract
        Remove-Item -Path "$InstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe"
}

# Downloading OMS Gateway
WriteInfoHighlighted "OMS Gateway presence"
If ( Test-Path -Path "$InstallRoot\UpdateManagement\OMSGateway\OMSGateway.msi" ) {
    WriteSuccess "`t OMS Gateway is present, skipping download"
}else{ 
    WriteInfo "`t OMS Gateway not present - Downloading OMS Gateway"
    try {
        $url = 'https://go.microsoft.com/fwlink/?linkid=837444'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InstallRoot\UpdateManagement\OMSGateway\OMSGateway.msi"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download OMS Gateway!"
    }
}

# Downloading Dependency Agent Windows
WriteInfoHighlighted "Dependency Agent Windows presence"
If ( Test-Path -Path "$InstallRoot\UpdateManagement\Agents\Windows\InstallDependencyAgent-Windows.exe" ) {
    WriteSuccess "`t Dependency Agent Windows is present, skipping download"
}else{ 
    WriteInfo "`t Dependency Agent Windows not present - Downloading Dependency Agent"
    try {
        $url = 'https://aka.ms/dependencyagentwindows'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InstallRoot\UpdateManagement\Agents\Windows\InstallDependencyAgent-Windows.exe"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download Dependency Agent Windows!"
    }
}

# Downloading Linux Guide
    WriteInfoHighlighted "Looking for Linux guide"
    If ( Test-Path -Path "$InstallRoot\UpdateManagement\Agents\Linux\README.md" ) {
        WriteSuccess "`t Linux guide is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading Linux guide"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/README.md -OutFile "$InstallRoot\UpdateManagement\Agents\Linux\README.txt"
        }catch{
            WriteError "`t Failed to Linux guide!"
        }
    }

# Download install scripts
    WriteInfoHighlighted "Looking for 0_Configuration.ps1 script"
    If ( Test-Path -Path "$InstallRoot\UpdateManagement\0_Configuration.ps1" ) {
        WriteSuccess "`t 0_Configuration.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 0_Configuration.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/0_Configuration.ps1 -OutFile "$InstallRoot\UpdateManagement\0_Configuration.ps1"
        }catch{
            WriteError "`t Failed to download 0_Configuration.ps1!"
        }
    }

    WriteInfoHighlighted "Looking for 2_AzureDeployment.ps1 script"
    If ( Test-Path -Path "$InstallRoot\UpdateManagement\2_AzureDeployment.ps1" ) {
        WriteSuccess "`t 2_AzureDeployment.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 2_AzureDeployment.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/2_AzureDeployment.ps1 -OutFile "$InstallRoot\UpdateManagement\2_AzureDeployment.ps1"
        }catch{
            WriteError "`t Failed to download 3_AzureDeployment.ps1!"
        }
    }

    WriteInfoHighlighted "Looking for 3_OnPremisesDeployment.ps1 script"
    If ( Test-Path -Path "$InstallRoot\UpdateManagement\3_OnPremisesDeployment.ps1" ) {
        WriteSuccess "`t 3_OnPremisesDeployment.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 2_OnPremisesDeployment.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/3_OnPremisesDeployment.ps1 -OutFile "$InstallRoot\UpdateManagement\3_OnPremisesDeployment.ps1"
        }catch{
            WriteError "`t Failed to download 2_OnPremisesDeployment.ps1!"
        }
    }

# Download, unzip and install PSEXEC
WriteInfo "`t Downloading PSEXEC"
$psexecurl = "https://download.sysinternals.com/files/PSTools.zip"
$psexecout = "$InstallRoot\UpdateManagement\Temp\PSTools.zip"
Start-BitsTransfer -Source $psexecurl -Destination $psexecout
WriteInfo "`t Extracting and installing PSEXEC"
Expand-Archive "$InstallRoot\UpdateManagement\Temp\PSTools.zip" -DestinationPath "C:\Windows\System32"
Remove-Item -path "$InstallRoot\UpdateManagement\Temp\PSTools.zip"
WriteSuccess "`t PSEXEC installed successfully"

#endregion

#region Install WSUS and Tools

# Installing Windows Features
# WSUS
WriteInfoHighlighted "WSUS presence"
If ( Get-WindowsFeature UpdateServices | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t WSUS is present, skipping installation"
}else{ 
    WriteInfo "`t WSUS not present - Installing WSUS with default settings"
    Install-WindowsFeature -Name UpdateServices, UpdateServices-WidDB, UpdateServices-Services, UpdateServices-RSAT, UpdateServices-API, UpdateServices-UI
    }
    WriteSuccess "`t WSUS installed successfully"

#Management Tools
WriteInfoHighlighted "GPMC presence"
If ( Get-WindowsFeature GPMC | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t GPMC is present, skipping installation"
}else{ 
    WriteInfo "`t GPMC not present - Installing GPMC with default settings"
    Install-WindowsFeature -Name GPMC
    }
    WriteSuccess "`t GPMC installed successfully"

WriteInfoHighlighted "Failover Cluster Tools presence"
If ( Get-WindowsFeature RSAT-Clustering | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t Failover Cluster Tools are present, skipping installation"
    }else{ 
    WriteInfo "`t Failover Cluster Tools not present - Installing Failover Cluster Tools"
    Install-WindowsFeature -Name RSAT-Clustering-Mgmt, RSAT-Clustering-Powershell
    }
    WriteSuccess "`t Failover Cluster Tools installed successfully"

WriteInfoHighlighted "AD DS and AD LDS Tools presence"
    If ( Get-WindowsFeature RSAT-AD-Tools | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t AD DS and AD LDS Tools are present, skipping installation"
    }else{ 
    WriteInfo "`t AD DS and AD LDS Tools not present - Installing AD DS and AD LDS Tools"
    Install-WindowsFeature -Name RSAT-AD-Tools
    }
    WriteSuccess "`t AD DS and AD LDS Tools installed successfully"

WriteInfoHighlighted "Hyper-V Tools presence"
    If ( Get-WindowsFeature RSAT-Hyper-V-Tools | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t Hyper-V Tools are present, skipping installation"
    }else{ 
    WriteInfo "`t Hyper-V Tools not present - Installing Hyper-V Tools"
    Install-WindowsFeature -Name RSAT-Hyper-V-Tools
    }
	WriteSuccess "`t Hyper-V Tools installed successfully"

WriteInfoHighlighted "Azure Powershell Installation"
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Az -AllowClobber -force
	Install-Module –Name PowerShellGet –Force
	WriteSuccess "`t Azure Powershell installed successfully"

#endregion

#region fill data in configuration file

WriteInfo "`t Writing hostname and Domain in 0_Configuration.ps1"
$path = $configuration.InstallRoot
$mgmtDomain=(Get-WmiObject win32_computersystem).Domain
$mgmtFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
(Get-Content -Path $path\0_Configuration.ps1) | ForEach-Object {$_ -Replace '#mgmthost', $mgmtFQDN} | Set-Content -Path $path\0_Configuration.ps1
(Get-Content -Path $path\0_Configuration.ps1) | ForEach-Object {$_ -Replace '#mgmtdomain', $mgmtDomain} | Set-Content -Path $path\0_Configuration.ps1
WriteSuccess "`t Hostname and Domain successfully written to 0_Configuration.ps1"

#endregion

#region finishing prereq

#creating object os WScript
$wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
#invoking the POP method using object
$wshell.Popup("Please change to the Update Management Folder and edit 0_Configuration.ps1 before running 2_AzureDeployment.ps1",0,"Setup",64)

#endregion