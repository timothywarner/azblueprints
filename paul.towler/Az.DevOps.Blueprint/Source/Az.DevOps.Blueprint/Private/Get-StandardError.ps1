function Get-StandardError
{
	<#
	.SYNOPSIS
		Error Message

	.DESCRIPTION
		Generates a standard error response

	.PARAMETER Exception
		Error Exception Object
	#>

	param
	(
		[Parameter(Mandatory=$true)]
		$Exception
	)

	Write-Output "An error occurred - please check rights or parameters for proper configuration and try again"
	Write-Output "======================================================================="
	Write-Output "Specific Error is: "
	Write-Output "$($Exception)"
	#Exit 1
}