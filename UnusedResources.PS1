$subid='83ebec46-2fdc-47b0-876d-23b8295d5c66'
Select-AzSubscription $subid
function Get-AzureUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [datetime]$FromTime,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [datetime]$ToTime,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Hourly','Daily')]
        [string]$Interval = 'Daily'
    )
    
    Write-Verbose -Message 'Querying usage data...'
    $usageData = $null
    do {
        $params = @{
            ReportedStartTime = $FromTime
            ReportedEndTime = $ToTime
            AggregationGranularity = $Interval
            ShowDetails = $true
        }
        if ((Get-Variable -Name usageData -ErrorAction Ignore) -and $usageData) {
            Write-Verbose -Message "Querying usage data with continuation token $($usageData.ContinuationToken)..."
            $params.ContinuationToken = $usageData.ContinuationToken
        }
        $usageData = Get-UsageAggregates @params
        $usageData.UsageAggregations | Select-Object -ExpandProperty Properties
    } while ('ContinuationToken' -in $usageData.psobject.properties.name -and $usageData.ContinuationToken)
}

$Endtime=((Get-Date).Date).ToString()
$StartTime=(((Get-Date).Date).AddMonths(-2)).ToString()
$tmpobj=$null
$usage = Get-AzureUsage -FromTime $StartTime -ToTime $Endtime -Interval Daily -Verbose
$rawUsageList = $usage | ?{$_.MeterCategory -eq 'Virtual Machines'} | Select-Object InstanceData
$UsedResourcesList=$null
$UsedResourcesList = $rawUsageList | %{$val=((($_ -Split('/')) -Split(','))).Replace("`"","")#split and filter unwanted characters
$UsedResourcesList =$UsedResourcesList| Sort-Object -Unique 
$val[4] + ':' + $val[8]}
$AllResourcesList=$null
$AllResourcesList=Get-AzVm | %{$_.ResourceGroupName + ':' + $_.Name} 
if ($AllResourcesList -eq $null){Continue}
$tmpList=$null
$tmpList=(Compare-Object -ReferenceObject $UsedResourcesList -DifferenceObject $AllResourcesList -IncludeEqual)| ?{$_.SideIndicator -eq '=>'} | Select InputObject #VM list which is not utilized
if($tmplist -eq $null){continue}
######Activity Logs Skimming
$logs=$null
$logs = Get-AzLog -ResourceProvider Microsoft.Compute -StartTime (Get-Date).AddDays(-60).Date.ToShortDateString() -MaxRecord 10000 #default returns 1000 record, set to max, however may still miss out if more than 10K events in given time range
$holder=[System.Collections.ArrayList]@()
foreach($log in $logs)
    {
          $scope=(($log.Authorization.Scope -split("/")))
          $Action=(($log.Authorization.Action -split("/")))
          If($scope -contains 'virtualMachines'){$null=$holder.Add($scope[4] + ":" +  $scope[8])}
    }
if($holder.Count -eq 0){$holder.add('PlaceHolder')}else{$holder =$holder| Sort-Object -Unique}
##########Activity Logs
####Remove any VMs from the list which is created Post 12:00:00 AM Today - check needed due to limitation of Get-UsageAggregates which takes 12:00:00 AM as default time
$finalVMList=$null
$finalVMList=(Compare-Object -ReferenceObject $tmpList.InputObject -DifferenceObject $holder -IncludeEqual)| ?{$_.SideIndicator -eq '<='} | Select InputObject
####List details of all VMs and Associated disks
Write-Host $finalVMList.InputObject -ForegroundColor Green
if($finalVMList -eq $null){Continue}
foreach ($vm in $finalVMList.InputObject)
{
$ph=$vm -split(":")
get-azvm -ResourceGroupName $ph[0] -Name $ph[1]| %{if($_.StorageProfile.OsDisk.vhd.Uri -ne $null){
[PSCustomObject]@{ResourceGroup=$_.ResourceGroupName;VMName= $_.Name;OSDiskURI=$_.StorageProfile.OsDisk.vhd.Uri;DataDiskURI=if($_.StorageProfile.DataDisks -ne $null){@(foreach($ddisk in $_.StorageProfile.DataDisks){$ddisk.Vhd.Uri}) -join ','}else{'NoDataDisk'}}}
else{
[PSCustomObject]@{ResourceGroup=$_.ResourceGroupName;VMName= $_.Name;OSDiskURI=$_.StorageProfile.OsDisk.manageddisk.Id; DataDiskURI=if($_.StorageProfile.DataDisks -ne $null){@(foreach($ddisk in $_.StorageProfile.DataDisks){$ddisk.ManagedDisk.ID}) -join ','}else{'NoDataDisk'}}}}|  Export-Csv C:\Windows\temp\$subid.csv -Append -NoTypeInformation
}
ii C:\Windows\temp\$subid.csv
