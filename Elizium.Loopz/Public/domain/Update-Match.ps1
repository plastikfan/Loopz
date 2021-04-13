﻿
function Update-Match {

  <#
  .NAME
    Update-Match

  .SYNOPSIS
    The core update match action function principally used by Rename-Many. Updates
  $Pattern match in it's current location.

  .DESCRIPTION
    Returns a new string that reflects updating the specified $Pattern match.
    First Update-Match, removes the Pattern match from $Value. This makes the With and
  Copy match against the remainder ($patternRemoved) of $Value. This way, there is
  no overlap between the Pattern match and $With and it also makes the functionality more
  understandable for the user. NB: Pattern only tells you what to remove, but it's the
  With, Copy and Paste that defines what to insert. The user should not be using named
  capture groups in Copy rather, they should be defined inside $Paste and referenced
  inside Paste.

  .PARAMETER Copy
    Regular expression string applied to $Value (after the $Pattern match has been removed),
  indicating a portion which should be copied and re-inserted (via the $Paste parameter;
  see $Paste or $With). Since this is a regular expression to be used in $Paste/$With, there
  is no value in the user specifying a static pattern, because that static string can just be
  defined in $Paste/$With. The value in the $Copy parameter comes when a generic pattern is
  defined eg \d{3} (is non static), specifies any 3 digits as opposed to say '123', which
  could be used directly in the $Paste/$With parameter without the need for $Copy. The match
  defined by $Copy is stored in special variable ${_p} and can be referenced as such from
  $Paste and $With.

  .PARAMETER CopyOccurrence
    Can be a number or the letters f, l
  * f: first occurrence
  * l: last occurrence
  * <number>: the nth occurrence

  .PARAMETER Diagnose
    switch parameter that indicates the command should be run in WhatIf mode. When enabled
  it presents additional information that assists the user in correcting the un-expected
  results caused by an incorrect/un-intended regular expression. The current diagnosis
  will show the contents of named capture groups that they may have specified. When an item
  is not renamed (usually because of an incorrect regular expression), the user can use the
  diagnostics along side the 'Not Renamed' reason to track down errors. When $Diagnose has
  been specified, $WhatIf does not need to be specified.

  .PARAMETER Paste
    Formatter parameter for Update operations. Can contain named/numbered group references
  defined inside regular expression parameters, or use special named references $0 for the whole
  Pattern match and ${_c} for the whole Copy match.

  .PARAMETER Pattern
    Regular expression string that indicates which part of the $Value that either needs
  to be moved or replaced as part of overall rename operation. Those characters in $Value
  which match $Pattern, are removed.

  .PARAMETER PatternOccurrence
    Can be a number or the letters f, l
  * f: first occurrence
  * l: last occurrence
  * <number>: the nth occurrence

  .PARAMETER Value
    The source value against which regular expressions are applied.

  .PARAMETER With
    This is a NON regular expression string. It would be more accurately described as a formatter,
  similar to the $Paste parameter. Defines what text is used as the replacement for the $Pattern
  match. Works in concert with $Relation (whereas $Paste does not). $With can reference special
  variables:
  * $0: the pattern match
  * ${_c}: the copy match
  When $Pattern contains named capture groups, these variables can also be referenced. Eg if the
  $Pattern is defined as '(?<day>\d{1,2})-(?<mon>\d{1,2})-(?<year>\d{4})', then the variables
  ${day}, ${mon} and ${year} also become available for use in $With or $Paste.
  Typically, $With is static text which is used to replace the $Pattern match.

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string]$Value,

    [Parameter(Mandatory)]
    [System.Text.RegularExpressions.RegEx]$Pattern,

    [Parameter()]
    [ValidateScript( { $_ -ne '0' })]
    [string]$PatternOccurrence = 'f',

    [Parameter()]
    [System.Text.RegularExpressions.RegEx]$Copy,

    [Parameter()]
    [ValidateScript( { $_ -ne '0' })]
    [string]$CopyOccurrence = 'f',

    [Parameter()]
    [string]$With,

    [Parameter()]
    [string]$Paste,

    [Parameter()]
    [switch]$Diagnose
  )

  function update-single {
    param (
      [Parameter()]
      [System.Text.RegularExpressions.Match]$pMatch,

      [Parameter()]
      [string]$src,

      [Parameter()]
      [string]$pOcc,

      [Parameter()]
      [RegEx]$pRegEx
    )
  }

  [string]$failedReason = [string]::Empty;
  [PSCustomObject]$diagnostics = [PSCustomObject]@{
    Named = @{}
  }

  [string]$pOccurrence = $PSBoundParameters.ContainsKey('PatternOccurrence') `
    ? $PatternOccurrence : 'f';

  [string]$capturedPattern, $patternRemoved, [System.Text.RegularExpressions.Match]$patternMatch = `
    Split-Match -Source $Value -PatternRegEx $Pattern `
    -Occurrence $pOccurrence;

  if (-not([string]::IsNullOrEmpty($capturedPattern))) {
    [Hashtable]$patternCaptures = get-Captures -MatchObject $patternMatch;
    if ($Diagnose.ToBool()) {
      $diagnostics.Named['Pattern'] = $patternCaptures;
    }
    [Hashtable]$copyCaptures = @{}

    [string]$copyText = if ($PSBoundParameters.ContainsKey('Copy')) {
      [string]$capturedCopy, $null, [System.Text.RegularExpressions.Match]$copyMatch = `
        Split-Match -Source $patternRemoved -PatternRegEx $Copy `
        -Occurrence ($PSBoundParameters.ContainsKey('CopyOccurrence') ? $CopyOccurrence : 'f');

      if (-not([string]::IsNullOrEmpty($capturedCopy))) {
        $copyCaptures = get-Captures -MatchObject $copyMatch;
        if ($Diagnose.ToBool()) {
          $diagnostics.Named['Copy'] = $copyCaptures;
        }
      }
      else {
        $failedReason = 'Copy Match';
      }
      $capturedCopy;
    }

    [string]$replaceWith = if ($PSBoundParameters.ContainsKey('With')) {
      # Still need to resolve group references inside With
      #
      # [string]$withText = Update-GroupRefs -Source $With -Captures $patternCaptures;
      # $withText = Update-GroupRefs -Source $withText -Captures $copyCaptures;
      $With;
    }
    else {
      [string]::Empty;
    }

    if ([string]::IsNullOrEmpty($failedReason)) {
      if ($PSBoundParameters.ContainsKey('Paste')) {
        [string]$format = $Paste.Replace('${_c}', $copyText).Replace(
          '${_w}', $replaceWith).Replace('$0', $capturedPattern);
      }
      else {
        # Just do a straight swap of the pattern match for the replaceWith
        #
        [string]$format = $replaceWith;
      }

      # Resolve all named/numbered group references
      #
      $format = Update-GroupRefs -Source $format -Captures $patternCaptures;
      $format = Update-GroupRefs -Source $format -Captures $copyCaptures;

      [string]$result = $Pattern.Replace($Value, $format, 1, $patternMatch.Index);
    }
  }
  else {
    $failedReason = 'Pattern Match';
  }

  [boolean]$success = $([string]::IsNullOrEmpty($failedReason));
  if (-not($success)) {
    $result = $Value;
  }

  [PSCustomObject]$updateResult = [PSCustomObject]@{
    Payload         = $result;
    Success         = $success;
    CapturedPattern = $capturedPattern;
  }

  if (-not([string]::IsNullOrEmpty($failedReason))) {
    $updateResult | Add-Member -MemberType NoteProperty -Name 'FailedReason' -Value $failedReason;
  }

  if ($Diagnose.ToBool() -and ($diagnostics.Named.Count -gt 0)) {
    $updateResult | Add-Member -MemberType NoteProperty -Name 'Diagnostics' -Value $diagnostics;
  }

  return $updateResult;
} # Update-Match

