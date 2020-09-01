function Get-AzDevOpsBlueprintVariableGroups
{
	<#
	.SYNOPSIS
		Get Azure DevOps Variable Group or Groups

	.PARAMETER Name
		A string containing the name of a variable group to target. By default all Variable Groups are returned unless the a Variable Group is named

	.PARAMETER DevOpsUri
		A string containing the Azure DevOps Project Uri. This is the value assigned the Azure DevOps predefined variable 'System.TeamFoundationCollectionUri'. See https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml#system-variables
		e.g. https://dev.azure.com/fabrikamfiber/

	.PARAMETER DevOpsProject
		A string containing the Name of Azure DevOps Project. This is the value assigned the Azure DevOps predefined variable 'System.TeamProject'. See https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml#system-variables
		e.g. myProject

	.PARAMETER DevOpsPAT
		A string containing the Azure DevOps Person Access Token required to communicate with the Azure DevOps API

	.PARAMETER DevOpsApiVersion
		A string containing the Azure DevOps API Version. Defaults to 5.0-preview.1

	.EXAMPLE
		Get all Variable Groups for an Azure DevOps Project
		Get-AzDevOpsBlueprintVariableGroups `
			-DevOpsUri $env:SYSTEM_TEAMFOUNDTIONCOLLECTIONURI `
			-DevOpsProject $env:SYSTEM_TEAMPROJECT `
			-DevOpsPAT $env:SYSTEM_ACCESSTOKEN

	.EXAMPLE
		Get a Variable Group for an Azure DevOps Project
		Get-AzDevOpsBlueprintVariableGroups `
			-Name TEST-Variable-Group `
			-DevOpsUri $env:SYSTEM_TEAMFOUNDTIONCOLLECTIONURI `
			-DevOpsProject $env:SYSTEM_TEAMPROJECT `
			-DevOpsPAT $env:SYSTEM_ACCESSTOKEN
	#>

	[CmdletBinding(DefaultParameterSetName = 'AllScope')]
	param
	(
		[Parameter(Mandatory=$false, ParameterSetName = 'ByName')]
		[ValidateNotNull()]
		[string]$Name,

		[Parameter(Position=1, Mandatory=$true)]
		[ValidateNotNull()]
		[string]$DevOpsUri,

		[Parameter(Position=1, Mandatory=$true)]
		[ValidateNotNull()]
		[string]$DevOpsProject,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$DevOpsPAT,

		[Parameter(Mandatory=$false)]
		[string]$DevOpsApiVersion = "5.0-preview.1"
	)

	try
	{
		# Checking if Commandlet is running on Azure DevOps
		if (!$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
			Write-Warning "It appears you are not running this command in Azure DevOps."
			Write-Warning "This command will still work, but is designed as a job in Azure DevOps. See https://dev.azure.com/paulrtowler/Az.DevOps.Blueprint for more information.`r`n"
		}

		# variables
		$DevOpsHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$DevOpsPAT"))}
		$getVarGrpsUri = "{0}{1}/_apis/distributedtask/variablegroups?api-version={2}" -f $DevOpsUri, $DevOpsProject, $DevOpsApiVersion

		$results = (Invoke-RestMethod -Uri $getVarGrpsUri -Method GET -Headers $DevOpsHeader).value

		if ($Name)
		{ $results = $results | Where-Object Name -eq $Name }

		return $results
	}
	catch
	{
		if ($_.ErrorDetails.Message) {$ErrDetails = $_.ErrorDetails.Message } else {$ErrDetails = $_}
		Get-StandardError -Exception $($ErrDetails)
	}
}