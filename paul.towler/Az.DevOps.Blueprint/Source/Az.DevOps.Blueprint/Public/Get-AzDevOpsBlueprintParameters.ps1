function Get-AzDevOpsBlueprintParameters
{
	<#
	.SYNOPSIS
		Determines the Blueprint Parameters and creates two Variable Groups (required/not-required) containing the Variables required to match Parameters in the Blueprint.

	.DESCRIPTION
		The parameters in the Blueprint, follow a pattern where the first part of the parameter matches a Blueprint artifact. For example:
			keyvault_ad-domain-admin-user-password
			artifact | separator | parameter
			keyvault |     _     | ad-domain-admin-user-password

	.PARAMETER InputPath
		A string containing the path to the Blueprint JSON File e.g.
		'C:\Repos\Blueprints\Small_ISO27001_Shared-Services'

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
		Get-AzDevOpsBlueprintParameters `
			-InputPath 'C:\Repos\Blueprints\Small_ISO27001_Shared-Services' `
			-DevOpsUri $env:SYSTEM_TEAMFOUNDTIONCOLLECTIONURI `
			-DevOpsProject $env:SYSTEM_TEAMPROJECT `
			-DevOpsPAT $env:SYSTEM_ACCESSTOKEN

		Result:
			3 x Variable Groups:
			 - BLUEPRINT_Parameters_Required
			 - BLUEPRINT_Parameters_Not_Required
			 - BLUEPRINT_Resource_Groups
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$InputPath,

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
		$VariableGroups = (Invoke-RestMethod -Uri $getVarGrpsUri -Method GET -Header $DevOpsHeader).value
		$rawBlueprint = Get-Content -Path "$($InputPath)\Blueprint.json" | ConvertFrom-Json

		#region Resource Group Parameters
		$json = @{
			variables = @{}
			type = "Vsts"
			name = "BLUEPRINT_Resource_Groups"
			description = "These Variables in Azure DevOps map to Resource Group Parameters in the Blueprint"
		}

		Write-Output "Create these Variables in Azure DevOps for Resource Groups and assign values:"
		foreach ($param in $rawBlueprint.properties.resourceGroups.PSObject.Properties)
		{
			if ([string]::IsNullOrWhitespace($param.Value.Name))
			{
				$key = "RG_$($param.Name)"
				$value = Test-ParameterValue -Value @{type = "resourceGroup"}

				Write-Output "`tName: $($key)"
				Write-Output "`tBlueprint Resource Group: $($param.Name)`r`n"

				$json.variables.Add($key, $value)
			}
		}

		New-AzDevOpsBlueprintVariableGroup `
			-Json $json `
			-VariableGroups $VariableGroups `
			-DevOpsUri $DevOpsUri `
			-DevOpsProject $DevOpsProject `
			-DevOpsPAT $DevOpsPAT
		#endregion

		#region Parameters that need Values
		$json = @{
			variables = @{}
			type = "Vsts"
			name = "BLUEPRINT_Parameters_Required"
			description = "These Variables in Azure DevOps map to Parameters in the Blueprint that need values"
		}

		Write-Output "Create these Variables in Azure DevOps and assign values:"
		foreach ($param in $rawBlueprint.properties.parameters.PSObject.Properties)
		{
			if ([string]::IsNullOrWhitespace($param.Value.defaultValue))
			{
				$key = "BP_$($param.Name -Replace '-','')"
				$value = Test-ParameterValue -Value $param.Value

				Write-Output "`tName: $($key)"
				Write-Output "`tType: $($param.Value.Type)`r`n"

				$json.variables.Add($key, $value)
			}
		}

		New-AzDevOpsBlueprintVariableGroup `
			-Json $json `
			-VariableGroups $VariableGroups `
			-DevOpsUri $DevOpsUri `
			-DevOpsProject $DevOpsProject `
			-DevOpsPAT $DevOpsPAT
		#endregion

		#region Parameters that have Default Values and can be overridden
		$json = @{
			variables = @{}
			type = "Vsts"
			name = "BLUEPRINT_Parameters_Not_Required"
			description = "These Variables in Azure DevOps map to Parameters in the Blueprint that have default values and can be overridden."
		}

		Write-Output "These Variables have Default Values. Create any of these Variable, assign a value to override the Default Value:"
		foreach ($param in $rawBlueprint.properties.parameters.PSObject.Properties)
		{
			if (![string]::IsNullOrWhitespace($param.Value.defaultValue))
			{
				$key = "BP_$($param.Name -Replace '-','')"
				$value = Test-ParameterDefaultValue -Value $param.Value

				Write-Output "`tName: BP_$($param.Name -Replace '-','')"
				Write-Output "`tValue: $($value)"
				Write-Output "`tType: $($param.Value.Type)`r`n"

				$json.variables.Add($key, $value)
			}
		}

		New-AzDevOpsBlueprintVariableGroup `
			-Json $json `
			-VariableGroups $VariableGroups `
			-DevOpsUri $DevOpsUri `
			-DevOpsProject $DevOpsProject `
			-DevOpsPAT $DevOpsPAT
	}
	catch
	{
		if ($_.ErrorDetails.Message) {$ErrDetails = $_.ErrorDetails.Message } else {$ErrDetails = $_}
		Get-StandardError -Exception $($ErrDetails)
	}
}
