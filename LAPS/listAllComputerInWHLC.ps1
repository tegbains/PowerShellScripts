# ActiveDirectory LAPS Output script
# Teg Bains - Jan 1, 2018
# Version 1.5

Import-Module ActiveDirectory


# List all OU's to traverse
$ouList = @("OU=SomeOUName,OU=SomeOtherOUName,DC=subdomain,DC=mydomain,DC=com", "OU=SomeOUName2,OU=SomeOtherOUName,DC=subdomain,DC=mydomain,DC=com")


#Create List of all computers

$ComputersList = @()

foreach ($targetOU in $ouList) {

    $ComputersList  += Get-ADComputer -Filter '*' -SearchBase $targetOU 

 }

# create list to store the of computer names and passwords
$ComputerNameList = @()

foreach ($Computer in $ComputersList) {

    $ComputerWithPassword = Get-AdmPwdPassword -Computername $Computer | Select ComputerName, Password

    # Display Computer Name and Password
    # $ComputerWithPassword

    $ComputerNameList +=  $ComputerWithPassword
}


# Sort the ComputerName List
$ComputerNameList = $ComputerNameList | Sort-Object

# Write the file
Out-File -FilePath "localAdminPasswordList.txt" -InputObject $ComputerNameList -Encoding UTF8 -Width 50