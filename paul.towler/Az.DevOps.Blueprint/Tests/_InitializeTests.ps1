$Global:ModuleName = 'Az.DevOps.Blueprint'
$Global:TestsFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:ProjectRoot = Split-Path -Parent $TestsFolder
$Global:ModuleRoot = Join-Path -Path $ProjectRoot -ChildPath "Source" -AdditionalChildPath $ModuleName
$Global:BlueprintsRoot = Join-Path -Path $ProjectRoot -ChildPath "Blueprints"
$Global:ModuleManifestPath = Join-Path -Path $ModuleRoot -ChildPath ('{0}.psd1' -f $ModuleName)

if(!(Get-Module $ModuleName)){
	Import-Module $ModuleRoot -Force
}