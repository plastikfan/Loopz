
function find-MultipleValueFromPipeline {
  [CmdletBinding()]
  [OutputType([array])]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.CommandInfo]$CommandInfo,

    [Parameter(Mandatory)]
    [Syntax]$Syntax
  )

  [System.Management.Automation.CommandParameterSetInfo[]]$paramSets = $commandInfo.ParameterSets;
  [array]$pods = @();

  [scriptblock]$paramIsValueFromPipeline = [scriptblock] {
    [OutputType([boolean])]
    param (
      [Parameter()]
      [PSCustomObject]$row
    )
    return [boolean]$row.PipeValue;
  };

  foreach ($paramSet in $paramSets) {
    [hashtable]$fieldMetaData, [hashtable]$headers, [hashtable]$tableContent = `
      get-ParameterSetTableData -CommandInfo $CommandInfo `
      -ParamSet $paramSet -Syntax $Syntax -Where $paramIsValueFromPipeline;

    if ($tableContent -and ($tableContent.Count -gt 1)) {
      [PSCustomObject]$seed = [PSCustomObject]@{
        ParamSet = $paramSet;
        Params   = $tableContent.Keys;
      }
      $pods += $seed;
    }
  }
  return ($pods.Count -gt 0) ? $pods : $null;
}