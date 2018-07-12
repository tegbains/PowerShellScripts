$targetMailbox = Read-Host -Prompt 'Input your mailbox name'

$mailboxExportPath = "\\scdc-ex02\OldEmailDumps\"

$targetMailboxPath = $mailboxExportPath + $targetMailbox + ".pst"

New-MailboxExportRequest –Mailbox $targetMailbox –FilePath $targetMailboxPath 