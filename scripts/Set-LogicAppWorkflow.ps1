#
# This updates workflow definition in Logic App
#

Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $LogicAppName,
    [string] [Parameter(Mandatory=$true)] $DefinitionFile,
    [string] [Parameter(Mandatory=$false)] $ParameterFile = $null,
    [hashtable] [Parameter(Mandatory=$false)] $ParameterObject = $null
)

$params = @{}

# Sets parameters from the parameter file, if provided.
if ([String]::IsNullOrWhiteSpace($ParameterFile) -eq $false) {
    (Get-Content $ParameterFile -Encoding UTF8 -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object {
        if ($_.Value.GetType().BaseType.Name -eq "Array") {
            $params[$_.Name] = [String]::Join(",", $_.Value)
        } else {
            $params[$_.Name] = $_.Value
        }
    }
}

# Overwrites existing parameters from the parameter object, if provided.
if ($ParameterObject -ne $null) {
    $ParameterObject.Keys | ForEach-Object {
        if ($ParameterObject[$_].GetType().BaseType.Name -eq "Array") {
            $params[$_] = [String]::Join(",", $ParameterObject[$_])
        } else {
            $params[$_] = $ParameterObject[$_]
        }
    }
}

if ($params.Count -eq 0) {
    Write-Host "No parameter found" -ForegroundColor Red -BackgroundColor Yellow

    throw "No parameter found"
}

# Reads the workflow definition.
$raw = Get-Content $DefinitionFile -Encoding UTF8 -Raw

# Updates the definition by substituting placeholders with actual values.
$params.Keys | ForEach-Object {
    $raw = $raw -replace $("{{" + $_ + "}}"), $params[$_]
}

$workflow = $raw | ConvertFrom-Json

# Gets the Logic App instance.
$logicApp = Get-AzureRmResource `
            -ResourceGroupName $ResourceGroupName `
            -ResourceName $LogicAppName `
            -ResourceType Microsoft.Logic/workflows

# Updates the Logic App instance.
$logicApp.Properties.state = $workflow.state
$logicApp.Properties.parameters = $workflow.parameters
$logicApp.Properties.definition = $workflow.definition

$result = $logicApp | Set-AzureRmResource -Force

Remove-Variable params
Remove-Variable raw
Remove-Variable workflow
Remove-Variable logicApp
Remove-Variable result
