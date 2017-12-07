<# Custom Script for Windows #>
Get-NetFirewallProfile  | set-NetFirewallProfile -LogAllowed True -LogBlocked True -LogIgnored True

"Script location: $PSScriptRoot" | Out-File (join-path $env:temp "location.txt") -Force


$currentDomain = Get-ADDomain -Current LocalComputer

$ous = Import-CSV (Join-Path $PSScriptRoot "OUs.csv")
$ous | New-ADOrganizationalUnit -Path $currentDomain.DistinguishedName

$users = Import-CSV (Join-Path $PSScriptRoot "$($currentDomain.NetBIOSName)-Users.csv")
Foreach ($user in $users)
	{
		New-ADUser -GivenName $user.GivenName -Surname $user.Surname  -DisplayName $user.DisplayName -Name $user.Name -SamAccountName $user.SamAccountName -UserPrincipalName "$($user.SamAccountName)@$($currentDomain.NetBIOSName).$($currentDomain.ParentDomain)" -AccountPassword (ConvertTo-SecureString "passw@rd1" -AsPlainText -Force) -PasswordNeverExpires $True -ChangePasswordAtLogon $False -Enabled $True -Path "OU=Company Users,$($currentDomain.DistinguishedName)"
	}

Start-Process -FilePath C:\Windows\System32\Repadmin.exe -ArgumentList "/kcc > c:\Packages\repadmin-kcc.log" -NoNewWindow -Wait
Start-Process -FilePath C:\Windows\System32\Repadmin.exe -ArgumentList "/syncall /edSA > c:\Packages\repadmin-syncall.log" -NoNewWindow -Wait
shutdown -r -t 10 -f -C "Final restart DC $($env:computername)"
