<# 
.SYNOPSIS 
    New-EnableAutoShutDownForVMs Module helps enabling Autoshutdown for ARM (Non-DevTestLab) VMs easily.
    
.DESCRIPTION 
    New-EnableAutoShutDownForVMs Module helps enabling Autoshutdown for ARM (Non-DevTestLab) VMs easily.
    # To Generate teh Client ID and Client Key Refer article "How to authenticate Azure Rest API with Azure Service Principal by Powershell" - https://gallery.technet.microsoft.com/scriptcenter/How-to-authenticate-Azure-4bb18b78 
    # Import ADAL library to acquire access token 
    # $PSScriptRoot only work PowerShell V3 or above versions 
    # The script is tested with Version 3.13.31202.1333 - Microsoft.IdentityModel.Clients.ActiveDirectory.dll and Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll
    # Time Zone may be changed to any timezone of your choice.
    
.EXAMPLE 
    
    New-EnableAutoShutdownForVMs 
        -subId = Your Subscription ID
        -rgroup = Resource Group Name 
        -vmname = Virutal Machine Name 
        -location = Virtual Machine location
        -ShutdownTime = 1400         
        
    Save New-EnableAutoShutdownForVMs.PSM1 in your desired folder, say C:\AutoshutVM\
    
    Open a powershell editor and copy paste the below text to use this module. The below script imports this module and enables Autoshutdown for a selected resource group.
    The below script can be customized further to enable autoshutdown for all VMs in a subscription just be removing the if statement inside For loop below.
    
    
    Import-Module "C:\AutoshutVM\New-EnableAutoShutdownForVMs.psm1"
    Login-AzureRmAccount
    $Tenant= Select-AzureRmSubscription -SubscriptionId <SubID>
    $subId = $Tenant.Subscription.SubscriptionId
    $VMlists = Get-AzureRmVM

    Foreach ($vmobj in $VMlists)
    {
        if ($vmobj.ResourceGroupName -match "<Your RG Name>")
            {
                $Output = New-EnableAutoShutdownForVMs -ClientId $ClientID -ClientKey $ClientKey -TenantId $TenantID -subId $subId -rgroup $vmobj.ResourceGroupName -vmname $vmobj.Name -location $vmobj.Location -shutdownTime "1710"
                Write-Host $Output -ForegroundColor Green
            }
    }
#> 


Function New-EnableAutoShutdownForVMs
{ 
    [CmdletBinding()] 
    Param 
    ( 
        
        [Parameter(Mandatory=$true)][String]$subId,
        [Parameter(Mandatory=$true)][String]$rgroup,
        [Parameter(Mandatory=$true)][String]$vmname,
        [Parameter(Mandatory=$true)][String]$location,
        [Parameter(Mandatory=$true)][String]$shutdownTime
       
    ) 
 
$adTenant = "microsoft.onmicrosoft.com" 
# Set well-known client ID for Azure PowerShell
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$resourceAppIdURI = "https://management.core.windows.net/"
$authority = "https://login.windows.net/$adTenant"
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
$authHeader = $authResult.CreateAuthorizationHeader()
$headerDate = '2017-03-30'
$method = "PUT"    
$headers = @{"x-ms-version"="$headerDate";"Authorization" = $authHeader}     
    
  
    # Forming the URI to be invoked later 
    $uri =  "https://management.azure.com/subscriptions/$subId/resourcegroups/$rgroup/providers/Microsoft.DevTestLab/schedules/shutdown-computevm-" + $vmName + "?api-version=2017-04-26-preview"
    
    # Request Body
    $params =  @"
           {
            "location": "$location",
            "properties": {
                "status": "Enabled",
                "timeZoneId": "India Standard Time",
                "taskType": "ComputeVmShutdownTask",
                "notificationSettings": {
                    "status": "Disabled",
                    "timeInMinutes": 15,
                    "webhookUrl": null
                },
                "targetResourceId": "/subscriptions/$subId/resourceGroups/$rgroup/providers/Microsoft.Compute/virtualMachines/$vmname",
                "dailyRecurrence": {"time": "$shutdownTime"}
            }
           }
"@

    $Result = Invoke-RestMethod -Method PUT -Headers $Headers -Uri $Uri -Body $params -ContentType 'application/json'
    return "AutoShutdown at $shutdownTime hrs IST successfully set for VM - $vmname "
   
} 
 
Export-ModuleMember -Function "New-EnableAutoShutdownForVMs"

