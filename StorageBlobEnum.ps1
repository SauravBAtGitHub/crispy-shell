<# 
.SYNOPSIS 
    Enumerates all ARM storge accounts and List, Delete or exports (Premium only) them to an excel file. It will delete page blobs based on the LeaseStatus being Unlocked.

    1. For listing blobs (Block\Page) from all storage accounts of the specified type (Standard, Premium) " 

    2. For deleting blobs (Block\Page) from all storage accounts of the specified type (Standard, Premium), which are currently not in use"

    3. For exporting blobs sizes (Block\Page) from all storage accounts of the specified type (Standard, Premium) to an Excel file"

.DESCRIPTION 
    1. For listing blobs (Block\Page) from all storage accounts of the specified type (Standard, Premium) " 

    2. For deleting blobs (Block\Page) from all storage accounts of the specified type (Standard, Premium), which are currently not in use"

    3. For exporting blobs sizes (Block\Page) from all storage accounts of the specified type (Standard, Premium) to an Excel file"

.EXAMPLE 
    Choice = List\Delete\Export
    
    .\StorageBuddy.ps1 -SubscriptionID <Subscription ID> -StorageType "PremiumLRS" -Choice "List"
    .\StorageBuddy.ps1 -SubscriptionID <Subscription ID> -StorageType "PremiumLRS" -Choice "Delete"
    .\StorageBuddy.ps1 -SubscriptionID <Subscription ID> -StorageType "PremiumLRS" -Choice "Export"


    .\StorageBuddy.ps1 -subid <Sub ID> -StorageType "StandardLRS" -Choice "List"

    .\StorageBuddy.ps1 -subid <Sub ID> -StorageType "StandardGRS" -Choice "Delete"
#> 
  
param( 
     # The name of the storage account to enumerate. 
    [Parameter(Mandatory = $true)] 
    [string]$SubscriptionID, 
  
   # The name of the storage container to enumerate. 
    [Parameter(Mandatory = $true)] 
    [ValidateNotNullOrEmpty()] 
    [string]$StorageType,

    # The name of the storage container to enumerate. 
    [Parameter(Mandatory = $true)] 
    [ValidateNotNullOrEmpty()] 
    [string]$Choice


) 
  
# The script has been tested on Powershell 3.0 
Set-StrictMode -Version 3 
  
# Following modifies the Write-Verbose behavior to turn the messages on globally for this session 
$VerbosePreference = "Continue" 
  
# Check if Windows Azure Powershell is avaiable 
#Login-azurermaccount
#get-azuresubscription
#Select-AzureRmSubscription -SubscriptionId $SubscriptionID

Echo ""
Switch ($Choice) {
"List" {
Echo "** Listing disks..."
Echo "---------------------"
$storageBlob=Get-AzureRmStorageAccount | Where-Object{$_.AccountType -match $StorageType} | Get-AzureStorageContainer | Get-AzureStorageBlob 
$infoholderobj=""
$infoholderobj = @()
foreach($blob in $storageBlob)
{
$infohash = [Ordered]@{

'Blob Name' = $blob.ICloudBlob.Name
'Disk Container' = $blob.ICloudBlob.Container.Name
'Account Name' = ($blob.ICloudBlob.Container.Uri.Host).ToString().Split(".")[0]
'Blob Type' = $blob.ICloudBlob.BlobType
'LeaseState' = $blob.ICloudBlob.Properties.LeaseState
'LeaseStatus' = $blob.ICloudBlob.Properties.LeaseStatus
'LastModifiedDate' = $blob.ICloudBlob.Properties.LastModified.Date}

$infoholderobj += $infohash
}

$infoholderobj.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

}

"Delete" {
Echo "** Deleting Disks..."
Echo "--------------------"
$storageBlob=Get-AzureRmStorageAccount | Where-Object{$_.AccountType -match $StorageType} | Get-AzureStorageContainer | Get-AzureStorageBlob 
$OPT=""
$infohash1 =""
$infoholderobj1 = @()
        foreach($blob in $storageBlob)
                                                                {

        if (($blob.ICloudBlob.Properties.LeaseStatus -eq "Unlocked") -and ($blob.ICloudBlob.Properties.BlobType -eq "PageBlob"))
                                                    {
        
        #Write-host "The following disk will be removed: "  $blob.ICloudBlob.Name " from container ::" $blob.ICloudBlob.Container.Name   "in disk path ::" $blob.ICloudBlob.Parent.Uri
         
        $infohash1 = [Ordered]@{
        'DiskName' = $blob.ICloudBlob.Name
        'LeaseStatus' = $blob.ICloudBlob.Properties.LeaseStatus
        'Disk Container' = $blob.ICloudBlob.Container.Name
        'Disk Location' = $blob.ICloudBlob.Parent.Uri
        'LastModifiedDate' = $blob.ICloudBlob.Properties.LastModified.Date}

        
    }
        $infoholderobj1 += $infohash1
        }

Write-host "The following disk will be removed, do you wish to continue?" 
$infoholderobj1.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

Write-host "Please note that the deleted blob can't be recovered. If you continue with the operations, all listed blobs above will be permanently deleted. `n
It's expected that you have validated every single blob in the list above as not required and you understands the risk to continue with the delete operation on all listed blobs above.." -ForegroundColor Red
$MyErr=""
$OPT= Read-Host "Do you wish to continue? Press [Y] for Yes, [N] for No : " 
        If ($OPT.ToUpper() -eq "Y")
        {
        
                foreach($blob in $storageBlob)
                {

                    if (($blob.ICloudBlob.Properties.LeaseStatus -eq "Unlocked") -and ($blob.ICloudBlob.Properties.BlobType -eq "PageBlob"))
                    {
                            
                            Remove-AzureStorageBlob -Container $blob.ICloudBlob.Container.Name -Blob $blob.ICloudBlob.Name -Context $blob.Context
                            Write-host "Removed :: " $blob.ICloudBlob.Name "successfully"
                     }

                            
                               
                 } 
                 
                 Write-host "Errors if any will be documented in your temp folder. Go to start->Run-> Type %temp% and hit enter. Look for StorageEnumError.log in temp folder"
                 $Error | out-file "$env:temp\StorageEnumError.log" -append        
          }
          Else
          {
           Write-host "Exiting..."
           Exit
          }
    
                } 
                
  

"Export" {
Echo "** Listing accounts, containers and their sizes..."
Echo "--------------------------------------------------"
$storageBlob=Get-AzureRmStorageAccount | Where-Object{$_.AccountType -match $StorageType} | Get-AzureStorageContainer | Get-AzureStorageBlob 
$infoholderobj=""
$infoholderobj = @()
foreach($blob in $storageBlob)
{

If ((($blob.Length).ToString()).Length -le 7){

$infohash = [Ordered]@{
'Account Name' = ($blob.ICloudBlob.Container.Uri.Host).ToString().Split(".")[0]
'Container Name' = $blob.ICloudBlob.Container.Name
'Type of Blob' = $blob.ICloudBlob.BlobType
'Blob Name' = $blob.ICloudBlob.Name
'Size in GB' = "0"
'Size in MB' = "0"
'Size in KB' = (($blob.Length)/1024).ToString().Split(".")[0]
'Size in Bytes' = (($blob.Length)).ToString()}
}

If ((($blob.Length).ToString()).Length -gt 7) {

$infohash = [Ordered]@{
'Account Name' = ($blob.ICloudBlob.Container.Uri.Host).ToString().Split(".")[0]
'Container Name' = $blob.ICloudBlob.Container.Name
'Type of Blob' = $blob.ICloudBlob.BlobType
'Blob Name' = $blob.ICloudBlob.Name
'Size in GB' = (($blob.Length)/1070599167).ToString().Split(".")[0] 
'Size in MB' = (($blob.Length)/1048576).ToString().Split(".")[0]
'Size in KB' = (($blob.Length)/1024).ToString().Split(".")[0]
'Size in Bytes' = (($blob.Length)).ToString()
}

}

$infoholderobj += $infohash
}

$tmp =  Get-Random
$Filename= "StorageConsumptionOutput" + $tmp.Tostring() + ".csv"
$infoholderobj.ForEach({[PSCustomObject]$_}) | Export-csv "$env:temp\$Filename" -Append -Force
Invoke-Item "$env:temp\$Filename"

}

}
