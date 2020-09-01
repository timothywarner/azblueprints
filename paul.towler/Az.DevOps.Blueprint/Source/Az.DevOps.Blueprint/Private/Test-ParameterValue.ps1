function Test-ParameterValue
{
	<#
	.SYNOPSIS
		Checks the type of Blueprint Parameter

	.DESCRIPTION
		Determines the type of Blueprint Parameter and returns a description of what the Azure DevOps variable requires as a value.

	.PARAMETER Value
		A PSCustomObject containing the Blueprint Parameter information

	.EXAMPLE
		Test-ParameterValue `
			-Value [PSCustomObject]@{
				type = "string"
				metadata = [PSCustomObject]@{displayName = "app_tshirt-size (WebApp Template)"; description = "What T-Shirt size is required for the Web App"}
				defaultValue = "Medium"
				allowedValues = @("Small", "Medium", "Large")
			}
	#>

	param
	(
		[Parameter(Mandatory=$true)]
		[PSCustomObject]$Value
	)

	switch ($Value.type)
	{
		"array"
		{	$tmpValue = "Needs to be an Array e.g. value1,value2,etc."	}

		"object"
		{ 	$tmpValue = "Needs to be an Object, but as JSON e.g. '{`"key1`": `"value1`", `"key2`": `"value2`"}'"	}

		"int"
		{	$tmpValue = "Needs to be an Int i.e. Integer/Number e.g. 123 etc."	}

		"secureString"
		{	$tmpValue = "Needs to be ReferenceId to a password in a Key Vault e.g. /subscriptions/`$(subscriptionId)/resourceGroups/`$(keyVault.ResourceGroup)/providers/Microsoft.KeyVault/vaults/`$(keyVault),`$(BP_activedirectorydomainservices_addomainadminusername)."	}

		"string"
		{	$tmpValue = "Needs to be an String or Text e.g. This is Text etc."	}

		"resourceGroup"
		{	$tmpValue = "Needs to be an Object, but as JSON e.g. '{`"name`": `"ResourceGroupName`", `"location`": `"azureregion`"}'"	}

		default
		{ 	$tmpValue = ""	}
	}

	return $tmpValue
}