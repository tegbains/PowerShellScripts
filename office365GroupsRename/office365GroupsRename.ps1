Write-Output("Getting List of Office365 Groups that match")

$oldDomainName = "summitaec.com"
$newDomainName = "summitbim.com"

$o365GroupsList = Get-Recipient | where {$_.EmailAddresses -match $oldDomainName -and $_.RecipientType -match "MailUniversalDistributionGroup" }

Write-Output("Iterating through the list of Groups")

foreach ($groupToRename in $o365GroupsList) {
	$groupToRenameIdentity = $groupToRename.Identity
	$groupToRenamePrimarySMTPSplitArray = $groupToRename.PrimarySmtpAddress -split '@'
	
	$newGroupSMTPPrimaryAddress = -join ($groupToRenamePrimarySMTPSplitArray[0], '@', $newDomainName)
	
	# $groupToRenameNameSMTPAddress = Get-UnifiedGroup -Identity $groupToRenameIdentity | fl Name, PrimarySmtpAddress
	
	# Write-Output -join ("New Group Email address is:", $newGroupSMTPPrimaryAddress)
	
	Set-UnifiedGroup -Identity $groupToRenameIdentity -PrimarySmtpAddress $newGroupSMTPPrimaryAddress

	
}
Write-Output("Finished renaming the Office365 Groups")
