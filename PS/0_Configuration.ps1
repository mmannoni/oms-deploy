<#
.SYNOPSIS
  Azure Update Management Cloud Deployment
.DESCRIPTION
  Parameters File
              
.NOTES
  Version:        1.0
  Author:         Marco Mannoni
  Creation Date:  08.03.2019
  Purpose/Change: Initial script development

.CHANGES

#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

$Configuration = @{
    OMSResourceGroupName = '';												# Name of the resource group on which OMS will deploy
    OMSWorkspaceName = '';                                                  # Name of the OMS workspace
    OMSWorkspaceLocation = '';                                              # Location, usually westeurope
    TenantSubscriptionID = '';												# Subscription ID from the Azure portal
    AutomationAccountname = '';                                             # Name of the automation account
    OMSWorkspaceSKU = 'pernode';                                            # do not change


}
