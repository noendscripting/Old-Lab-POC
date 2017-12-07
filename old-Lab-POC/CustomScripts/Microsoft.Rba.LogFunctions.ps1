<#
.SYNOPSIS
   Microsoft.RaasAD.Rba.LogFunctions.ps1 - This module contains generic functions for logging, this should be DOT sourced on every script that needs logging
.DESCRIPTION
   Microsoft.RaasAD.Rba.LogFunctions.ps1 - This module contains generic functions for logging, this should be DOT sourced on every script that needs logging
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

#>
#-----------------------------------------------
# Variables, Enumerators and Classes Definition
#-----------------------------------------------
$enumSeverityDef = @"
public enum Severity
{	
	Info,
	Warn,
	Error
}
"@
try { Add-Type -TypeDefinition $enumSeveritydef } catch {}

function Add-RbaLogEntry
{
	<#
	.SYNOPSIS
	   	Adds a log entry in a defined log file.
	.DESCRIPTION
	   	Adds a log entry in a defined log file.
	.PARAMETER Severity
		Severity string, which can be obtained from severity enum (Informational, Warning, Error)
	.PARAMETER NoConsoleOutput
		Does not shows message that was logged on file to screen
	.PARAMETER Clobber
		Rewrites log file
	.EXAMPLE
		"Importing ServerManager Module..." | Add-RbaLogEntry -Severity ([Severity]::Info)
	.EXAMPLE
		Add-LogEntry  -ModuleName "MyfileName" -FunctionName "MyFunction"  -LogFileName "c:\temp\mylog.log" -Severity "Warning" -Message "This is a sample message"
	#>
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $Severity,
		
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $Message,
		
		[Parameter(Mandatory=$false)]
		[switch] $Clobber=$false,

		[Parameter(Mandatory=$false)]
		[switch] $NoConsoleOutput=$false
   	)

    $callStack = Get-PSCallStack
    $moduleName = $callStack[1].Location.Split(":")[0]
    
    $callStack[1].Location.Split(":")[1].Trim() -imatch '(\d+)' | Out-null
    $lineNumber = $matches[0]
    
    $logFileName = [string]::Format("{0}.log",$callStack[1].ScriptName)
    $functionName = $callStack[1].Command
    
	if ($Clobber)
	{
		[System.IO.FileStream] $fs = New-Object System.IO.FileStream($LogFileName,[System.IO.FileMode]::Create)
	}
	else
	{
		[System.IO.FileStream] $fs = New-Object System.IO.FileStream($LogFileName,[System.IO.FileMode]::Append)
	}

	[System.IO.StreamWriter] $sw = New-Object System.IO.StreamWriter($fs,[System.Text.Encoding]::UTF8)
	
	[string]$FormatedLine = [string]::Format("{0}|{1}|{2}|{3}|{4}|{5}",[datetime]::Now,$ModuleName,$FunctionName,$lineNumber,$Severity,$Message)
	$sw.WriteLine($FormatedLine)
	$sw.Dispose()
	$fs.Dispose()
	
	if (!($NoConsoleOutput))
	{
		Write-RbaScreenMessage -Severity $Severity -Message $FormatedLine
	}
}

function Write-RbaScreenMessage
{
	<#
	.SYNOPSIS
	   	Outputs messages to host console
	.DESCRIPTION
	   	Outputs messages to host console
	.PARAMETER Message
		Message to output
	.PARAMETER Severity
		Severity string, which can be obtained from severity enum (Info, Warn, Error)
	#>
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $Severity,
        
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $Message
   	)
	
	switch ($Severity)
	{
		"Info"
			{
				Write-Host $Message -ForegroundColor Cyan
			}
		"Warn"
			{
				Write-Host $Message -ForegroundColor Yellow
			}
		"Error"
			{
				Write-Host $Message -ForegroundColor White -BackgroundColor Red
			}
	}
	
}