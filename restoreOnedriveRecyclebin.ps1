<#
.SYNOPSIS
    Restore a given users recyclebin in Onedrive for business  
 
.DESCRIPTION
    Xperta Onedrive Scripts for Office 365
    Restore a given users recyclebin in onedrive for business
    The script uses SharePoint Online Client Object Model for most activities except for adding site administrator   
    
.EXAMPLE
   .\Onedrive-RestoreRecycleBin.ps1
    Vill ask for 365 admin credentials and use the default settings in script. These settings needs to be changed for your case
 
.EXAMPLE
   .\Onedrive-RestoreRecycleBin.ps1 -user "torbjorn.granheden@xperta.se" -OnedriveUrl "https://granheden-my.sharepoint.com/personal/torbjorn_granheden_se"
    Vill ask for 365 admin credentials and restores all Items deleted by torbjorn@granheden.se in given onedrive 

 .EXAMPLE
   .\Onedrive-RestoreRecycleBin.ps1 -user "torbjorn.granheden@xperta.se" -OnedriveUrl "https://granheden-my.sharepoint.com/personal/torbjorn_granheden_se" -startdate "2017-01-01 10:24:00" -enddate "2017-01-01 11:24:00"
    Vill ask for 365 admin credentials and restores all Items deleted between "2017-01-01 10:24:00" and "2017-01-01 11:24:00" by torbjorn@granheden.se in given onedrive

.PARAMETER OnedriveUser
    This parameter accepts userprincipalname of the user that deleted the Items. If non given, all Items in Recyclebin will be restored regardless of who deleted 

.PARAMETER OnedriveUrl
    This required parameter accepts URL to the users onedrive.  

.PARAMETER StartDate
    This parameter accepts a start date for deleted Items search in format "2017-01-01 00:00:00". If non given, all Items in Recyclebin will be restored regardless of when deleted 

.PARAMETER EndDate
    This parameter accepts a end date for deleted Items search in format "2017-01-01 00:00:00". If non given, all Items in Recyclebin will be restored regardless of when deleted 

.NOTES
    Written by Torbjörn Granheden Xperta AB
    torbjorn.granheden@xperta.se

#>

#region ---------------------------------------------------[Set script requirements]-----------------------------------------------
# This script requires:
# Sharepoint CSOM version 16         - https://www.nuget.org/packages/Microsoft.SharePointOnline.CSOM/ 
# Sharepoint Online Management Shell - https://www.microsoft.com/en-us/download/details.aspx?id=35588
#
#Requires -Version 3.0
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
#endregion

#region ---------------------------------------------------[Modifyable Parameters and defaults]------------------------------------
Param(
    [Parameter(Mandatory=$false)]
    [String[]]$OnedriveUser       ="",
    [Parameter(Mandatory=$false)]
    [String[]]$OnedriveUrl        ="https://granheden-my.sharepoint.com/personal/torbjorn_granheden_se",
    [Parameter(Mandatory=$false)]
    [String[]]$startDate          ="2000-01-01 00:00:00",
    [Parameter(Mandatory=$false)]
    [String[]]$EndDate            =$(get-date -Format "yyyy-MM-dd HH:mm:ss")
)
#endregion

#region ---------------------------------------------------[Set global script settings]--------------------------------------------
Set-StrictMode -Version Latest
#endregion

#region ---------------------------------------------------[Static Variables]------------------------------------------------------
$Scriptname = $MyInvocation.MyCommand.Name
$PSscriptRoot = Split-Path (Resolve-Path $myInvocation.MyCommand.Path)
#Log File Info
$startTime = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$Logfile = $PSscriptRoot + "\" + $scriptName + " " + $startTime + ".log"
#endregion

#region ---------------------------------------------------[Import Modules and Extensions]-----------------------------------------
# Paths to SDK. Please verify location on your computer.
Try {
    Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll" 
    Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.UserProfiles.dll"
    }
Catch {logwrite -Logstring $_ -type Error;Break}
Try{Import-Module 'Microsoft.Online.SharePoint.PowerShell' -DisableNameChecking} Catch{logwrite -Logstring $_ -type Error;Break}
#endregion

#region ---------------------------------------------------[Functions]------------------------------------------------------------
Function LogWrite{
    Param(
        $logfile = "$logfile",
        [validateset("Info","Warning","Error")]$type = "Info",
        [string]$Logstring
    )
  
  Begin{ }
  
  Process{
    Try{
        if($type -eq "Info"){$foreGroundColor = "Green"}
        if($type -eq "Warning"){$foreGroundColor = "Cyan"}
        if($type -eq "Error"){$foreGroundColor = "Red"}
        Add-content $Logfile -value "$(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') - $type - $logstring"
  	    Write-Host $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') - $logstring -ForegroundColor $foreGroundColor 
    
    }
    
    Catch{
      Write-Host $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') - $_ -ForegroundColor Cyan
      Break
    }
  }
  
  End{ }
}

Function Login2SPO{
    Param(
        [Parameter(Mandatory=$True)]$creds,
        [Parameter(Mandatory=$True)]$site
    )
  
    Begin{logwrite -Logstring "Signing in to SharePoint Online services" -type Info} 
  
    Process{
        Try{Connect-SPOService -Url $site -Credential $Creds} Catch{logwrite -Logstring $_ -type Error;Break}
    }
  
    End{ logwrite -Logstring "Successfully signed in to SharePoint Online Services" -type Info }
}
#endregion

#region ---------------------------------------------------[[Script Execution]------------------------------------------------------
logwrite -Logstring "Starting script to Restore a given users recyclebin in onedrive for business" -type Info
Get-PSSession|Remove-PSSession
 
logwrite -Logstring "Setting sharepoint online global admin credentials" -type Info
$365AdminCredentials = Get-Credential -Message "Enter Global Admin Credentials"
try   {$365AdminUsername = $365AdminCredentials.UserName}
catch {logwrite -Logstring "Credentials missing, error: '$_.Exception.Message'" -type error
        break}
$365AdminPassword = $365AdminCredentials.Password
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($365AdminUsername, $365AdminPassword) 
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($OnedriveUrl) 
$ctx.Credentials = $credentials

logwrite -Logstring "Checking if $365adminusername as site admin for $OnedriveUrl" -type Info
$spUser = $ctx.Web.EnsureUser($365AdminUsername) 
$ctx.Load($spUser) 
try     {$ctx.ExecuteQuery()}
catch   {logwrite -Logstring "Failed to check if $365adminusername as site admin for $OnedriveUrl with error: '$_.Exception.Message'" -type error
        break}

if (!$spUser.IsSiteAdmin)
    {
    logwrite -Logstring "Set $365adminusername as site admin for $OnedriveUrl" -type info
    $adminURL = $OnedriveUrl.Replace("-my","-admin") 
    $adminUrl = $adminUrl -replace '(.*?)personal.*', '$1'
    Login2SPO $365AdminCredentials $adminurl
    try    {$site=Get-SPOSite -limit all -IncludePersonalSite $true| where { $_.Url -eq $OnedriveUrl}
            Set-SPOUser -site $site -LoginName $365AdminUsername -IsSiteCollectionAdmin $true | Out-Null}
    catch  {logwrite -Logstring "Failed to Set $365adminusername as site admin for $OnedriveUrl with error: '$_.Exception.Message'" -type error
            break}
    }

logwrite -Logstring "Collecting all deleted Items from $OnedriveURL" -Type Info
$Recyclebinarray=$ctx.Site.RecycleBin
$ctx.Load($Recyclebinarray)
try     {$ctx.ExecuteQuery()}
catch   {logwrite -Logstring "Failed Collecting all deleted Items from $OnedriveURL with error: '$_.Exception.Message'" -type error
        break}
        
$RecycleBinArraycount=$Recyclebinarray.count
logwrite -Logstring "Recyclebin contains $RecycleBinArraycount items" -type info
If ($RecycleBinArraycount -lt 1)
    {logwrite -Logstring "Recyclebin is empty, no files to restore, ending script" -type warning
    break}

logwrite -Logstring "Filter Recylebin Items for who and when deleted" -Type Info
$FilteredRecycleBinArray = @()
foreach($item in $Recyclebinarray) 
    {
	$itemDeletedDate = $item.DeletedDate.ToString('yyyy-MM-dd HH:mm:ss')
	$itemname = $item.title
	#Check if item deleted is between start date and end date
	if ($itemDeletedDate -ge $startDate -and $itemDeletedDate -le $endDate)
        {
        $ctx.Load($item.DeletedBy)
		Try  {$ctx.ExecuteQuery()}
        catch{logwrite -Logstring "Failed to load deleted item info for who deleted the item $itemname with error: '$_.Exception.Message'" -type warning}
		$itemDeletedBy = $item.DeletedBy.LoginName.split("|")
		#Check if item deleted by specific user
        if ($itemDeletedBy[2].ToString() -eq $OnedriveUser -or !$OnedriveUser)
            {$FilteredRecycleBinArray += $Item}
         }
    }
$FilteredRecycleBinArraycount = $FilteredRecycleBinArray.Count
if ($FilteredRecycleBinArraycount -lt 1)
    {logwrite -Logstring "Filtered Recyclebin result is empty, no files to restore, ending script" -type warning
    break}
logwrite -Logstring "Filtered Recyclebin contains $FilteredRecycleBinArraycount items" -type Info        

logwrite -Logstring "Sorting items to restore. Folders first, then Items. Deleted dates descending. And then item path descending " -type Info 
$FilteredRecycleBinArray = $FilteredRecycleBinArray | sort-object -property @{Expression="Itemtype";Descending=$true}, @{Expression="DeletedDate";Descending=$true}, @{Expression="dirname";Descending=$false}

logwrite -Logstring "Starting Restore of files" -type Info 
foreach ($fileitem in $FilteredRecycleBinArray)
    {
    $filename = $fileItem.Title
    $fileitem.Restore()
    try {
        $ctx.ExecuteQuery()
        logwrite -Logstring "Item $filename restored successfully" -type info
        }
    catch 
        {
        logwrite -Logstring "Item $filename failed to restore with error: '$_.Exception.Message'" -type error
	    }
    }

logwrite -Logstring "Remove $365adminusername as site admin for $OnedriveUrl" -type Info
$spUser.IsSiteAdmin = $false; 
$spUser.Update();
$ctx.Load($spUser) 
try     {$ctx.ExecuteQuery()}
catch   {logwrite -Logstring "Failed remove $365adminusername as site admin for $OnedriveUrl with error: '$_.Exception.Message'" -type error}
         
$ctx.Dispose()
Get-PSSession|Remove-PSSession
Set-StrictMode -Off
logwrite -Logstring "Script finished" -type info
#endregion