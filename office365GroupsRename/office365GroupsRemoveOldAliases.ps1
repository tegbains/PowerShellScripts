Write-Output("Getting List of Office365 Groups that match")

$oldDomainName = "summitaec.com"
$newDomainName = "summitbim.com"

$o365GroupsList = Get-Recipient | where {$_.EmailAddresses -match $oldDomainName -and $_.RecipientType -match "MailUniversalDistributionGroup" }

Write-Output("Iterating through the list of Groups")

foreach ($groupToRename in $o365GroupsList) {
	$groupToRenameIdentity = $groupToRename.Identity
	$groupToRenamePrimarySMTPSplitArray = $groupToRename.PrimarySmtpAddress -split '@'
	
	$oldGroupSMTPAlias = -join ($groupToRenamePrimarySMTPSplitArray[0], '@', $oldDomainName)
	
	
	Set-Unifiedgroup -Identity $groupToRenameIdentity -emailaddresses @{remove=$oldGroupSMTPAlias}
	
}
Write-Output("Finished renaming the Office365 Groups")
