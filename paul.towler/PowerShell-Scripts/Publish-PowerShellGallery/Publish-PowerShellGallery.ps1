param
(
	[Parameter(Mandatory=$true)]
	[String] $ModulePath,

	[Parameter(Mandatory=$true)]
	[Object] $Modules,

	[Parameter(Mandatory=$false)]
	$APIKey = $env:KEY
)

# NOTE: $env:KEY is an Azure DevOps secret Variable and must be passed to the PowerShell Task. See https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/powershell?view=azure-devops#arguments

#Get Parent Directory
$ParentPath = Split-Path -Parent $PSScriptRoot

# Load Modules Function
. $ParentPath/Import-Modules/Import-Modules.ps1

# Import Modules
foreach ($module in $Modules)
{
	$moduleVersion = (Get-Module $module.Name -ListAvailable -ErrorAction SilentlyContinue).version
	Import-Modules -Module $module.Name -ModuleVersion $moduleVersion -Version $module.Version -Type $module.Type
}

try
{	Publish-Module -Path $ModulePath -NugetAPIKey $APIKey -Verbose	} catch
{	throw $_	}