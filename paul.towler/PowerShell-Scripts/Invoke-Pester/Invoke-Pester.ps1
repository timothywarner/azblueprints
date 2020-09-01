[CmdLetBinding()]
param
( 
	[Parameter(Mandatory=$true)]
	[string] $Path,

	[Parameter(Mandatory=$true)]
	[hashtable] $Parameters,

	[Parameter(Mandatory=$true)]
	[string] $OutputFile,

	[Parameter(Mandatory=$true)]
	[Object] $Modules
)

#Get Parent Directory
$ParentPath = Split-Path -Parent $PSScriptRoot

# Load Modules Function
. $ParentPath/Import-Modules/Import-Modules.ps1

foreach ($module in $Modules)
{
	$moduleVersion = (Get-Module $module.Name -ListAvailable -ErrorAction SilentlyContinue).version
	Import-Modules -Module $module.Name -ModuleVersion $moduleVersion -Version $module.Version -Type $module.Type
}

try
{
	if ((Get-Module Pester -ErrorAction SilentlyContinue).version | Where-Object Major -ge 5)
	{
		# No Support for Parameters in Test File ??? Use wisely! See https://github.com/pester/Pester
		Invoke-Pester `
		-Path $Path `
		-PassThru `
		-CI `
		-Output Detailed
	} else
	{
		Invoke-Pester `
		-Script @{ Path = $Path; Parameters = $Parameters } `
		-PassThru `
		-OutputFile $OutputFile `
		-OutputFormat NUnitXml
	}
} catch
{ throw $_ }