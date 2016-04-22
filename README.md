# crispy-shell
Thought it would be interesting to write a script to

SupportedVMRoleSizes - To identify what VM sizes are supported by their existing cloud services. 

StorageBlobEnum.PS1 - Powershell script with functionality for Listing and exporting blob details to an excel file or deleting blobs. 
    Choice = List\Delete\Export
    .\StorageBlobEnum.ps1 -SubscriptionID <Subscription ID> -StorageType "PremiumLRS" -Choice "List"
    .\StorageBlobEnum.ps1 -SubscriptionID <Subscription ID> -StorageType "PremiumLRS" -Choice "Delete"
    .\StorageBlobEnum.ps1 -SubscriptionID <Subscription ID> -StorageType "PremiumLRS" -Choice "Export" 

Please use Export switch for ARM premium accounts only, for ASM standard storage billable size you may use the script here https://gallery.technet.microsoft.com/scriptcenter/Get-Billable-Size-of-32175802.

AZDCIPRanges.PS1 - Script to download (https://www.microsoft.com/en-in/download/details.aspx?id=41653) the IP range for the specified region and add it to the windows firewall outbound IP ranges to restric communication within AZ datacenters only. Requires elevation.

    .\AZDCIPRanges.ps1  -region "useast"



