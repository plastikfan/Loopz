
function Show-Signals {
  param(
    [Parameter()]
    [System.Collections.Hashtable]$SourceSignals = $global:Loopz.Signals,

    [Parameter()]
    [System.Collections.Hashtable]$Custom = $global:Loopz.CustomSignals
  )
  $result = $SourceSignals.Clone();

  if ($Custom -and ($Custom.Count -gt 0)) {
    $Custom.GetEnumerator() | ForEach-Object {
      try {
        $result[$_.Key] = $_.Value;
      }
      catch {
        Write-Error "Skipping custom signal: '$($_.Key)'";
      }
    }
  }

  [System.Collections.Hashtable]$collection = @{}
  $result.GetEnumerator() | ForEach-Object {

    $collection[$_.Name] = [PSCustomObject]@{
      Label  = $_.Value[0];
      Icon   = $_.Value[1];
      Length = $_.Value[1].Length 
    }
  }

  # result is array, because of the sort
  #
  $result = $collection.GetEnumerator() | Sort-Object -Property Name;

  return $result;
}