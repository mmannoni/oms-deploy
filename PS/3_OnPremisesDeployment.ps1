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

#region installation of OMS components on Premises

#Installing MMA
WriteInfo "`t Installing Microsoft Monitoring Agent"
Start-Process msiexec.exe -Wait -ArgumentList "/i $PSScriptRoot\Agents\Windows\MMA\momagent.msi AcceptEndUserLicenseAgreement=1 /quiet"
WriteSuccess "`t Microsoft Monitoring Agent successfully installed"

#Setup Azure Config in MMA
WriteInfo "`t Configuring Microsoft Monitoring Agent"
$healthServiceSettings = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$proxyMethod = $healthServiceSettings | Get-Member -Name 'SetProxyInfo'
if (!$proxyMethod)
{
     Write-Output 'Health Service proxy API not present, will not update settings.'
     return
}

$healthServiceSettings.SetProxyInfo('', '', '')
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$mma.AddCloudWorkspace($Configuration.omsworkspaceId, $Configuration.omsworkspaceKey)
$mma.ReloadConfiguration()
WriteSuccess "`t Microsoft Monitoring Agent successfully configured"

#Installing Dependency Agent
WriteInfo "`t Installing Microsoft Dependency Agent"
Start-Process "$PSScriptRoot\Agents\Windows\InstallDependencyAgent-Windows.exe" -Wait -ArgumentList '/S'
WriteSuccess "`t Microsoft Dependency Agent successfully installed"

#Installing OMS Gateway
WriteInfo "`t Installing Microsoft OMS Gateway"
Start-Process msiexec.exe -Wait -ArgumentList "/i $PSScriptRoot\OMSGateway\OMSGateway.msi /passive"
WriteSuccess "`t Microsoft OMS Gateway successfully installed"

#Setting parameters in OMS Gateway
WriteInfo "`t Configuring OMS Gateway"
Start-Sleep -Seconds 5
Import-Module "C:\Program Files\OMS Gateway\PowerShell\OmsGateway\OmsGateway.psd1"
Import-Module "C:\Program Files\OMS Gateway\PowerShell\OmsGateway\OmsGateway.psm1"
Add-OMSGatewayAllowedHost -host azurewatsonanalysis-prod.core.windows.net -Force
Add-OMSGatewayAllowedHost -host 1ca08785-c731-4c01-a004-1f7bd57a99a8.agentsvc.azure-automation.net -Force
Add-OMSGatewayAllowedHost -host winatp-gw-cus.microsoft.com -Force
Add-OMSGatewayAllowedHost -host winatp-gw-neu.microsoft.com -Force
Add-OMSGatewayAllowedHost -host we-jobruntimedata-prod-su1.azure-automation.net -Force
Add-OMSGatewayAllowedHost -host we-agentservice-prod-1.azure-automation.net -Force
Add-OMSGatewayAllowedHost -host winatp-gw-weu.microsoft.com -Force
Add-OMSGatewayAllowedHost -host winatp-gw-uks.microsoft.com -Force
Set-OMSGatewayConfig -Name listenport -value 8282 -Force
Restart-Service OMSGatewayService
Get-OMSGatewayAllowedHost
WriteSuccess "`t Microsoft OMS Gateway successfully configured"
