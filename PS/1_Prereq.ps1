<#
.SYNOPSIS
  Azure Update Management on Premises Installation Prerequisites
.DESCRIPTION
  Azure Update Management on Premises Installation Prerequisites
.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS Log File
  The script log file stored in C:\Temp\OnPremises_Prereq.log
.NOTES
  Version:        1.0
  Author:         Marco Mannoni
  Creation Date:  06.03.2019
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
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
"UpdateManagement\Agents\Windows","UpdateManagement\Agents\Linux","UpdateManagement\OMSGateway\" | ForEach-Object {
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
If ( Test-Path -Path "$InstallRoot\UpdateManagement\OMSGateway\OMS Gateway.msi" ) {
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
        $output = "$InstallRoot\UpdateManagement\OMSGateway\OMS Gateway.msi"
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
<#
    WriteInfoHighlighted "Looking for 1_Prereq.ps1 script"
    If ( Test-Path -Path "$InstallRoot\UpdateManagement\Scripts\1_Prereq.ps1" ) {
        WriteSuccess "`t 1_Prereq.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 1_Prereq.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/1_Prereq.ps1 -OutFile "$InstallRoot\UpdateManagement\Scripts\1_Prereq.ps1"
        }catch{
            WriteError "`t Failed to download 1_Prereq.ps1!"
        }
    }
#>
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

#Management Tools
WriteInfoHighlighted "GPMC presence"
If ( Get-WindowsFeature GPMC | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t GPMC is present, skipping installation"
}else{ 
    WriteInfo "`t GPMC not present - Installing GPMC with default settings"
    Install-WindowsFeature -Name GPMC
    }
WriteInfoHighlighted "Failover Cluster Tools presence"
If ( Get-WindowsFeature RSAT-Clustering | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t Failover Cluster Tools are present, skipping installation"
    }else{ 
    WriteInfo "`t Failover Cluster Tools not present - Installing Failover Cluster Tools"
    Install-WindowsFeature -Name RSAT-Clustering-Mgmt, RSAT-Clustering-Powershell
    }
WriteInfoHighlighted "AD DS and AD LDS Tools presence"
    If ( Get-WindowsFeature RSAT-AD-Tools | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t AD DS and AD LDS Tools are present, skipping installation"
    }else{ 
    WriteInfo "`t AD DS and AD LDS Tools not present - Installing AD DS and AD LDS Tools"
    Install-WindowsFeature -Name RSAT-AD-Tools
    }
WriteInfoHighlighted "Hyper-V Tools presence"
    If ( Get-WindowsFeature RSAT-Hyper-V-Tools | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t Hyper-V Tools are present, skipping installation"
    }else{ 
    WriteInfo "`t Hyper-V Tools not present - Installing Hyper-V Tools"
    Install-WindowsFeature -Name RSAT-Hyper-V-Tools
    }
WriteInfoHighlighted "Azure Powershell Installation"
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Az -AllowClobber -force

#endregion


#region finishing prereq

#creating object os WScript
$wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
#invoking the POP method using object
$wshell.Popup("Please change to the Update Management Folder and edit 0_Configuration.ps1 before running 2_AzureDeployment.ps1",0,"Setup",64)

#endregion