<#
	.SYNOPSIS
		A companion for Az.Blueprint Module specifically designed to assist with Azure Blueprint deployments via Azure DevOps

	.DESCRIPTION
		Provides cmdlets to allow Azure DevOps:
		- Analyse a Blueprint for Resource Groups, Parameters and Secure Parameters that require values
		- Analyse a Blueprint for Resource Groups, Parameters and Secure Parameters that do not require values
       	- Create Azure DevOps Variable Groups and Variables for Resource Groups, Parameters and Secure Parameters found in a Blueprint
		- Matches Blueprint Resource Groups, Parameters and Secure Parameters with Azure DevOps Variables When Assigning a Blueprint in a Pipeline
#>

# Load Module settings file
try
{	$script:SETTINGS = (Get-Content (Join-Path $PSScriptRoot 'Settings.json') | ConvertFrom-Json) } catch
{	throw 'Could not load settings.json file.'	}

# Get public and private function defenition files.
# Sort to make sure files that start with '_' get loaded first
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private -Recurse -Filter "*.ps1") | Sort-Object Name
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public -Recurse -Filter "*.ps1") | Sort-Object Name

# Dots source the private files
foreach ($import in $Private)
{
	try
	{
		. $import.fullName
		Write-Verbose -Message ("Imported private function {0}" -f $import.fullName)
	} catch
	{
		Write-Error -Message ("Failed to import private function {0}: {1}" -f $import.fullName, $_)
	}
}

# Dots source the public files
foreach ($import in $Public)
{
	try
	{
		. $import.fullName
		Write-Verbose -Message ("Imported public function {0}" -f $import.fullName)
	} catch
	{
		Write-Error -Message ("Failed to import public function {0}: {1}" -f $import.fullName, $_)
	}
}

Export-ModuleMember -Function $Public.BaseName