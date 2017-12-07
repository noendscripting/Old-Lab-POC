Configuration DcConfig
{
	[CmdletBinding()]

	Param
	(
		[string]$NodeName = 'localhost',
		[PSCredential]$DomainAdminCredentials,
		[string]$DomainName,
		[array]$DNSSearchSuffix,
		[string]$dNSIP

	)

	Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xStorage, xComputerManagement, xAdcsDeployment, xTimeZone, xNetworking

	Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
	{             
  		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		 xTimeZone TimeZoneExample

        {
			isSingleInstance = 'Yes'
            TimeZone = 'Eastern Standard Time'

        }


		WindowsFeature DNS_RSAT
		{ 
			Ensure = "Present" 
			Name = "RSAT-DNS-Server"
		}

		WindowsFeature ADDS_Install 
		{ 
			Ensure = 'Present' 
			Name = 'AD-Domain-Services' 
		} 

		WindowsFeature RSAT_AD_AdminCenter 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-AdminCenter'
		}

		WindowsFeature RSAT_ADDS 
		{
			Ensure = 'Present'
			Name   = 'RSAT-ADDS'
		}

		WindowsFeature RSAT_AD_PowerShell 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-PowerShell'
		}

		WindowsFeature RSAT_AD_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-Tools'
		}

		WindowsFeature RSAT_Role_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-Role-Tools'
		}      

		xWaitForDisk Wait_Data_Disk
		{
			DiskNumber = $Node.DataDiskNumber
			RetryCount = $Node.RetryCount
			RetryIntervalSec = $Node.RetryIntervalSec
			DependsOn = '[WindowsFeature]RSAT_Role_Tools','[xTimeZone]TimeZoneExample'
		}

		xDisk Data_Disk
		{
			DiskNumber = $Node.DataDiskNumber
			DriveLetter = $Node.DataDriveLetter
			AllocationUnitSize = 4096
			DependsOn = '[xWaitforDisk]Wait_Data_Disk'
		}

		xADDomain CreateForest 
		{ 
			DomainName = $DomainName            
			DomainAdministratorCredential = $DomainAdminCredentials
			SafemodeAdministratorPassword = $DomainAdminCredentials
			#DnsDelegationCredential = $DomainAdminCredentials
			DomainNetbiosName = $Node.DomainNetBiosName
			DatabasePath = $Node.DataDriveLetter + ":\NTDS"
			LogPath = $Node.DataDriveLetter + ":\NTDS"
			SysvolPath = $Node.DataDriveLetter + ":\SYSVOL"
			DependsOn = '[xDisk]Data_Disk', '[WindowsFeature]ADDS_Install'
		}
		
		WindowsFeature RSAT_ADCS
		{
			Ensure='Present'
			Name='RSAT-ADCS'
			DependsOn='[xADDomain]CreateForest'
		}
	

		WindowsFeature ADCS-Cert-Authority
        {
               Ensure = 'Present'
               Name = 'ADCS-Cert-Authority'
			   DependsOn = '[WindowsFeature]RSAT_ADCS'
        }

        xADCSCertificationAuthority ADCS
        {
            Ensure = 'Present'
            Credential = $DomainAdminCredentials
            CAType = 'EnterpriseRootCA'
			CACommonName = "Contoso AD Root CA"
	        KeyLength = 4096
			ValidityPeriod = 'Years'
			ValidityPeriodUnits = 8
		    DependsOn = '[WindowsFeature]ADCS-Cert-Authority','[xADDomain]CreateForest'
        }
		 xDnsClientGlobalSetting AddDNSSuffix
        {
            IsSingleInstance = 'Yes'
            SuffixSearchList = $DNSSearchSuffix
            UseDevolution    = $false
			DependsOn = '[xADDomain]CreateForest'

            
        }

		xDnsServerAddress DnsServerAddress
        {
            Address        = $dNSIP
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Validate       = $true
			DependsOn = '[xADDomain]CreateForest'
        }
	}
}