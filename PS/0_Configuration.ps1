<#
.SYNOPSIS
  Azure Update Management Cloud Deployment
.DESCRIPTION
  Parameters File
              
.NOTES
  Version:        1.1
  Author:         Marco Mannoni
  Creation Date:  08.03.2019
  Purpose/Change: Initial script development

.CHANGES
09.03.2019	Script changes

#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

# Don't change values marked with "do not change"!

<#
OMSResourceGroupName		Name of the resource group on which OMS will deploy
OMSWorkspaceName			Name of the OMS workspace
OMSWorkspaceLocation		Location, usually westeurope
TenantSubscriptionID		Subscription ID from the Azure portal
AutomationAccountname		Name of the automation account
InstallRoot					Root folder for installation - do not change
OMSWorkspaceSKU				SKU of the workspace - do not change
OMSWorkspaceID				OMS workspace id, will be filled automatically - do not change
OMSWorkspaceKey				OMS workspace key, will be filled automatically - do not change
MGMTHost					MGMT Host FQDN, will be filled automatically - do not change



#>

$Configuration = @{
	OMSResourceGroupName = '';
	OMSWorkspaceName = '';
	OMSWorkspaceLocation = '';
	TenantSubscriptionID = '';
	AutomationAccountname = '';
	InstallRoot = 'C:\Sys\UpdateManagement';
	OMSWorkspaceSKU = 'pernode';
	OMSWorkspaceID = '#omsworkspaceid';
	OMSWorkspaceKey ='#OMSWorkspacekey';
	MGMTHost = "#mgmthost";
	MGMTDomain = "#mgmtdomain";

}
