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

$InitialInstallRoot = 'C:\Sys\'

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#region Initializtion


# grab Time and start Transcript
Start-Transcript -Path "$InitialInstallRoot\1_Prereq.log"
$StartDateTime = get-date
WriteInfo "Script started at $StartDateTime"


#set TLS 1.2 for github downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# Checking Folder Structure
WriteInfoHighlighted "Checking folder structure"
"UpdateManagement\Agents\Windows","UpdateManagement\Agents\Linux","UpdateManagement\OMSGateway\","UpdateManagement\Temp\","UpdateManagement\AD\ADMX","UpdateManagement\AD\GPOs","UpdateManagement\WMF"    | ForEach-Object {
    if (!( Test-Path "$InitialInstallRoot\$_" )) { New-Item -Type Directory -Path "$InitialInstallRoot\$_" } }

#endregion


#-----------------------------------------------------------[Execution]------------------------------------------------------------


#region Download Software & Scripts

# Downloading Windows Agent
WriteInfoHighlighted "Windows Agent presence"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe" ) {
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
        $output = "$InitialInstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download Windows Agent!"
    }
    # Extracting Windows Agent
    
        $Command = "$InitialInstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe"
        $Parameter = "/Q /T:$InitialInstallRoot\UpdateManagement\Agents\Windows\MMA /C"
        $Prms = $Parameter.Split("")
        & "$Command" $Prms
        $waitextract = (Get-Process MMASetup-AMD64).Id
        Wait-Process -Id $waitextract
        Remove-Item -Path "$InitialInstallRoot\UpdateManagement\Agents\Windows\MMASetup-AMD64.exe"
}

# Downloading OMS Gateway
WriteInfoHighlighted "OMS Gateway presence"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\OMSGateway\OMSGateway.msi" ) {
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
        $output = "$InitialInstallRoot\UpdateManagement\OMSGateway\OMSGateway.msi"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download OMS Gateway!"
    }
}

# Downloading WMF 5.1
WriteInfoHighlighted "WMF 5.1 for W2K12"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\WMF\W2K12-KB3191565-x64.msu" ) {
    WriteSuccess "`t WMF 5.1 for W2K12 is present, skipping download"
}else{ 
    WriteInfo "`t WMF 5.1 for W2K12 not present - Downloading WMF 5.1 for W2K12"
    try {
        $url = 'https://www.microsoft.com/en-us/download/details.aspx?id=54616'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InitialInstallRoot\UpdateManagement\WMF\W2K12-KB3191565-x64.msu"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download WMF 5.1 for W2K12!"
    }
}

WriteInfoHighlighted "WMF 5.1 for W7 & W2K8R2"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\WMF\Win7AndW2K8R2-KB3191566-x64.zip" ) {
    WriteSuccess "`t WMF 5.1 for W7 & W2K8R2 is present, skipping download"
}else{ 
    WriteInfo "`t WMF 5.1 for W7 & W2K8R2 not present - Downloading WMF 5.1 for W7 & W2K8R2"
    try {
        $url = 'https://www.microsoft.com/en-us/download/details.aspx?id=54616'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InitialInstallRoot\UpdateManagement\WMF\Win7AndW2K8R2-KB3191566-x64.zip"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download WMF 5.1 for W7 & W2K8R2!"
    }
}

WriteInfoHighlighted "WMF 5.1 for W7x86"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\WMF\Win7-KB3191566-x86.zip" ) {
    WriteSuccess "`t WMF 5.1 for W7x86 is present, skipping download"
}else{ 
    WriteInfo "`t WMF 5.1 for W7x86 not present - Downloading WMF 5.1 for W7x86"
    try {
        $url = 'https://www.microsoft.com/en-us/download/details.aspx?id=54616'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InitialInstallRoot\UpdateManagement\WMF\Win7-KB3191566-x86.zip"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download WMF 5.1 for W7x86!"
    }
}

WriteInfoHighlighted "WMF 5.1 for W8.1 & W2K12R2"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\WMF\Win8.1AndW2K12R2-KB3191564-x64.msu" ) {
    WriteSuccess "`t WMF 5.1 for W8.1 & W2K12R2 is present, skipping download"
}else{ 
    WriteInfo "`t WMF 5.1 for W8.1 & W2K12R2 not present - Downloading WMF 5.1 for W8.1 & W2K12R2"
    try {
        $url = 'https://www.microsoft.com/en-us/download/details.aspx?id=54616'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InitialInstallRoot\UpdateManagement\WMF\Win8.1AndW2K12R2-KB3191564-x64.msu"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download WMF 5.1 for W8.1 & W2K12R2!"
    }
}

WriteInfoHighlighted "WMF 5.1 for W8.1x86"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\WMF\Win8.1-KB3191564-x86.msu" ) {
    WriteSuccess "`t WMF 5.1 for W8.1x86 is present, skipping download"
}else{ 
    WriteInfo "`t WMF 5.1 for W8.1x86 not present - Downloading WMF 5.1 for W8.1x86"
    try {
        $url = 'https://www.microsoft.com/en-us/download/details.aspx?id=54616'
        $WebRequest = [System.Net.WebRequest]::create($URL)
        $WebResponse = $WebRequest.GetResponse()
        $ActualDownloadURL = $WebResponse.ResponseUri.AbsoluteUri
        $ObjectProperties = @{ 'Shortened URL' = $URL;
                       'Actual URL' = $ActualDownloadURL}
        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        $WebResponse.Close()
        $ResultsObject.'Actual URL'
        $output = "$InitialInstallRoot\UpdateManagement\WMF\Win8.1-KB3191564-x86.msu"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download WMF 5.1 for W8.1x86!"
    }
}


# Downloading Dependency Agent Windows
WriteInfoHighlighted "Dependency Agent Windows presence"
If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\Agents\Windows\InstallDependencyAgent-Windows.exe" ) {
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
        $output = "$InitialInstallRoot\UpdateManagement\Agents\Windows\InstallDependencyAgent-Windows.exe"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download Dependency Agent Windows!"
    }
}

# Downloading Linux Guide
    WriteInfoHighlighted "Looking for Linux guide"
    If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\Agents\Linux\README.md" ) {
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
    If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\0_Configuration.ps1" ) {
        WriteSuccess "`t 0_Configuration.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 0_Configuration.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/0_Configuration.ps1 -OutFile "$InitialInstallRoot\UpdateManagement\0_Configuration.ps1"
        }catch{
            WriteError "`t Failed to download 0_Configuration.ps1!"
        }
    }

    WriteInfoHighlighted "Looking for 2_AzureDeployment.ps1 script"
    If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\2_AzureDeployment.ps1" ) {
        WriteSuccess "`t 2_AzureDeployment.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 2_AzureDeployment.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/2_AzureDeployment.ps1 -OutFile "$InitialInstallRoot\UpdateManagement\2_AzureDeployment.ps1"
        }catch{
            WriteError "`t Failed to download 3_AzureDeployment.ps1!"
        }
    }

    WriteInfoHighlighted "Looking for 3_OnPremisesDeployment.ps1 script"
    If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\3_OnPremisesDeployment.ps1" ) {
        WriteSuccess "`t 3_OnPremisesDeployment.ps1 is present, skipping download"
    }else{ 
        WriteInfo "`t Downloading 2_OnPremisesDeployment.ps1"
        try{
            Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/mmannoni/oms-deploy/master/PS/3_OnPremisesDeployment.ps1 -OutFile "$InitialInstallRoot\UpdateManagement\3_OnPremisesDeployment.ps1"
        }catch{
            WriteError "`t Failed to download 2_OnPremisesDeployment.ps1!"
        }
    }

# Download, unzip and install PSEXEC
WriteInfo "`t Downloading PSEXEC"
$psexecurl = "https://download.sysinternals.com/files/PSTools.zip"
$psexecout = "$InitialInstallRoot\UpdateManagement\Temp\PSTools.zip"
Start-BitsTransfer -Source $psexecurl -Destination $psexecout
WriteInfo "`t Extracting and installing PSEXEC"
Expand-Archive "$InitialInstallRoot\UpdateManagement\Temp\PSTools.zip" -DestinationPath "C:\Windows\System32"
Remove-Item -path "$InitialInstallRoot\UpdateManagement\Temp\PSTools.zip"
WriteSuccess "`t PSEXEC installed successfully"

# Download and install ADMX templates
$admxurl = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=57576"
$admxout = "$InitialInstallRoot\UpdateManagement\AD\ADMX\Administrative Templates (.admx) for Windows 10 October 2018 Update.msi"
    WriteInfoHighlighted "Looking for ADMX 10.2018 templates"
    If ( Test-Path -Path "$InitialInstallRoot\UpdateManagement\AD\ADMX\Administrative Templates (.admx) for Windows 10 October 2018 Update.msi" ) {
        WriteSuccess "`t ADMX templates present, skipping download"
    }else{ 
        WriteInfo "`t Downloading ADMX templates"
        try{
            Start-BitsTransfer -Source $admxurl -Destination $admxout
        }catch{
            WriteError "`t Failed to download ADMX templates!"
        }
    }
WriteInfo "`t Extracting ADMX templates"
Start-Process msiexec.exe -Wait -ArgumentList "/i $InitialInstallRoot\UpdateManagement\AD\ADMX\Administrative Templates (.admx) for Windows 10 October 2018 Update.msi /passive"
Copy-Item "C:\Program Files (x86)\Microsoft Group Policy\Windows 10 October 2018 Update (1809) v2\*" -Destination "$InitialInstallRoot\UpdateManagement\AD\ADMX\" -Recurse
Remove-Item "$InitialInstallRoot\UpdateManagement\AD\ADMX\Administrative Templates (.admx) for Windows 10 October 2018 Update.msi"
WriteSuccess "`t ADMX templates extracted sucessfully"

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
$mgmtDomain=(Get-WmiObject win32_computersystem).Domain
$mgmtFQDN=(Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
(Get-Content -Path $InitialInstallRoot\UpdateManagement\0_Configuration.ps1) | ForEach-Object {$_ -Replace '#mgmthost', $mgmtFQDN} | Set-Content -Path $InitialInstallRoot\UpdateManagement\0_Configuration.ps1
(Get-Content -Path $InitialInstallRoot\UpdateManagement\0_Configuration.ps1) | ForEach-Object {$_ -Replace '#mgmtdomain', $mgmtDomain} | Set-Content -Path $InitialInstallRoot\UpdateManagement\0_Configuration.ps1
WriteSuccess "`t Hostname and Domain successfully written to 0_Configuration.ps1"

#endregion

#region finishing prereq

#creating object os WScript
$wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
#invoking the POP method using object
$wshell.Popup("Please change to the Update Management Folder and edit 0_Configuration.ps1 before running 2_AzureDeployment.ps1",0,"Setup",64)

#endregion