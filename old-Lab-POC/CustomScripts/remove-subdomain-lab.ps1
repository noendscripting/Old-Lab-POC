$secpassword = ConvertTo-SecureString "Test@2016" -AsPlainText -Force
$creds = new-object -typename System.Management.Automation.PSCredential -argumentlist "contosoad\vadmin", $secpassword
Uninstall-ADDSDomainController -LocalAdministratorPassword $creds.Password -Credential $creds -LastDomainControllerInDomain -RemoveApplicationPartitions -Force -NoRebootOnCompletion
