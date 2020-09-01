function New-AzDevOpsBlueprintVariableGroup
{
	<#
	.SYNOPSIS
		Creates a Variable Group in a nominated Azure DevOps Project

	.DESCRIPTION
		The Variable Group created, contains the a group of variables detected from the Blueprint Parameters

	.PARAMETER Json
		A Hashtable containing Json information used to create the Variable Group

	.PARAMETER VariableGroups
		An Object containing all the Variable Groups in the Azure DevOps Project

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
	#>

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
	param
	(
		[Parameter(Mandatory=$true)]
		[hashtable]$Json,

		[Parameter(Mandatory=$true)]
		[object]$VariableGroups,

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

	# Variables
	$DevOpsHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$DevOpsPAT"))}

	if ($json.variables.count -ge 1 -and $PSCmdlet.ShouldProcess($json, 'Proceed.'))
	{
		if ($Id = ($VariableGroups | Where-Object Name -eq $json.Name).id)
		{
			$uri = "{0}{1}/_apis/distributedtask/variablegroups/{2}?api-version={3}" -f $DevOpsUri, $DevOpsProject, $id, $DevOpsApiVersion
			$body = $json | ConvertTo-Json
			$null = Invoke-RestMethod -Uri $uri -Method PUT -Headers $DevOpsHeader -Body $body -ContentType "application/json" -ErrorAction Stop
			Write-Output "SUCCESS! Variable Group '$($json.Name)' has been updated in Azure DevOps"
		} else
		{
			$uri = "{0}{1}/_apis/distributedtask/variablegroups?api-version={2}" -f $DevOpsUri, $DevOpsProject, $DevOpsApiVersion
			$body = $json | ConvertTo-Json
			$null = Invoke-RestMethod -Uri $uri -Method POST -Headers $DevOpsHeader -Body $body -ContentType "application/json" -ErrorAction Stop
			Write-Output "SUCCESS! Variable Group '$($json.Name)' has been created in Azure DevOps"
		}
	}
}