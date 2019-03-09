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

$Configuration = @{
    OMSResourceGroupName = '';												# Name of the resource group on which OMS will deploy
    OMSWorkspaceName = '';                                                  # Name of the OMS workspace
    OMSWorkspaceLocation = '';                                              # Location, usually westeurope
    TenantSubscriptionID = '';												# Subscription ID from the Azure portal
    AutomationAccountname = '';                                             # Name of the automation account
	InstallRoot = 'C:\Sys\UpdateManagement';                                # Root folder for installation - do not change
	OMSWorkspaceSKU = 'pernode';                                            # do not change
	OMSWorkspaceID = '#omsworkspaceid';                                     # do not change
	OMSWorkspaceKey ='#OMSWorkspacekey';                                    # do not change

}
