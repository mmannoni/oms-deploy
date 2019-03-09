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
#region parameters

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit
}

#endregion

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#region Initialisations

# grab Time and start Transcript
Start-Transcript -Path "$PSScriptRoot\3_OnPremisesDeployment.log"
$StartDateTime = get-date
WriteInfo "Script started at $StartDateTime"

#Load Configfile....
WriteInfo "`t Loading configuration file"
."$PSScriptRoot\0_Configuration.ps1"

#endregion


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#region Execution


#Installing Windows Features and WSUS
WriteInfoHighlighted "WSUS presence"
If ( Get-WindowsFeature UpdateServices | Where-Object InstallState -EQ "Installed" ) {
    WriteSuccess "`t WSUS is present, skipping installation"
}else{ 
    WriteInfo "`t WSUS not present - Installing WSUS with default settings"
    Install-WindowsFeature -Name UpdateServices, UpdateServices-WidDB, UpdateServices-Services, UpdateServices-RSAT, UpdateServices-API, UpdateServices-UI
    }

#Installing Management Tools
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

WriteInfoHighlighted "WSUS and Management tools installed successfully"

#endregion