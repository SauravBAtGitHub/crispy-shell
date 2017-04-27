<# 
.SYNOPSIS 
    Script to automate querying all ASM storage account in a given subscription for file shares and listing the share, directory and filenames along with their sizes. It also exports the files and their sizes to a C:\temp\<StorageAccountName>.csv file
    

.DESCRIPTION 

Script to automate querying all ASM storage account in a given subscription for file shares and listing the share, directory and filenames along with their sizes. It also exports the files and their sizes to a C:\temp\<StorageAccountName>.csv file
    

.EXAMPLE 
    

    .\ListAzureShareFileSizes.ps1 -SubscriptionID <Your Subscription ID>

#> 

param( 
     # The name of the storage account to enumerate. 
    [Parameter(Mandatory = $true)] 
    [string]$SubscriptionID
) 
Import-Module Azure.Storage
Select-AzureRmSubscription -SubscriptionId $SubscriptionID
$global:Share = ""
$global:StorageAccount = ""
$global:Key = ""
Function ListShares
{
$sharedKey = [System.Convert]::FromBase64String($Key)
$date = [System.DateTime]::UtcNow.ToString("R")
$stringToSign = "GET`n`n`n`n`n`n`n`n`n`n`n`nx-ms-date:$date`nx-ms-version:2016-05-31`n/$StorageAccount/`ncomp:list"
$hasher = New-Object System.Security.Cryptography.HMACSHA256
$hasher.Key = $sharedKey
$signedSignature = [System.Convert]::ToBase64String($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign)))
$URI = "https://$StorageAccount.file.core.windows.net/" + "?comp=list"
$authHeader = "SharedKey ${StorageAccount}:$signedSignature"
$headers = @{"x-ms-date"=$date
             "x-ms-version"="2016-05-31"
             "Authorization"=$authHeader}

$container=""
[xml]$container= (Invoke-RestMethod -method GET -Uri $URI -Headers $headers) -replace 'ï»¿', ''
$sharename=$container.enumerationresults.shares.share.name
 
If (!$sharename){
     Echo "No File Shares Found inside storage account -- $StorageAccount, Exiting...." 
   }
    else {
        Echo `n`n
        Echo "Starting Fileshare listing under StorageAccount ======= $StorageAccount "
        Echo "---------------------------------------------------------------------------"
        $sharename
        Echo "---------------------------------------------------------------------------"
        Echo "Finishing Fileshare listing under StorageAccount ======= $StorageAccount " `n`n 
    ForEach ($objects in $sharename){
       $global:Share = $objects
       ListDirFiles("") 
       }
    }
}
Function ListDirFiles($dirpath)
{
if (!$dirpath) 
{
$resources=$share
}
else
{
$resources=$share + "/$dirpath"
}
$sharedKey = [System.Convert]::FromBase64String($Key)
$date = [System.DateTime]::UtcNow.ToString("R")
$stringToSign = "GET`n`n`n`n`n`n`n`n`n`n`n`nx-ms-date:$date`nx-ms-version:2016-05-31`n/$StorageAccount/$resources`ncomp:list`nrestype:directory"
$hasher = New-Object System.Security.Cryptography.HMACSHA256
$hasher.Key = $sharedKey
$signedSignature = [System.Convert]::ToBase64String($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign)))
$URI = "https://$StorageAccount.file.core.windows.net/$resources" + "?comp=list&restype=directory"
$authHeader = "SharedKey ${StorageAccount}:$signedSignature"
$headers = @{"x-ms-date"=$date
             "x-ms-version"="2016-05-31"
             "Authorization"=$authHeader}

$container=""
[xml]$container= (Invoke-RestMethod -method GET -Uri $URI -Headers $headers) -replace 'ï»¿', '' 
Echo "Starting File listing under directory =======$resources "
Echo "---------------------------------------------------------------------------"
if ($container.enumerationresults.entries.file.name -ne $null)
{
$container.enumerationresults.entries.file | % { $hash = @{} } { $hash += @{$_.Name = $_.Properties.'Content-Length'} }
$hash.GetEnumerator() | sort -Property name | Select-Object @{Label="FileName";Expression={$_.Key}},@{Label="FileSize";Expression={$_.Value}} | export-csv -Append C:\temp\$StorageAccount.csv -NoTypeInformation
$hash
}
else
{
Echo "No Files in this directory"
}
Echo "---------------------------------------------------------------------------"
Echo "Finished File listing under directory =======$resources "`n`n
$dpath = $container.enumerationresults | Select DirectoryPath
ForEach ($objects in $container.enumerationresults.entries.Directory.Name){
If (!$dpath.DirectoryPath){
     ListDirFiles($objects)
   }
    else {
    ListDirFiles($dpath.DirectoryPath + "/$objects")
    }
}
} 
##Looping through all ASM storage accounts in selected Subscription
$StorageObject = Get-AzureStorageAccount | Select Label

Foreach($strobj in $StorageObject)
{
$StorageAccount= $strobj.Label
$Key=(Get-AzureStorageKey -StorageAccountName $strobj.Label).Primary
ListShares
}
##Looping through all ASM storage accounts in selected Subscription
$StorageObject = Get-AzureRMStorageAccount | Select ResourceGroupName, StorageAccountName
Foreach($strobj in $StorageObject)
{
$StorageAccount= $strobj.StorageAccountName
$Key=(Get-AzureRmStorageAccountKey -ResourceGroupName $strobj.ResourceGroupName -StorageAccountName $strobj.StorageAccountName).Value[0]
ListShares
}