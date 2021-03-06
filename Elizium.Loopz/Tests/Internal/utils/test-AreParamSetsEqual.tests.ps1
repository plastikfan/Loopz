using module Elizium.Krayola;
using namespace System.Management.Automation;

Describe 'test-AreParamSetsEqual' -Tag 'PSTools' {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module -Force;;
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;
  }

  BeforeEach {
    InModuleScope Elizium.Loopz {
      [Krayon]$script:_krayon = Get-Krayon;
      [hashtable]$script:_signals = Get-Signals;
      [hashtable]$theme = $_krayon.Theme;
      [Hashtable]$script:_scheme = Get-SyntaxScheme -Theme $theme;
      [Scribbler]$script:_scribbler = New-Scribbler -Krayon $_krayon -Test;
    }
  }

  Context 'given: parameter sets which are different' {
    It 'should: return false' {
      InModuleScope Elizium.Loopz {
        function test-WithMultipleParamSets {
          param(
            [parameter()]
            [object]$Chaff,

            [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 1)]
            [object]$DuplicatePosA,

            [Parameter(ParameterSetName = 'Alpha', Position = 2)]
            [object]$DuplicatePosB,

            [Parameter(ParameterSetName = 'Alpha', Position = 3)]
            [object]$DuplicatePosC,

            [Parameter(ParameterSetName = 'Beta', Mandatory, Position = 1)]
            [object]$SameA,

            [Parameter(ParameterSetName = 'Beta', Position = 2)]
            [object]$SameB
          )
        }

        [string]$commandName = 'test-WithMultipleParamSets';
        [CommandInfo]$commandInfo = Get-Command $commandName;
        [CommandParameterSetInfo]$alphaPsi = $commandInfo.ParameterSets | Where-Object Name -eq 'Alpha';
        [CommandParameterSetInfo]$betaPsi = $commandInfo.ParameterSets | Where-Object Name -eq 'Beta';
        [Syntax]$syntax = [Syntax]::new($commandName, $_signals, $_scribbler, $_scheme);

        test-AreParamSetsEqual -FirstPsInfo $alphaPsi -SecondPsInfo $betaPsi `
          -Syntax $syntax | Should -BeFalse;
      }
    }
  }

  Context 'given: parameter sets which are the same' {
    It 'should: return true' {
      InModuleScope Elizium.Loopz {
        function test-WithDuplicateParamSets {
          param(
            [Parameter()]
            [object]$Chaff,

            [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 1)]
            [Parameter(ParameterSetName = 'Beta', Mandatory, Position = 1)]
            [object]$DuplicatePosA,

            [Parameter(ParameterSetName = 'Alpha', Position = 2)]
            [Parameter(ParameterSetName = 'Beta', Position = 2)]
            [object]$DuplicatePosB,

            [Parameter(ParameterSetName = 'Alpha', Position = 3)]
            [Parameter(ParameterSetName = 'Beta', Position = 3)]
            [object]$DuplicatePosC
          )
        }
        [string]$commandName = 'test-WithDuplicateParamSets';
        [CommandInfo]$commandInfo = Get-Command $commandName;
        [CommandParameterSetInfo]$alphaPsi = $commandInfo.ParameterSets | Where-Object Name -eq 'Alpha';
        [CommandParameterSetInfo]$betaPsi = $commandInfo.ParameterSets | Where-Object Name -eq 'Beta';
        [Syntax]$syntax = [Syntax]::new($commandName, $_signals, $_scribbler, $_scheme);

        test-AreParamSetsEqual -FirstPsInfo $alphaPsi -SecondPsInfo $betaPsi `
          -Syntax $syntax | Should -BeTrue;
      }
    }
  }
} # test-AreParamSetsEqual
