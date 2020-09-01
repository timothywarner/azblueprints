function Remove-AzDevOpsBlueprintAssignment
{
	<#
	.SYNOPSIS
		Removes a Blueprint Assignment in Azure

	.DESCRIPTION
		Removes a Blueprint that was Assigned to a Management Group / Subscription

	.PARAMETER Blueprint
		An Object containing the Blueprint information.

	.PARAMETER AssignmentName
		A string containing the Assignment Name of the Blueprint

	.EXAMPLE Remove Assignment from a Subscription
		$Context = Get-AzContext
		$Blueprint = Get-AzBlueprintAssignment -Name "Assignment-Small_ISO27001_Shared-Services" -Subscription $Context.Subscription.Id
		Remove-AzDevOpsBlueprintAssignment `
			-Blueprint $Blueprint
			-AssignmentName 'Assignment-Small_ISO27001_Shared-Services.json'

	.EXAMPLE Remove Assignment from a Management Group and Delete Resource Groups
		$ManagementGroup = Get-AzManagementGroup | Where-Object DisplayName -eq "Development"
		$Blueprint = Get-AzBlueprintAssignment -Name "Assignment-Small_ISO27001_Shared-Services" -ManagementGroupId $ManagementGroup.Name
		Remove-AzDevOpsBlueprintAssignment `
			-Blueprint $Blueprint
			-AssignmentName 'Assignment-Small_ISO27001_Shared-Services.json' `
			-Test $true
	#>

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
	param
	(
		[parameter(Mandatory=$true)]
		$Blueprint,

		[parameter(Mandatory=$true)]
		[string]$AssignmentName
	)

	function Confirm-UnAssignment
	{
		param
		(
			[parameter(Mandatory=$true)]
			$Blueprint,

			[parameter(Mandatory=$true)]
			$AssignmentName
		)

		Do
		{
			switch ($Blueprint)
			{
				{$Blueprint.SubscriptionId}
				{
					$Assignment = Get-AzBlueprintAssignment -Name $AssignmentName -Subscription $Blueprint.SubscriptionId -ErrorAction SilentlyContinue
					break
				}

				{$Blueprint.ManagementGroupId}
				{
					$Assignment = Get-AzBlueprintAssignment -Name $AssignmentName -ManagementGroupId $Blueprint.ManagementGroupId -ErrorAction SilentlyContinue
					break
				}
			}

			if ($Assignment.ProvisioningState) {	Write-Output $Assignment.ProvisioningState	}
			Start-Sleep -Seconds 5
		} Until ($null -eq $Assignment)

		Write-Output "SUCCESS! Blueprint '$($Blueprint.Name)' has been Unassigned"
	}

	try
	{
		# Checking if Commandlet is running on Azure DevOps
		if (!$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
			Write-Warning "It appears you are not running this command in Azure DevOps."
			Write-Warning "This command will still work, but is designed as a job in Azure DevOps. See https://dev.azure.com/paulrtowler/Az.DevOps.Blueprint for more information.`r`n"
		}

		# Get Assignment
		# Assign Blueprint
		Write-Output "`r`nUnassigning Blueprint '$($Blueprint.Name)'....."
		switch ($Blueprint)
		{
			{$Blueprint.SubscriptionId}
			{
				$Assignment = Get-AzBlueprintAssignment -Name $AssignmentName -Subscription $Blueprint.SubscriptionId -ErrorAction SilentlyContinue

				if ($Assignment -and $PSCmdlet.ShouldProcess($AssignmentName, 'Proceed.'))
				{
					Remove-AzBlueprintAssignment -Name $Assignment.Name -Subscription $Blueprint.SubscriptionId -ErrorAction SilentlyContinue
					Confirm-UnAssignment -Blueprint $Blueprint -AssignmentName $AssignmentName
				} else
				{
					Write-Output "Assignment '$($AssignmentName)' was not found."
				}
				break
			}

			{$Blueprint.ManagementGroupId}
			{
				$Assignment = Get-AzBlueprintAssignment -Name $AssignmentName -ManagementGroupId $Blueprint.ManagementGroupId -ErrorAction SilentlyContinue

				if ($Assignment -and $PSCmdlet.ShouldProcess($AssignmentName, 'Proceed.'))
				{
					Remove-AzBlueprintAssignment -Name $Assignment.Name -ManagementGroupId $Blueprint.ManagementGroupId -ErrorAction SilentlyContinue
					Confirm-UnAssignment -Blueprint $Blueprint -AssignmentName $AssignmentName
				} else
				{
					Write-Output "Assignment '$($AssignmentName)' was not found."
				}
				break
			}
		}
	}
	catch
	{
		if ($_.ErrorDetails.Message) {$ErrDetails = $_.ErrorDetails.Message } else {$ErrDetails = $_}
		if ($_.Message) {$ErrDetails = $_.Message } else {$ErrDetails = $_}
		Get-StandardError -Exception $($ErrDetails)
	}
}