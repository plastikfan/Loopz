$global:LoopzHelpers = @{
  # Helper Script Blocks
  #
  WhItemDecoratorBlock = [scriptblock] {
    param(
      [Parameter(Mandatory)]
      $_underscore,

      [Parameter(Mandatory)]
      [int]$_index,

      [Parameter(Mandatory)]
      [hashtable]$_exchange,

      [Parameter(Mandatory)]
      [boolean]$_trigger
    )

    return Write-HostFeItemDecorator -Underscore $_underscore `
      -Index $_index `
      -Exchange $_exchange `
      -Trigger $_trigger
  } # WhItemDecoratorBlock

  HeaderBlock          = [scriptblock] {
    param(
      [hashtable]$Exchange = @{}
    )

    Show-Header -Exchange $Exchange;
  } # HeaderBlock

  SummaryBlock         = [scriptblock] {
    param(
      [int]$Count,
      [int]$Skipped,
      [int]$Errors,
      [boolean]$Triggered,
      [hashtable]$Exchange = @{}
    )

    Show-Summary -Count $Count -Skipped $Skipped `
      -Errors $Errors -Triggered $Triggered -Exchange $Exchange;
  } # SummaryBlock
}

# Session UI state
#
[int]$global:_LineLength = 121;
[int]$global:_SmallLineLength = 81;
#
$global:LoopzUI = [ordered]@{
  # Line definitions:
  #
  UnderscoreLine      = ([string]::new("_", $_LineLength));
  EqualsLine          = ([string]::new("=", $_LineLength));
  DotsLine            = ([string]::new(".", $_LineLength));
  DashLine            = ([string]::new("-", $_LineLength));
  LightDotsLine       = (([string]::new(".", (($_LineLength - 1) / 2))).Replace(".", ". ") + ".");
  LightDashLine       = (([string]::new("-", (($_LineLength - 1) / 2))).Replace("-", "- ") + "-");
  TildeLine           = ([string]::new("~", $_LineLength));

  SmallUnderscoreLine = ([string]::new("_", $_SmallLineLength));
  SmallEqualsLine     = ([string]::new("=", $_SmallLineLength));
  SmallDotsLine       = ([string]::new(".", $_SmallLineLength));
  SmallDashLine       = ([string]::new("-", $_SmallLineLength));
  SmallLightDotsLine  = (([string]::new(".", (($_SmallLineLength - 1) / 2))).Replace(".", ". ") + ".");
  SmallLightDashLine  = (([string]::new("-", (($_SmallLineLength - 1) / 2))).Replace("-", "- ") + "-");
  SmallTildeLine      = ([string]::new("~", $_SmallLineLength));
}

$global:Loopz = [PSCustomObject]@{
  InlineCodeToOption    = [hashtable]@{
    'm' = 'Multiline';
    'i' = 'IgnoreCase';
    'x' = 'IgnorePatternWhitespace';
    's' = 'Singleline';
    'n' = 'ExplicitCapture';
  }

  FsItemTypePlaceholder = '*{_fileSystemItemType}';
  DependencyPlaceholder = '*{_dependency}';

  SignalLabel           = 0;
  SignalEmoji           = 1;

  MissingSignal         = @{
    'windows' = (New-Pair(@('???', '🔻')));
    'linux'   = (New-Pair(@('???', '🔴')));
    'mac'     = (New-Pair(@('???', '🔺')));
  }

  # TODO:
  # - See
  #   * https://devblogs.microsoft.com/commandline/windows-command-line-unicode-and-utf-8-output-text-buffer/
  #   * https://stackoverflow.com/questions/49476326/displaying-unicode-in-powershell
  #
  DefaultSignals        = [ordered]@{
    # Operations
    #
    'CUT-A'        = (New-Pair(@('Cut', '✂️')));
    'CUT-B'        = (New-Pair(@('Cut', '🔪')));
    'COPY-A'       = (New-Pair(@('Copy', '🍒')));
    'COPY-B'       = (New-Pair(@('Copy', '🥒')));
    'MOVE-A'       = (New-Pair(@('Move', '🍺')));
    'MOVE-B'       = (New-Pair(@('Move', '🍻')));
    'PASTE-A'      = (New-Pair(@('Paste', '🌶️')));
    'PASTE-B'      = (New-Pair(@('Paste', '🥜')));
    'OVERWRITE-A'  = (New-Pair(@('Overwrite', '♻️')));
    'OVERWRITE-B'  = (New-Pair(@('Overwrite', '❗')));
    'PREPEND'      = (New-Pair(@('Prepend', '📌')));
    'APPEND'       = (New-Pair(@('Append', '📌')));

    # Thingies
    #
    'DIRECTORY-A'  = (New-Pair(@('Directory', '📁')));
    'DIRECTORY-B'  = (New-Pair(@('Directory', '🗂️')));
    'FILE-A'       = (New-Pair(@('File', '🏷️')));
    'FILE-B'       = (New-Pair(@('File', '📝')));
    'PATTERN'      = (New-Pair(@('Pattern', '🛡️')));
    'WITH'         = (New-Pair(@('With', '🍑')));
    'CRUMB-A'      = (New-Pair(@('Crumb', '🎯')));
    'CRUMB-B'      = (New-Pair(@('Crumb', '🧿')));
    'CRUMB-C'      = (New-Pair(@('Crumb', '💎')));
    'SUMMARY-A'    = (New-Pair(@('Summary', '🔆')));
    'SUMMARY-B'    = (New-Pair(@('Summary', '✨')));
    'MESSAGE'      = (New-Pair(@('Message', '🗯️')));
    'CAPTURE'      = (New-Pair(@('Capture', '☂️')));

    # Media
    #
    'AUDIO'        = (New-Pair(@('Audio', '🎶')));
    'TEXT'         = (New-Pair(@('Text', '🆎')));
    'DOCUMENT'     = (New-Pair(@('Document', '📜')));
    'IMAGE'        = (New-Pair(@('Image', '🖼️')));
    'MOVIE'        = (New-Pair(@('Movie', '🎬')));

    # Indicators
    #
    'WHAT-IF'      = (New-Pair(@('WhatIf', '☑️')));
    'WARNING-A'    = (New-Pair(@('Warning', '⚠️')));
    'WARNING-B'    = (New-Pair(@('Warning', '👻')));
    'SWITCH-ON'    = (New-Pair(@('On', '✔️')));
    'SWITCH-OFF'   = (New-Pair(@('Off', '✖️')));
    'INVALID'      = (New-Pair(@('Invalid', '❌')));
    'OK-A'         = (New-Pair(@('🆗', '🚀')));
    'OK-B'         = (New-Pair(@('🆗', '🌟')));
    'BAD-A'        = (New-Pair(@('Bad', '💥')));
    'BAD-B'        = (New-Pair(@('Bad', '💢')));
    'PROHIBITED'   = (New-Pair(@('Prohibited', '🚫')));
    'INCLUDE'      = (New-Pair(@('Include', '➕')));
    'EXCLUDE'      = (New-Pair(@('Exclude', '➖')));
    'SOURCE'       = (New-Pair(@('Source', '🎀')));
    'DESTINATION'  = (New-Pair(@('Destination', '☀️')));
    'TRIM'         = (New-Pair(@('Trim', '🌊')));
    'MULTI-SPACES' = (New-Pair(@('Spaces', '❄️')));
    'DIAGNOSTICS'  = (New-Pair(@('Diagnostics', '🧪')));
    'LOCKED'       = (New-Pair(@('Locked', '🔐')));
    'NOVICE'       = (New-Pair(@('Novice', '🔰')));
    'TRANSFORM'    = (New-Pair(@('Transform', '🤖')));
    'BULLET-A'     = (New-Pair(@('Bullet Point', '🔶')));
    'BULLET-B'     = (New-Pair(@('Bullet Point', '🟢')));
    'BULLET-C'     = (New-Pair(@('Bullet Point', '🟨')));
    'BULLET-D'     = (New-Pair(@('Bullet Point', '💠')));

    # Outcomes
    #
    'FAILED-A'     = (New-Pair(@('Failed', '☢️')));
    'FAILED-B'     = (New-Pair(@('Failed', '💩')));
    'SKIPPED-A'    = (New-Pair(@('Skipped', '💤')));
    'SKIPPED-B'    = (New-Pair(@('Skipped', '👾')));
    'ABORTED-A'    = (New-Pair(@('Aborted', '✖️')));
    'ABORTED-B'    = (New-Pair(@('Aborted', '👽')));
    'CLASH'        = (New-Pair(@('Clash', '📛')));
    'NOT-ACTIONED' = (New-Pair(@('Not Actioned', '⛔')));

    # Command Specific
    #
    'REMY.ANCHOR'  = (New-Pair(@('Anchor', '⚓')));
    'REMY.POST'    = (New-Pair(@('Post Process', '🌈')));
    'REMY.DROP'    = (New-Pair(@('Drop', '💧')));
    'REMY.UNDO'    = (New-Pair(@('Undo Rename', '❎')));
    'GREPS'        = (New-Pair(@('greps', '🔍')));
  }

  OverrideSignals       = @{ # Label, Emoji
    'windows' = @{
      # defaults based on windows, so there should be no need for overrides
    };

    'linux'   = @{
      # tbd
    };

    'mac'     = @{
      # tbd
    };
  }

  # DefaultSignals resolved into Signals by Initialize-Signals
  #
  Signals               = $null;

  # User defined signals, should be populated by profile
  #
  CustomSignals         = $null;

  Defaults              = [PSCustomObject]@{
    Remy = [PSCustomObject]@{
      Marker  = [char]0x2BC1;

      Context = [PSCustomObject]@{
        Title             = 'Rename';
        ItemMessage       = 'Rename Item';
        SummaryMessage    = 'Rename Summary';
        Locked            = 'LOOPZ_REMY_LOCKED';
        UndoDisabledEnVar = 'LOOPZ_REMY_UNDO_DISABLED';
        OperantShortCode  = 'remy';
      }
    }
  }

  Rules                 = [PSCustomObject]@{
    Remy = [PSCustomObject]@{
      Trim   = @{
        'IsApplicable' = [scriptblock] {
          param([string]$_Input)
          $($_Input.StartsWith(' ') -or $_Input.EndsWith(' '));
        };

        'Transform'    = [scriptblock] {
          param([string]$_Input)
          $_Input.Trim();
        };
        'Signal'       = 'TRIM'
      }

      Spaces = @{
        'IsApplicable' = [scriptblock] {
          param([string]$_Input)
          $_Input -match "\s{2,}";
        };

        'Transform'    = [scriptblock] {
          param([string]$_Input)
          $_Input -replace "\s{2,}", ' '
        };
        'Signal'       = 'MULTI-SPACES'
      }
    }
  }

  InvalidCharacterSet   = [char[]]'<>:"/\|?*';
}
