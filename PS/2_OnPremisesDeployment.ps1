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
  The script log file stored in C:\Temp\1_OnPremisesDeployment.log
.NOTES
  Version:        1.0
  Author:         Marco Mannoni
  Creation Date:  06.03.2019
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
  #Script parameters go here
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#region Initializtion


# grab Time and start Transcript
Start-Transcript -Path "$PSScriptRoot\2_OnPremisesDeployment.log"
$StartDateTime = get-date


#set TLS 1.2 for github downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12



# Checking Folder Structure
"UpdateManagement\Agents","UpdateManagement\OMSGateway\" | ForEach-Object {
    if (!( Test-Path "$PSScriptRoot\$_" )) { New-Item -Type Directory -Path "$PSScriptRoot\$_" } }

#endregion

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = '1.0'


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

function  Get-WindowsBuildNumber { 
$os = Get-WmiObject -Class Win32_OperatingSystem 
return [int]($os.BuildNumber) 
} 

#endregion

#-----------------------------------------------------------[Execution]------------------------------------------------------------
#
#
WriteInfo "Script started at $StartDateTime"
#
#
# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit
}




#region Download Software

# Downloading Windows Agent
WriteInfoHighlighted "Windows Agent presence"
If ( Test-Path -Path "$PSScriptRoot\UpdateManagement\Agents\MMASetup-AMD64.exe" ) {
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
        $output = "$PSScriptRoot\UpdateManagement\Agents\MMASetup-AMD64.exe"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download Windows Agent!"
    }
    # Extracting Windows Agent
    
        $Command = "$PSScriptRoot\UpdateManagement\Agents\MMASetup-AMD64.exe"
        $Parameter = "/Q /T:$PSScriptRoot\UpdateManagement\Agents\Windows /C"
        $Prms = $Parameter.Split("")
        & "$Command" $Prms
        $waitextract = (Get-Process MMASetup-AMD64).Id
        Wait-Process -Id $waitextract
        Remove-Item -Path "$PSScriptRoot\UpdateManagement\Agents\MMASetup-AMD64.exe"
}

# Downloading OMS Gateway
WriteInfoHighlighted "OMS Gateway presence"
If ( Test-Path -Path "$PSScriptRoot\UpdateManagement\OMSGateway\OMS Gateway.msi" ) {
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
        $output = "$PSScriptRoot\UpdateManagement\OMSGateway\OMS Gateway.msi"
        Start-BitsTransfer -Source $ActualDownloadURL -Destination $output
    }catch{
        WriteError "`t Failed to download OMS Gateway!"
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
    WriteInfo "`t GPMC not present - Installing WSUS with default settings"
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
    Install-Module -Name Az -AllowClobber -force
WriteInfoHighlighted "Powershell Help Update"
    Update-Help -Force
#endregion