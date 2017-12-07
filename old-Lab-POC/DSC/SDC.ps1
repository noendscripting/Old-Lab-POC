
Configuration Main
{

Param ( 
	
	[string] $nodeName = "localhost",
    [string] $DataDiskNumber,
	[string] $DataDriveLetter,
    [string] $parentForest,
    [string] $domainname,
    [System.Management.Automation.PSCredential] $DomainAdminCredentials,
	[array] $DNSSearchSuffix


	


)

Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xStorage, xComputerManagement, xAdcsDeployment,xNetworking, xTimeZone

[array]::Reverse($DNSSearchSuffix)

Node $nodeName
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
	xWaitForDisk Wait_Data_Disk
		{
			DiskNumber = $DataDiskNumber
			RetryCount = 3
			RetryIntervalSec = 60
		}
	xDisk Data_Disk
		{
			DiskNumber = $DataDiskNumber
			DriveLetter = $DataDriveLetter
			AllocationUnitSize = 4096
			DependsOn = '[xWaitforDisk]Wait_Data_Disk','[xTimeZone]TimeZoneExample'
		}
	WindowsFeature RSAT_Role_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-Role-Tools'
		}
	
        WindowsFeature DNS
		{
			Ensure = 'Present'
			Name   = 'DNS'
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
       
        WindowsFeature GPMC
		{
			Ensure = 'Present'
			Name   = 'GPMC'
		}
      	  		
        xDnsClientGlobalSetting AddDNSSuffix
        {
            IsSingleInstance = 'Yes'
            SuffixSearchList = $DNSSearchSuffix
            UseDevolution    = $false
            
        }
	  <#Script Reboot
	  {
		  TestScript = 
		  {
			 return (Test-Path C:\Packages\reboot.log )
		  
		  }
		  GetScript =
		  {
				$TestResult = Test-ADDSDomainControllerInstallation -DomainName $using:domainname -SafeModeAdministratorPassword $using:DomainAdminCredentials.Password -Credential $using:DomainAdminCredentials
				if ($testresult.status -notcontains "Error")
				{
					$results = @{"domain"=$True}
				}
			  else
				{
					$results = @{"domain"=$false}
				}
		      return $results
			}
		  SetScript = 
		  {
			  Get-Date | Out-File C:\Packages\reboot.log	
			  #start-sleep -Seconds 300		
			  Restart-Computer -Force 
		  
		  }
		  Dependson = '[xDnsClientGlobalSetting]AddDNSSuffix','[WindowsFeature]ADDS_Install'
	  }#>
       xWaitForADDomain DscForestWait
        {
            DomainName = $parentForest
            DomainUserCredential = $DomainAdminCredentials
            #DependsOn = '[Script]Reboot'
			RetryCount = 4
            RetryIntervalSec = 300
            
        }

        xADDomain ChildDS
        {
            DomainName = $domainname
            ParentDomainName = $parentForest
            DomainAdministratorCredential = $DomainAdminCredentials
            SafemodeAdministratorPassword = $DomainAdminCredentials
			DatabasePath = "$($DataDriveLetter):\NTDS"
			LogPath = "$($DataDriveLetter):\NTDS"
			SysvolPath = "$($DataDriveLetter):\SYSVOL"
            DependsOn = '[xWaitForADDomain]DscForestWait','[xWaitForDisk]Wait_Data_Disk'
        }

	   Registry RegistryExample
    {
        Ensure      = "Present"  # You can also set Ensure to "Absent"
        Key         = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
        ValueName   = "Global Catalog Partition Occupancy"
        ValueData   = "6"
		DependsOn = '[xADDomain]ChildDS'
    }



	
      
  }
}