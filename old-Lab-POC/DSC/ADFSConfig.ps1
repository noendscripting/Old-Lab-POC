Configuration ADFSConfig
{

[CmdletBinding()]
Param ( [string] $nodeName = "localhost"  )

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node localhost
  {
      LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		    ConfigurationModeFrequencyMins =  15
		}
	   WindowsFeature ADFS
	  {
		Name="ADFS-Federation"
		Ensure = "Present"
		IncludeAllSubFeature = $true
	  }

  }
}