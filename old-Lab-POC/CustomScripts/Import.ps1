<#
.DISCLAIMER
    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained
    within the Premier Customer Services Description.
#>
. (Join-Path ([System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)) "Microsoft.Rba.LogFunctions.ps1")

try
{
	"Script location: $PSScriptRoot" | Out-File (join-path $env:temp "location.txt") -Force

	"Importing $PSScriptRoot\OUs.csv file" | Add-RbaLogEntry -Severity ([Severity]::Info)
	$ous = Import-CSV (Join-Path $PSScriptRoot "OUs.csv")

	"Creating OUs" | Add-RbaLogEntry -Severity ([Severity]::Info)
	$ous | New-ADOrganizationalUnit

	"Importing $PSScriptRoot\Users.csv file" | Add-RbaLogEntry -Severity ([Severity]::Info)
	$users = Import-CSV (Join-Path $PSScriptRoot "Users.csv")

	"Creating users" | Add-RbaLogEntry -Severity ([Severity]::Info)
	Foreach ($user in $users)
	{
		New-ADUser -GivenName $user.GivenName -Surname $user.Surname -Initials $user.Initials -DisplayName $user.DisplayName -Name $user.Name -SamAccountName $user.SamAccountName -UserPrincipalName $user.UserPrincipalName -AccountPassword (ConvertTo-SecureString $user.AccountPassword -AsPlainText -Force) -PasswordNeverExpires $True -ChangePasswordAtLogon $False -Enabled $True -Path $user.Path
	}

	"Importing $PSScriptRoot\Groups.csv file" | Add-RbaLogEntry -Severity ([Severity]::Info)
	$groups = Import-CSV (Join-Path $PSScriptRoot "Groups.csv")

	"Creating groups" | Add-RbaLogEntry -Severity ([Severity]::Info)
	$groups | New-ADGroup -Path "OU=Company Users,DC=contosoad,DC=com"

	"Importing $PSScriptRoot\Members.csv file" | Add-RbaLogEntry -Severity ([Severity]::Info)
	$members = Import-CSV (Join-Path $PSScriptRoot "Members.csv")

	"Adding users to groups" | Add-RbaLogEntry -Severity ([Severity]::Info)
	Foreach ($member in $members)
	{
		Add-ADGroupMember -Identity $member.Identity -Members (Get-ADUser $member.Members)
	}
}
catch
{
	"An error ocurred $_" | Add-RbaLogEntry -Severity ([Severity]::Error)
}

Start-Sleep -Seconds 600