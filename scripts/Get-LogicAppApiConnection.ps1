#
# This gets the API connection details used for Logic App
#

Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $ResourceName
)

$apicon = Get-AzureRmResource `
          -ResourceGroupName $ResourceGroupName `
          -ResourceName $ResourceName `
          -ResourceType Microsoft.Web/connections

$result = @{ `
    Id = $apicon.Properties.api.id; `
    ConnectionId = $apicon.ResourceId; `
    ConnectionName = $apicon.ResourceName; `
}

$result

Remove-Variable result
Remove-Variable apicon
