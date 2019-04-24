<# 

.SYNOPSIS 

    Script to automate, closing open handles on a directory 

.DESCRIPTION 

This Scrip closes all handles opened on a directory or share. It supports closing all handles opened on that resource. It supports recursively closing handles on subresources when the resource is a directory.
This script is intended to be used to force close all handles that block operations, such as renaming a directory. These handles may have leaked or been lost track of by SMB clients. 
The Operation has client-side impact on the handle being closed, including user visible errors due to failed attempts to read or write files. 
Not intended for use as a replacement or alternative for SMB close.
Script will throw error if attempted to be used to close a single file. 

The script can however be worked further to list open handles and close a single handle etc.

Refer: https://docs.microsoft.com/en-us/rest/api/storageservices/force-close-handles

Running the script will return the below output, refer x-ms-number-of-handles-closed to verify handles closed.

Sample Output below
Key                           Value                                       
---                           -----                                       
x-ms-request-id               49922229-c01a-004b-3ec8-f5cb49000000        
x-ms-version                  2018-11-09                                  
x-ms-number-of-handles-closed 5                                           
Content-Length                0                                           
Date                          Thu, 18 Apr 2019 04:25:35 GMT               
Server                        Windows-Azure-File/1.0 Microsoft-HTTPAPI/2.0

.EXAMPLE 

    Storageaccount      - MyStorageAccount
    Storage account Key - Long_access_key____________________==
    Sharedirpath        - Myfileshare/mydir1 OR Myfileshare/mydir1/mydir2


    .\AFS-closeHandle.ps1 -StorageAccount <StorageAccountName> -Key <Access Key for Storage Account> -sharedirpath <Sharename/dir1/dir2>

#> 

param (
    [Parameter(Mandatory=$true)][string]$StorageAccount,
    [Parameter(Mandatory=$true)][string]$Key,
    [Parameter(Mandatory=$true)][string]$sharedirpath # Operation will apply to all files and subdirectories of the path specified here. Provide Sharename/dir1/dir2 to close handles of all subdir and files within
    # Read https://docs.microsoft.com/en-us/rest/api/storageservices/force-close-handles#authorization for details.
 )
Function CloseHandle()
{
$sharedKey = [System.Convert]::FromBase64String($Key)
$date = [System.DateTime]::UtcNow.ToString("R")
$strToSign = "PUT`n`n`n`n`n`n`n`n`n`n`n`nx-ms-date:$date`nx-ms-handle-id:*`nx-ms-recursive:true`nx-ms-version:2018-11-09`n/$StorageAccount/$sharedirpath`ncomp:forceclosehandles"
$hasher = New-Object System.Security.Cryptography.HMACSHA256
$hasher.Key = $sharedKey
$Signature = [System.Convert]::ToBase64String($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($strToSign)))
$URI = "https://$StorageAccount.file.core.windows.net/$sharedirpath" + "?comp=forceclosehandles"
$authHeader = "SharedKey ${StorageAccount}:$Signature"
$headers = @{"x-ms-date"=$date
             "x-ms-version"="2018-11-09"
             "x-ms-handle-id"="*"
             "x-ms-recursive"="true"
             "Authorization"=$authHeader}
$respObj=$null
$respObj=(Invoke-WebRequest -method PUT -Uri $URI -Headers $headers)
$respObj.Headers
}
CloseHandle