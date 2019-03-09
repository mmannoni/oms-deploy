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
Start-Process msiexec.exe -Wait -ArgumentList '/i "$PSScriptRoot\Agents\Windows\MMA\momagent.msi" /quiet'


#Setup Azure Config in MMA
WriteInfo "`t Configuring Microsoft Monitoring Agent"
$healthServiceSettings = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$proxyMethod = $healthServiceSettings | Get-Member -Name 'SetProxyInfo'
if (!$proxyMethod)
{
     Write-Output 'Health Service proxy API not present, will not update settings.'
     return
}

Write-Output "Clearing proxy settings."
$healthServiceSettings.SetProxyInfo('', '', '')
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$mma.AddCloudWorkspace($Configuration.omsworkspaceId, $Configuration.omsworkspaceKey)
$mma.ReloadConfiguration()

#Installing Dependency Agent
WriteInfo "`t Installing Microsoft Dependency Agent"
Start-Process "$PSScriptRoot\Agents\Windows\InstallDependencyAgent-Windows.exe" -Wait -ArgumentList '/S'

#Installing OMS Gateway
WriteInfo "`t Installing OMS Gateway"
Start-Process msiexec.exe -Wait -ArgumentList '/i "$PSScriptRoot\OMSGateway\OMS Gateway.msi" /passive'

#Setting parameters in OMS Gateway
WriteInfo "`t Configuring OMS Gateway"
Set-OMSGatewayConfig -Name listenport -value 8282 -Force
Add-OMSGatewayAllowedHost -host azurewatsonanalysis-prod.core.windows.net
Add-OMSGatewayAllowedHost -host 1ca08785-c731-4c01-a004-1f7bd57a99a8.agentsvc.azure-automation.net
Add-OMSGatewayAllowedHost -host winatp-gw-cus.microsoft.com
Add-OMSGatewayAllowedHost -host winatp-gw-neu.microsoft.com
Add-OMSGatewayAllowedHost -host we-jobruntimedata-prod-su1.azure-automation.net
Add-OMSGatewayAllowedHost -host we-agentservice-prod-1.azure-automation.net
Add-OMSGatewayAllowedHost -host winatp-gw-weu.microsoft.com
Add-OMSGatewayAllowedHost -host winatp-gw-uks.microsoft.com

Restart-Service OMSGatewayService

