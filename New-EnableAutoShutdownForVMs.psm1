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
    
    Import-Module "C:\Users\sauravb\Desktop\StorageEnum\New-EnableAutoShutdownForVMs.psm1"
    Login-AzureRmAccount
    $Tenant= Select-AzureRmSubscription -SubscriptionId <SubID>
    $subId = $Tenant.Subscription.SubscriptionId
    $ClientID = "72xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx49c2"
    $ClientKey =  "Password@123!"
    $TenantID= "72xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxb47"
    $VMlists = Get-AzureRmVM

    Foreach ($vmobj in $VMlists)
    {
        if ($vmobj.ResourceGroupName -match "<Your RG Name>")
            {
                $Output = New-EnableAutoShutdownForVMs -ClientId $ClientID -ClientKey $ClientKey -TenantId $TenantID -subId $subId -rgroup $vmobj.ResourceGroupName -vmname $vmobj.Name -location $vmobj.Location -shutdownTime "1710"
                Write-Host $Output -ForegroundColor Green
            }
    }
  
    New-EnableAutoShutdownForVMs 
        -subId = Your Subscription ID
        -rgroup = Resource Group Name 
        -vmname = Virutal Machine Name 
        -location = Virtual Machine location
        -ShutdownTime = 1400 HRS
        -ClientId = Your Client ID 
        -ClientKey = Your Secret Key
        -TenantId = Tenant Id
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
        [Parameter(Mandatory=$true)][String]$shutdownTime,
        [Parameter(Mandatory=$true)][String]$TenantId,
        [Parameter(Mandatory=$true)][String]$ClientId, 
        [Parameter(Mandatory=$true)][String]$ClientKey 
        
    ) 
 
     
    Add-Type -Path "<local path>\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    Add-Type -Path "<local path>\Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll" 
 
    # Authorization & resource Url 
    $authUrl = "https://login.windows.net/$TenantId/" 
    $resource = "https://management.core.windows.net/" 
 
    # Create credential for client application 
    $clientCred = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential]::new($ClientId, $ClientKey) 
 
    # Create AuthenticationContext for acquiring token 
    $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authUrl, $false) 
 
    # Acquire the authentication result 
    $authResult = $authContext.AcquireTokenAsync($resource, $clientCred).Result 
 
    # Compose the access token type and access token for authorization header 
    $authHeader = $authResult.AccessTokenType + " " + $authResult.AccessToken 
 
    # the final header hash table 
    $authHeader = @{"Authorization"=$authHeader; "Content-Type"="application/json"}
  
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

    $Result = Invoke-RestMethod -Method PUT -Headers $authHeader -Uri $Uri -Body $params
    return "AutoShutdown at $shutdownTime hrs IST successfully set for VM - $vmname "
   
} 
 
Export-ModuleMember -Function "New-EnableAutoShutdownForVMs"

