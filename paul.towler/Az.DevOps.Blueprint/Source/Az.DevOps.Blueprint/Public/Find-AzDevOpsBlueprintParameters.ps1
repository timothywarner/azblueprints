function Find-AzDevOpsBlueprintParameters
{
	<#
	.SYNOPSIS
		Matches different types of Blueprint parameters with Variables in Azure DevOps

	.DESCRIPTION
		Finds Blueprint Parameters in a Raw Blueprint and matches Resource Group, Parameters and Secure Parameters with Variables already defined in Azure DevOps

	.PARAMETER Type
		A string containing the Type of Parameter to match. There are two options
		1. ResourceGroup
		2. Parameters

	.PARAMETER RawBlueprint
		A PSCustomObject containing the raw data for a Blueprint.

	.PARAMETER Location
		A String containing the Location if a Resource Group parameter is required

	.EXAMPLE 1
		Match Blueprint Resource Group parameters
		Find-AzDevOpsBlueprintParameters `
			-Type ResourceGroups `
			-RawBlueprint (Get-Content -Raw '$($env:BUILD_SOURCESDIRECTORY)/myRepo/Blueprints/Small_ISO27001_Shared-Services/Small_ISO27001_Shared-Services.json' | ConvertFrom-Json)
			-Location "australiaeast"

	.EXAMPLE 2
		Match Blueprint Parameters
		Find-AzDevOpsBlueprintParameters `
			-Type Parameters `
			-RawBlueprint (Get-Content -Raw '$($env:BUILD_SOURCESDIRECTORY)/myRepo/Blueprints/Small_ISO27001_Shared-Services/Small_ISO27001_Shared-Services.json' | ConvertFrom-Json)

	.EXAMPLE 3
		Match Blueprint Secure Parameters
		Find-AzDevOpsBlueprintParameters `
			-Type SecureParameters `
			-RawBlueprint (Get-Content -Raw '$($env:BUILD_SOURCESDIRECTORY)/myRepo/Blueprints/Small_ISO27001_Shared-Services/Small_ISO27001_Shared-Services.json' | ConvertFrom-Json)

	#>

	[CmdletBinding(DefaultParameterSetName="Default")]
	[OutputType([Hashtable])]
	param
	(
		[Parameter(Mandatory=$true)]
		[ValidateSet("ResourceGroups","Parameters","SecureParameters")]
		[String]$Type,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[PSCustomObject]$RawBlueprint,

		[Parameter(ParameterSetName="ResourceGroups", Mandatory=$true)]
		[string]$Location
	)

	# Checking if Commandlet is running on Azure DevOps
	if (!$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
		Write-Warning "It appears you are not running this command inside a job in Azure DevOps."
		Write-Warning "This command is designed to run as a job in Azure DevOps. See https://dev.azure.com/paulrtowler/Az.DevOps.Blueprint for more information."
		Write-Warning "Exiting...`r`n" -ErrorAction Stop
	}

	switch ($Type)
	{
		"ResourceGroups"
		{
			$resourceGroups = @{}
			foreach ($rg in $rawBlueprint.properties.resourceGroups.PSObject.Properties)
			{
				foreach ($envVariable in (Get-ChildItem env: | Where-Object Name -like "RG_*"))
				{
					$tmp = $rg.Name -replace "-", ""
					$tmpEnv = $envVariable.Name -replace "RG_", ""
					$tmpValue = $null
					if ($tmp -eq $tmpEnv)
					{
						if ([string]::IsNullOrWhitespace($rg.Value.Name))
						{
							$tmpObject = @{}
							(ConvertFrom-Json $envVariable.value -ErrorAction Stop).psobject.properties | Foreach-Object { $tmpObject[$_.Name] = $_.Value }
							$resourceGroups.Add($rg.Name, $tmpObject)
						} else
						{
							# Adding to resourceGroups
							$resourceGroups.Add($rg.Name, @{name = $rg.Name; location = $Location})
						}
					}
				}
			}

			if ($resourceGroups) {	return $resourceGroups	}
		}

		"Parameters"
		{
			$params = @{}
			foreach ($param in $rawBlueprint.properties.parameters.PSObject.Properties)
			{
				foreach ($envVariable in (Get-ChildItem env: | Where-Object Name -like "BP_*"))
				{
					$tmp = $param.Name -replace "-", ""
					$tmpEnv = $envVariable.Name -replace "BP_", ""
					$tmpValue = $null
					if ($tmp -like "*$($tmpEnv)*")
					{
						switch ($param.Value.type)
						{
							"string"
							{
								if ([string]::IsNullOrWhitespace($envVariable.value))
								{
									$tmpValue = ""
									$params.Add($param.Name, $tmpValue)
								} else
								{
									$params.Add($param.Name, $envVariable.value)
								}
							}

							"array"
							{
								if ([string]::IsNullOrWhitespace($envVariable.value))
								{
									$tmpValue = @()
									$params.Add($param.Name, $tmpValue)
								} else
								{
									$tmpValue = $envVariable.value -split ","
									$params.Add($param.Name, $tmpValue)
								}
							}

							"object"
							{
								if ([string]::IsNullOrWhitespace($envVariable.value))
								{
									$tmpValue = @()
									$params.Add($param.Name, $tmpValue)
								} else
								{
									$tmpValue = @{}
									(ConvertFrom-Json $envVariable.value -ErrorAction Stop).psobject.properties | Foreach-Object { $tmpValue[$_.Name] = $_.Value }
									$params.Add($param.Name, $tmpValue)
								}
							}

							"int"
							{	$params.Add($param.Name, [int]$envVariable.value)	}

							"secureString"
							{
								if ($envVariable.Value.Contains('Microsoft.KeyVault/vaults'))
								{	continue	} else
								{	$params.Add($param.Name, $envVariable.value)	}
							}

							default
							{	$params.Add($param.Name, $envVariable.value)	}
						}
					}
				}

				# Checking for Variables that require a secret. These variables are defined as an Input Enviromment variable on the PowerShell Task and use a Azure DevOps Secret Variable
				foreach ($envVariable in (Get-ChildItem env: | Where-Object Name -like "BPS_*"))
				{
					$tmp = $param.Name -replace "-", ""
					$tmpEnv = $envVariable.Name -replace "BPS_", ""
					$tmpValue = $null
					if ($tmp -like "*$($tmpEnv)*")
					{
						if ([string]::IsNullOrWhitespace($param.Value.defaultValue))
						{
							# Adding to Params
							$params.Add($param.Name, $envVariable.value)
						}
					}
				}
			}

			if ($params) {	return $params	}
		}

		"SecureParameters"
		{
			$secureParams = @{}
			foreach ($param in $rawBlueprint.properties.parameters.PSObject.Properties)
			{
				foreach ($envVariable in (Get-ChildItem env: | Where-Object Name -like "BP_*"))
				{
					$tmp = $param.Name -replace "-", ""
					$tmpEnv = $envVariable.Name -replace "BP_", ""
					$tmpValue = $null
					if ($tmp -like "*$($tmpEnv)*")
					{
						switch ($param.Value.type)
						{
							"secureString"
							{
								if ($envVariable.Value.Contains('Microsoft.KeyVault/vaults'))
								{
									$tmpValue = $envVariable.Value -split ","
									$tmpValue = @{keyVaultId=$tmpValue[0];secretName=$tmpValue[1]}
									$secureParams.Add($param.Name, $tmpValue)
								} else
								{
									$secureParams.Add($param.Name, $envVariable.value)
								}
							}
						}
					}
				}
			}

			if ($secureParams) {	return $secureParams	}
		}
	}
}