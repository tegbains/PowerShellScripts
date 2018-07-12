# Run on a Window 10 PC in regular PowerShell terminal as Administrator
# assuming that you have installed the LAPS PowerShell module

Import-Module AdmPwd.PS

Reset-AdmPwdPassword -Computername pcNameHere -WhenEffective 12/31/2019

# read the password

Get-AdmPwdPassword -Computername pcNameHere

