<#
.SYNOPSIS
	Azure Update Management Cloud Deployment

.DESCRIPTION
	Azure Update Management
	Installation of: Log Analytics Workspace, Automation Account

.INPUTS
	0_Configuration.ps1

.OUTPUTS Log File
	The script log file stored in C:\Temp\2_AzureDeployment.log

.NOTES
	Version:        1.2
	Author:         Marco Mannoni
	Creation Date:  06.03.2019
	Purpose/Change: Initial script development

.CHANGES
08.03.2019	Script changes
09.03.2019	Script changes
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

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#region Initializtion

# grab Time and start Transcript
Start-Transcript -Path "$PSScriptRoot\2_AzureDeployment.log"
$StartDateTime = get-date
WriteInfo "Script started at $StartDateTime"

#Load Configfile....
WriteInfo "`t Loading configuration file"
."$PSScriptRoot\0_Configuration.ps1"

#set TLS 1.2 for github downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#endregion


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#region Azure Logon

#Logon to the Azure Subscription and set the right context
WriteInfo "`t Logon to the Azure Subscription and set the right context"
Connect-AzAccount
$azcontext = Get-AzSubscription -SubscriptionId $configuration.TenantSubscriptionID
Set-AzContext $azcontext

#endregion


#region Deployment

#Check if the RG is there, otherwise create it. 
Get-AzResourceGroup -Name $configuration.OMSResourceGroupName -ErrorVariable notpresent -ErrorAction SilentlyContinue
if ($notPresent)
{
  WriteInfo "`t Resource group not present - creating resource group"
  New-AzResourceGroup -Name $configuration.OMSResourceGroupName -Location $configuration.OMSWorkspaceLocation
}
else
{
  WriteSuccess "`t Resource group is present, skipping creation"
}

#Create the OMS Workspace
WriteInfo "`t Creating OMS/Log Analytics Workspace"
$OMSWorkspace = New-AzOperationalInsightsWorkspace `
                -ResourceGroupName $configuration.OMSResourceGroupName `
                -Name $configuration.OMSWorkspaceName `
                -Location $configuration.OMSWorkspaceLocation `
                -SKU $configuration.OMSWorkspaceSKU `

WriteInfo "`t Workspace created, getting workspace ID and Keys"
$OMSWorkspaceID = $OMSWorkspace.CustomerId
$OMSWorkspaceKey = Get-AzOperationalInsightsWorkspaceSharedKeys `
                -ResourceGroupName $OMSWorkspace.ResourceGroupName `
                -Name $OMSWorkspace.Name

WriteInfo "`t Writing ID and key in 0_Configuration.ps1"
$path = $configuration.InstallRoot
(Get-Content -Path $path\0_Configuration.ps1) | ForEach-Object {$_ -Replace '#omsworkspaceid', $OMSWorkspaceID} | Set-Content -Path $path\0_Configuration.ps1
(Get-Content -Path $path\0_Configuration.ps1) | ForEach-Object {$_ -Replace '#OMSWorkspacekey', $omsworkspacekey.PrimarySharedKey} | Set-Content -Path $path\0_Configuration.ps1

#Create the Automation acccount
WriteInfo "`t Creating Automation Account"
New-AzAutomationAccount -ResourceGroupName $configuration.OMSResourceGroupName -Name $configuration.AutomationAccountname -Location $configuration.OMSWorkspaceLocation

WriteInfoHighlighted "`t Azure setup completed successfully"

#endregion