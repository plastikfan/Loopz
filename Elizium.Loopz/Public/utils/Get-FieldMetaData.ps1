
function Get-FieldMetaData {
  param(
    [PSCustomObject[]]$Data
  )
  [hashtable]$fieldMetaData = @{}

  # Just look at the first row, so we can see each field
  #
  foreach ($field in $Data[0].psobject.properties.name) {
    $fieldMetaData[$field] = @{
      FieldName = $field;
      # !array compound statement: => .$field
      # Note, we also add the field name to the collection, because the field name
      # might be larger than any of the field values
      # 
      Max       = Get-LargestLength $($Data.$field + $field);
      Type      = $Data[0].$field.GetType();
    }
  }

  return $fieldMetaData;
}