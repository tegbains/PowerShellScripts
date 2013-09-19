#this script creates dropboxes for each user that is listed in a text file named "userlist.txt"

Set-Variable filename -value "userlist.txt"

$objDomainAdmins = New-Object System.Security.Principal.NTAccount "$myDomain\Domain Admins"
Set-Variable homeDir  -value “\\pw-file02\Teacher Dropboxes"
Set-Variable myDomain  -value  “SCHOOL"


foreach ($username in [System.IO.File]::ReadLines($filename)) {

    # If the folder for the user does not exist, make a new one and set the correct permissions.
    if ( (Test-Path "$homeDir\$username") -eq $false) {
       try {
        $NewFolder = New-Item -Path $homeDir -Name $username -ItemType "Directory"
        $Rights = [System.Security.AccessControl.FileSystemRights]"FullControl,Modify,ReadAndExecute,ListDirectory,Read,Write"
        $InheritanceFlag = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
        $objType =[System.Security.AccessControl.AccessControlType]::Allow
        $objUser = New-Object System.Security.Principal.NTAccount "$myDomain\$username"
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
                ($objUser, $Rights, $InheritanceFlag, $PropagationFlag, $objType)

        $objDomainAdminsACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
                ($objDomainAdmins, $Rights, $InheritanceFlag, $PropagationFlag, $objType)

        $ACL = Get-Acl -Path $NewFolder
        $ACL.AddAccessRule($objACE)
        $ACL.AddAccessRule($objDomainAdminsACE)


        $DropboxRights = [System.Security.AccessControl.FileSystemRights]"Write"
        $ReadRights = [System.Security.AccessControl.FileSystemRights]"Read"
        $NoInheritanceFlag = @([System.Security.AccessControl.InheritanceFlags]::None,[System.Security.AccessControl.InheritanceFlags]::None)
        $objEveryone = New-Object System.Security.Principal.NTAccount "Everyone"

        $objEveryoneACEWrite = New-Object System.Security.AccessControl.FileSystemAccessRule `
                ($objEveryone, $DropboxRights, $InheritanceFlag, $PropagationFlag, $objType)

        $ACL.AddAccessRule($objEveryoneACEWrite)


        $objEveryoneACERead = New-Object System.Security.AccessControl.FileSystemAccessRule `
                ($objEveryone, $ReadRights, $NoInheritanceFlag, $PropagationFlag, $objType)

        $ACL.AddAccessRule($objEveryoneACERead)

        Set-ACL -Path $NewFolder.FullName -AclObject $ACL
        }
        catch {
            $msg = $_
            $msg
        }
    }
}
