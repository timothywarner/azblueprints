function Import-Modules
{
	param
	(
		$Module,
		$ModuleVersion,
		$Version,
		$Type
	)

	switch ($ModuleVersion)
	{
		{$PSItem -ge $Version -and $Type -eq "Minimum"}
		{
			if ((Get-Module $Module -ErrorAction SilentlyContinue).version -ne $Version)
			{	
				Write-Output "Importing Module '$($Module)' with a Minimum Version of '$Version'"
				Import-Module $Module -MinimumVersion $Version -Force -Global	} else
			{	Write-Output "Module '$($Module)' Version '$Version' is already Imported"	}
			break
		}

		default
		{
			switch ($Type)
			{
				"Required"
				{
					Write-Output "Installing and Importing Module '$($Module)' with the Required Version '$Version'"
					if (Get-Module -Name $Module) { Remove-Module -Name $Module -Force  }
					Install-Module -Name $Module -RequiredVersion $Version -Force -Scope CurrentUser
					Import-Module -Name $Module -RequiredVersion $Version -Force -Global
					break
				}

				"Minimum"
				{
					Write-Output "Installing and Importing Module '$($Module)' with a Minimum Version of '$Version'"
					if (Get-Module -Name $Module) { Remove-Module -Name $Module -Force  }
					Install-Module -Name $Module -MinimumVersion $Version -Force -Scope CurrentUser
					Import-Module -Name $Module -MinimumVersion $Version -Force -Global
					break
				}
			}
		}
	}
}