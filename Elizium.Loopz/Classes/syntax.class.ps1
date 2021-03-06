
class Syntax {
  # PsSyntax
  [string]$CommandName;
  [hashtable]$Theme;
  [hashtable]$Signals
  [object]$Krayon;
  [object]$Scribbler;
  [hashtable]$Scheme;

  [string]$ParamNamePattern = "\-(?<name>\w+)";
  [string]$TypePattern = "\<(?<type>[\w\[\]]+)\>";
  [string]$NegativeTypePattern = "(?!\s+\<[\w\[\]]+\>)";

  [PSCustomObject]$Regex;
  [PSCustomObject]$Snippets;
  [PSCustomObject]$Formats;
  [PSCustomObject]$TableOptions;
  [PSCustomObject]$Labels;
  [regex]$NamesRegex;

  [string[]]$CommonParamSet = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction',
    'InformationAction', 'VerboseAction', 'DebugAction', 'ProgressAction',
    'ErrorVariable', 'WarningVariable', 'InformationVariable', 'DebugVariable',
    'VerboseVariable', 'ProgressVariable', 'OutVariable', 'OutBuffer',
    'PipelineVariable');

  [string[]]$ShouldProcessParamSet = @('WhatIf', 'Confirm');
  [string[]]$AllCommonParamSet;

  static [hashtable]$CloseBracket = @{
    '(' = ')';
    '[' = ']';
    '{' = '}';
    '<' = '>';
  }

  static [string] $AllParameterSets = '__AllParameterSets';

  [scriptblock]$RenderCell = {
    [OutputType([boolean])]
    param(
      [string]$column,
      [string]$value,
      [PSCustomObject]$row,
      [PSCustomObject]$options,
      [object]$scribbler,
      [int]$counter
    )
    [boolean]$result = $true;

    # A warning about using -Regex option on a switch statement:
    # - Make sure that each switch branch has a break, this ensures that a single value
    # is handled only once.
    # - Since 'Name' is a substring of 'PipeName' the more prescriptive branch must appear first,
    # otherwise the wrong branch will be taken; If 'Name' case appears before 'PipeName' case, then
    # when $column is 'PipeName' could be handled by the 'Name' case which is not what we intended,
    # and is why the order of the cases matters.
    #
    # So, be careful using -Regex on switch statements.
    #
    switch -Regex ($column) {
      'Mandatory|PipeValue|PipeName|Unique' {
        [string]$padded = Format-BooleanCellValue -Value $value -TableOptions $options;
        $null = $scribbler.Scribble("$($options.Snippets.Reset)$($padded)");

        break;
      }

      'Name' {
        [string]$trimmed = $value.Trim();
        [System.Management.Automation.CommandParameterInfo]$parameterInfo = `
          $options.Custom.ParameterSetInfo.Parameters | Where-Object Name -eq $trimmed;
        [string]$parameterType = $parameterInfo.ParameterType;

        [string]$nameSnippet = if ($options.Custom.CommonParamSet.Contains($trimmed)) {
          $options.Custom.Snippets.Common;
        }
        elseif ($parameterInfo.IsMandatory) {
          $options.Custom.Snippets.Mandatory;
        }
        elseif ([string]$parameterType -eq 'switch') {
          $options.Custom.Snippets.Switch;
        }
        else {
          $options.Custom.Snippets.Cell;
        }
        $null = $scribbler.Scribble("$($nameSnippet)$($value)");

        break;
      }

      'Type' {
        $null = $scribbler.Scribble("$($options.Custom.Snippets.Type)$($value)");

        break;
      }

      default {
        # let's not do anything here and revert to default handling
        #
        $result = $false;
      }
    }
    # https://devblogs.microsoft.com/scripting/use-the-get-command-powershell-cmdlet-to-find-parameter-set-information/
    # https://blogs.msmvps.com/jcoehoorn/blog/2017/10/02/powershell-expandproperty-vs-property/

    return $result;
  } # RenderCell

  Syntax([string]$commandName, [hashtable]$signals, [object]$scribbler, [hashtable]$scheme) {
    $this.CommandName = $commandName;
    $this.Signals = $signals;
    $this.Scribbler = $scribbler;
    $this.Krayon = $scribbler.Krayon;
    $this.Theme = $this.Krayon.Theme;
    $this.Scheme = $scheme;

    $this.Regex = [PSCustomObject]@{
      Param = [PSCustomObject]@{
        OptionalPos_A   = New-RegularExpression `
          -Expression $("\[\[$($this.ParamNamePattern)\]\s$($this.TypePattern)\]");

        OptionalNamed_B = New-RegularExpression `
          -Expression $("\[$($this.ParamNamePattern)\s$($this.TypePattern)\]");

        ManNamed_C      = New-RegularExpression `
          -Expression $("$($this.ParamNamePattern)\s$($this.TypePattern)");

        ManPos_D        = New-RegularExpression `
          -Expression $("\[$($this.ParamNamePattern)\]\s$($this.TypePattern)");

        Switch          = New-RegularExpression `
          -Expression $("\[$($this.ParamNamePattern)\]$($this.NegativeTypePattern)");         
      }
    }

    $this.Snippets = [PSCustomObject]@{
      Punct        = $($this.Scribbler.Snippets($this.Scheme['COLS.PUNCTUATION']));
      Type         = $($this.Scribbler.Snippets($this.Scheme['COLS.TYPE']));
      Mandatory    = $($this.Scribbler.Snippets($this.Scheme['COLS.MAN-PARAM']));
      Optional     = $($this.Scribbler.Snippets($this.Scheme['COLS.OPT-PARAM']));
      Switch       = $($this.Scribbler.Snippets($this.Scheme['COLS.SWITCH']));
      Default      = $($this.Scribbler.Snippets($this.Scheme['COLS.CELL']));
      ParamSetName = $($this.Scribbler.Snippets($this.Scheme['COLS.PARAM-SET-NAME']));
      Command      = $($this.Scribbler.Snippets($this.Scheme['COLS.CMD-NAME']));
      HiLight      = $($this.Scribbler.Snippets($this.Scheme['COLS.HI-LIGHT']));

      HeaderUL     = $($this.Scribbler.Snippets($this.Scheme['COLS.HEADER-UL']));
      Special      = $($this.Scribbler.Snippets($this.Scheme['COLS.SPECIAL']));
      Error        = $($this.Scribbler.Snippets($this.Scheme['COLS.ERROR']));
      Ok           = $($this.Scribbler.Snippets($this.Scheme['COLS.OK']));

      Reset        = $($this.Scribbler.Snippets('Reset'));
      Space        = $($this.Scribbler.Snippets('Reset')) + ' ';
      Comma        = $($this.Scribbler.Snippets('Reset')) + ', ';
      Ln           = $($this.Scribbler.Snippets('Ln'));
      Heading      = $($this.Scribbler.Snippets(@('black', 'bgDarkYellow')));
    }

    $this.Formats = @{
      # NB: The single letter suffix attached to these names (A-D) are important as it reflects
      # the order in which regex replacement must occur. If these replacements are not done in
      # this strict order, then the correct replacements will not occur. This is because some
      # matches are sub-sets of others; eg
      # '-Param <type>' is a substring of '[-Param <type>]' so in the case, the latter replacement
      # must be performed before the former. The order of replacement goes from the most
      # prescriptive to the least.
      #
      OptionalPos_A    = [string]$(
        # [[-Param] <type>] ... optional, positional parameter
        #
        $this.Snippets.Punct + '[[' + $this.Snippets.Optional + '-${name}' + $this.Snippets.Punct + ']' +
        $this.Snippets.Space + '<' + $this.Snippets.Type + '${type}' + $this.Snippets.Punct + '>]'
      );

      OptionalNamed_B  = [string]$(
        # [-Param <type>] ... optional, non-positional parameter
        #
        $this.Snippets.Punct + '[' + $this.Snippets.Optional + '-${name}' + $this.Snippets.Type +
        $this.Snippets.Space +
        $this.Snippets.Punct + '<' + $this.Snippets.Type + '${type}' + $this.Snippets.Punct + '>]'
      );

      MandatoryNamed_C = [string]$(
        # -Param <type> ... mandatory, non-positional parameter
        # (requires passing with parameter name)
        #
        $this.Snippets.Mandatory + '-${name}' + $this.Snippets.Space + $this.Snippets.Punct +
        '<' + $this.Snippets.Type + '${type}' + $this.Snippets.Punct + '>'
      );

      MandatoryPos_D   = [string]$(
        # [-Param] <type> ... mandatory, positional parameter
        # (using the parameter name is optional, if passed in the right position among other
        # arguments passed positionally)
        #
        $this.Snippets.Punct + '[' + $this.Snippets.Mandatory + '-${name}' + $this.Snippets.Punct + ']' +
        $this.Snippets.Space +
        $this.Snippets.Punct + '<' + $this.Snippets.Type + '${type}' + $this.Snippets.Punct + '>'
      );

      # We need to use a negative look-ahead (?!) and only match if the param is not followed by <type>
      # [-Param]
      #
      OptionalSwitch   = [string]$(
        $this.Snippets.Punct + '[' + $this.Snippets.Switch + '-${name}' + $this.Snippets.Punct + ']'
      );

      # -Param
      # (Initially this might seem counter intuitive, since an Option/Flag is optional, but in the
      # context of a parameter set. An optional can be mandatory if the presence of the flag defines
      # that parameter set.)
      #
    }

    [PSCustomObject]$custom = [PSCustomObject]@{
      Colours          = [PSCustomObject]@{
        Mandatory = $this.Scheme['COLS.MAN-PARAM'];
        Switch    = $this.Scheme['COLS.SWITCH'];
        Title     = 'green';
      }

      Snippets         = [PSCustomObject]@{
        Header    = $($this.Scribbler.Snippets($this.Scheme['COLS.HEADER']));
        Underline = $($this.Scribbler.Snippets($this.Scheme['COLS.UNDERLINE']));
        Mandatory = $($this.Scribbler.Snippets($this.Scheme['COLS.MAN-PARAM']));
        Switch    = $($this.Scribbler.Snippets($this.Scheme['COLS.SWITCH']));
        Cell      = $($this.Scribbler.Snippets($this.Scheme['COLS.OPT-PARAM']));
        Type      = $($this.Scribbler.Snippets($this.Scheme['COLS.TYPE']));
        Command   = $($this.Scribbler.Snippets($this.Scheme['COLS.CMD-NAME']));
        Common    = $($this.Scribbler.Snippets($this.Scheme['COLS.COMMON']));
      }
      CommonParamSet   = $this.CommonParamSet;
      IncludeCommon    = $false;
      ParameterSetInfo = $null;
    }

    [string[]]$columns = @('Name', 'Type', 'Mandatory', 'Pos', 'PipeValue', 'PipeName', 'Alias', 'Unique');
    $this.TableOptions = Get-TableDisplayOptions -Select $columns  `
      -Signals $signals -Scribbler $this.Scribbler -Custom $custom;

    $this.TableOptions.Snippets = $this.Snippets;

    [string]$bulletedPoint = $(
      "$([string]::new(' ', $this.TableOptions.Chrome.Indent))" +
      "$($signals['BULLET-B'].Value)"
    );
    $this.Labels = [PSCustomObject]@{
      ParamSet                  = "====> Parameter Set: ";
      DuplicatePositions        = "  *** Duplicate Positions for Parameter Set: ";
      MultipleValueFromPipeline = "  *** Multiple ValueFromPipeline claims for Parameter Set: ";
      AccidentallyInAllSets     = "  *** Parameter '{0}', accidentally in all Parameter Sets.";
      BulletedParams            = $(
        "$($bulletedPoint) Params: "
      );
      BulletedParam             = $(
        "$($bulletedPoint) Param: "
      );
      BulletedParamSet          = $(
        "$($bulletedPoint) Parameter Set: "
      );
    }

    $this.NamesRegex = New-RegularExpression -Expression '(?<name>\w+)';

    $this.AllCommonParamSet = $this.CommonParamSet + $this.ShouldProcessParamSet;
  } # ctor

  [string] TitleStmt([string]$title, [string]$commandName) {
    [string]$commandStmt = $this.QuotedNameStmt($this.Snippets.Command, $commandName, '[');
    [string]$titleStmt = $(
      "$($this.Snippets.Reset)$($this.Snippets.Ln)" +
      "----> $($title) $($commandStmt)$($this.Snippets.Reset) ..." +
      "$($this.Snippets.Ln)"
    );
    return $titleStmt;
  }

  [string] ParamSetStmt(
    [System.Management.Automation.CommandInfo]$commandInfo,
    [System.Management.Automation.CommandParameterSetInfo]$paramSet
  ) {

    [string]$defaultLabel = ($commandInfo.DefaultParameterSet -eq $paramSet.Name) `
      ? " (Default)" : [string]::Empty;

    [string]$structuredParamSetStmt = `
    $(
      "$($this.Snippets.Reset)$($this.Labels.BulletedParamSet)'" +
      "$($this.Snippets.ParamSetName)$($paramSet.Name)$($this.Snippets.Reset)'" +
      "$defaultLabel"
    );

    return $structuredParamSetStmt;
  }

  [string] ResolveParameterSnippet([System.Management.Automation.CommandParameterInfo]$paramInfo) {
    [string]$paramSnippet = if ($paramInfo.IsMandatory) {
      $this.TableOptions.Custom.Snippets.Mandatory;
    }
    elseif ([string]$paramInfo.ParameterType -eq 'switch') {
      $this.TableOptions.Custom.Snippets.Switch;
    }
    else {
      $this.TableOptions.Custom.Snippets.Cell;
    }
    return $paramSnippet;
  }

  [string] ResolvedParamStmt(
    [string[]]$params,
    [System.Management.Automation.CommandParameterSetInfo]$paramSet
  ) {
    [System.Text.StringBuilder]$buildR = [System.Text.StringBuilder]::new();
    [string]$commaSnippet = $this.Snippets.Comma;

    [int]$count = 0;
    foreach ($paramName in $params) {
      [System.Management.Automation.CommandParameterInfo[]]$paramResult = $(
        $paramSet.Parameters | Where-Object { $_.Name -eq $paramName }
      );

      if ($paramResult -and ($paramResult.Count -eq 1)) {
        [System.Management.Automation.CommandParameterInfo]$paramInfo = $paramResult[0];
        [string]$paramSnippet = $this.ResolveParameterSnippet($paramInfo)

        $null = $buildR.Append($(
            $this.QuotedNameStmt($paramSnippet, $paramName)
          ));

        if ($count -lt ($params.Count - 1)) {
          $null = $buildR.Append("$($commaSnippet)");
        }
      }
      $count++;
    }

    return $buildR.ToString();
  }

  [string] ParamsDuplicatePosStmt([PSCustomObject]$seed) {
    [string[]]$params = $seed.Params;
    [System.Management.Automation.CommandParameterSetInfo]$paramSet = $seed.ParamSet;
    [string]$positionNumber = $seed.Number;

    [string]$quotedPosition = $this.QuotedNameStmt($this.Snippets.Special, $positionNumber, '(');
    [string]$structuredStmt = $(
      "$($this.Snippets.Reset)$($this.Labels.DuplicatePositions)" +
      "$($this.QuotedNameStmt($($this.Snippets.ParamSetName), $paramSet.Name))" +
      "$($this.Snippets.Ln)" +
      "$($this.Snippets.Reset)$($this.Labels.BulletedParams) " +
      "$($quotedPosition) " +
      $this.ResolvedParamStmt($params, $paramSet)
    );

    return $structuredStmt;
  }

  [string] MultiplePipelineItemClaimStmt([PSCustomObject]$seed) {
    [string[]]$params = $seed.Params;
    [System.Management.Automation.CommandParameterSetInfo]$paramSet = $seed.ParamSet;

    [string]$structuredStmt = $(
      "$($this.Snippets.Reset)$($this.Labels.MultipleValueFromPipeline)" +
      "$($this.QuotedNameStmt($($this.Snippets.ParamSetName), $paramSet.Name))" +
      "$($this.Snippets.Ln)" +
      "$($this.Snippets.Reset)$($this.Labels.BulletedParams) " +
      $this.ResolvedParamStmt($params, $paramSet)
    );

    return $structuredStmt;
  }

  [string] InAllParameterSetsByAccidentStmt([PSCustomObject]$seed) {
    [string]$paramName = $seed.Param;
    [System.Management.Automation.CommandParameterSetInfo]$paramSet = $seed.ParamSet;
    [System.Management.Automation.CommandParameterInfo]$paramInfo = $($paramSet.Parameters | Where-Object {
        $_.Name -eq $paramName
      })[0];

    [string]$structuredParamName = $(
      "$($this.ResolveParameterSnippet($paramInfo))$($paramName)$($this.Snippets.Reset)"
    );

    # [string[]]$others = ($seed.Others | ForEach-Object {
    #     $this.QuotedNameStmt($this.Snippets.ParamSetName, $_.Name)
    #   }) -join "$($this.Snippets.Comma)";

    [string]$quotedParamSetName = $(
      "$($this.QuotedNameStmt($this.Snippets.ParamSetName, $paramSet.Name))" +
      "$($this.Snippets.Reset)"
    );

    [string]$accidentsStmt = $(
      "$($this.Snippets.Reset)" +
      "$($this.Labels.AccidentallyInAllSets -f $structuredParamName)" +
      "$($this.Snippets.Reset)$($this.Snippets.Ln)$($this.Labels.BulletedParamSet)$($quotedParamSetName)"
    );

    return $accidentsStmt;
  }

  [string] SyntaxStmt(
    [System.Management.Automation.CommandParameterSetInfo]$paramSet
  ) {
    #
    # the syntax can be processed by regex: (gcm command -syntax) -replace '\]? \[*(?=-|<C)',"`r`n "
    # this expression is used in the unit tests.

    [string]$source = $paramSet.ToString();
    [string]$structuredSyntax = $(
      "$($this.Snippets.Reset)Syntax: $($this.Snippets.Command)$($this.CommandName) $source"
    );

    $structuredSyntax = $this.Regex.Param.OptionalPos_A.Replace(
      $structuredSyntax, $this.Formats.OptionalPos_A);

    $structuredSyntax = $this.Regex.Param.OptionalNamed_B.Replace(
      $structuredSyntax, $this.Formats.OptionalNamed_B);

    $structuredSyntax = $this.Regex.Param.ManNamed_C.Replace(
      $structuredSyntax, $this.Formats.MandatoryNamed_C);

    $structuredSyntax = $this.Regex.Param.ManPos_D.Replace(
      $structuredSyntax, $this.Formats.MandatoryPos_D);

    $structuredSyntax = $this.Regex.Param.Switch.Replace(
      $structuredSyntax, $this.Formats.OptionalSwitch);

    # We need to process Mandatory switch parameters, which are of the form
    # -Param. However, this pattern is way too generic, so we can't identify
    # by applying a regex on the syntax. Instead, we need to query the parameter
    # set's parameters to find them and colourise them directly.
    #
    [PSCustomObject[]]$resultSet = $($paramSet.Parameters | Where-Object {
        ($_.Name -NotIn $this.CommonParamSet) -and
        ($_.IsMandatory) -and ([string]$_.ParameterType -eq 'switch')
      });

    if ($resultSet -and ($resultSet.Count -gt 0)) {
      [string[]]$names = $resultSet.Name;

      $names | ForEach-Object {
        $expression = "\-$_[\s|$]";
        $structuredSyntax = $($structuredSyntax -replace $expression, $(
            # -Param
            #
            $this.Snippets.Switch + '-' + $this.Snippets.Mandatory + $_ + ' '
          ))
      }
    }

    # NB: this is a straight string replace, not regex replace
    #
    $structuredSyntax = $structuredSyntax.Replace('[<CommonParameters>]',
      "$($this.Snippets.Punct)[<$($this.Snippets.Default)CommonParameters$($this.Snippets.Punct)>]"
    );

    return $structuredSyntax;
  }

  [string] DuplicateParamSetStmt(
    [System.Management.Automation.CommandParameterSetInfo]$firstSet,
    [System.Management.Automation.CommandParameterSetInfo]$secondSet
  ) {
    # ----> Parameter sets [command-name]: 'first' and 'second' have equivalent sets of parameters
    #
    [string]$structuredDuplicateParamSetStmt = $(
      "$($this.Snippets.Reset)$([string]::new(' ', $this.TableOptions.Chrome.Indent))" +
      "$($this.Signals['BULLET-B'].Value) Parameter Sets " +
      "$($this.Snippets.Reset)[$($this.Snippets.Command)$($this.CommandName)$($this.Snippets.Reset)]: " +
      "$($this.Snippets.Punct)'" +
      "$($this.Snippets.ParamSetName)$($firstSet.Name)$($this.Snippets.Punct)'$($this.Snippets.Reset) and " +
      "$($this.Snippets.Punct)'" +
      "$($this.Snippets.ParamSetName)$($secondSet.Name)$($this.Snippets.Punct)' " +
      "$($this.Snippets.Reset) have equivalent sets of parameters:" +
      "$($this.Snippets.Ln)"
    );
    return $structuredDuplicateParamSetStmt;
  }

  [string] QuotedNameStmt([string]$nameSnippet) {
    return $this.QuotedNameStmt($nameSnippet, '${name}', "'");
  }

  [string] QuotedNameStmt([string]$nameSnippet, [string]$name) {
    return $this.QuotedNameStmt($nameSnippet, $name, "'");
  }

  [string] QuotedNameStmt([string]$nameSnippet, [string]$name, [string]$open) {
    [string]$close = if ([syntax]::CloseBracket.ContainsKey($open)) {
      [syntax]::CloseBracket[$open];
    }
    else {
      $open;
    }

    [string]$nameStmt = $(
      $($this.Snippets.Punct) + $open + $nameSnippet + $name + $($this.Snippets.Punct) + $close
    );
    return $nameStmt;
  }

  [string] InvokeWithParamsStmt (
    [System.Management.Automation.CommandParameterSetInfo]$paramSet,
    [string[]]$invokeParams
  ) {
    [System.Text.StringBuilder]$buildR = [System.Text.StringBuilder]::new();

    [int]$count = 0;
    $invokeParams | ForEach-Object {
      [string]$paramName = $_;
      [array]$params = $paramSet.Parameters | Where-Object Name -eq $paramName;

      if ($params.Count -eq 1) {
        [System.Management.Automation.CommandParameterInfo]$parameterInfo = $params[0];
        [string]$paramSnippet = $this.ResolveParameterSnippet($parameterInfo);

        $null = $buildR.Append($this.QuotedNameStmt($paramSnippet, $parameterInfo.Name));

        if ($count -lt ($invokeParams.Count - 1)) {
          $null = $buildR.Append($this.Snippets.Comma);
        }
      }
      $count++;
    }

    return $buildR.ToString();
  }

  [string] Indent([int]$units) {
    return [string]::new(' ', $this.TableOptions.Chrome.Indent * $units);
  }

  [string] Fold([string]$text, [string]$textSnippet, [int]$width, [int]$margin) {
    [System.Text.StringBuilder]$buildR = [System.Text.StringBuilder]::new();
    $null = $buildR.Append($textSnippet);

    [string[]]$split = $text -split ' ';
    [int]$tokenNoCurrentLine = 0;
    [string]$line = [string]::new(' ', $margin);
    [int]$space = 1;
    foreach ($token in $split) {
      if ((($line.Length + $token.Length + $space) -lt ($width - $margin)) -or ($tokenNoCurrentLine -eq 0)) {
        # Current token will fit on the current line so let's add it. The only exception is
        # if the current token is very large and breaches the width/margin limit by itself
        # (ie tokenNo is 0), then we have no choice other than to breach the limit anyway.
        # I suppose an alternative would be just to fold this token by inserting a dash.
        #
        $line += "$token "; # use of += ok here, because its the core of the algorithm.
        $tokenNoCurrentLine++;
      }
      else {
        # Current token doesn't fit, so let's start a new line
        #
        $null = $buildR.Append($(
            "$($line)$($this.Snippets.Ln)"
          ));
        $line = [string]::new(' ', $margin);
        $line += "$token "; # use of += ok here, because its the core of the algorithm.
        $tokenNoCurrentLine = ($tokenNoCurrentLine -eq 0) ? 1 : 0;
      }
    }
    $null = $buildR.Append($(
        "$($line)$($this.Snippets.Ln)$($this.Snippets.Reset)"
      ));

    return $buildR.ToString();
  }
}
