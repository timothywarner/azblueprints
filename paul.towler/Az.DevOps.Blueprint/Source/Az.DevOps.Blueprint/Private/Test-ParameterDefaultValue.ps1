function Test-ParameterDefaultValue
{
	<#
	.SYNOPSIS
		Checks the Default Value of Blueprint Parameter

	.DESCRIPTION
		Depending on the type of Blueprint Parameter, the Default Value is modified and returned as a string.

	.PARAMETER Value
		A PSCustomObject containing the Blueprint Parameter information

	.EXAMPLE
		Test-ParameterDefaultValue `
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
		$Value
	)

	if ($Value.type -eq "array")
	{
		$tmpValue = $Value.defaultValue -join "`n"
		$tmpValue = $tmpValue -replace "`n", ","
	} elseif ($Value.type -eq "object")
	{
		$tmpValue = ($Value.defaultValue | ConvertTo-Json) -replace "`n", ""
		$tmpValue = $tmpValue -replace " ", ""
	} else {
		$tmpValue = $Value.defaultValue
	}

	return $tmpValue.toString()
}