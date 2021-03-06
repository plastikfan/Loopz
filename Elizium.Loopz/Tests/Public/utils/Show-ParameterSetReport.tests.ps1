
Describe 'Show-ParameterSetReport' -Tag 'PSTools' {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module -Force;;
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    InModuleScope Elizium.Loopz {
      function script:test-MultipleSetsWithDuplicatedPositions {
        param(
          [parameter()]
          [object]$Chaff,

          [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 999)]
          [object]$DuplicatePosA,

          [Parameter(ParameterSetName = 'Alpha', Position = 999)]
          [object]$DuplicatePosB,

          [Parameter(ParameterSetName = 'Alpha', Position = 999)]
          [object]$DuplicatePosC,

          [Parameter(ParameterSetName = 'Beta', Mandatory, Position = 111)]
          [object]$SameA,

          [Parameter(ParameterSetName = 'Beta', Position = 111)]
          [object]$SameB
        )
      }

      function script:test-WithDuplicateParamSets {
        param(
          [Parameter()]
          [object]$Chaff,

          [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 1)]
          [Parameter(ParameterSetName = 'Beta', Mandatory, Position = 11)]
          [object]$DuplicatePosA,

          [Parameter(ParameterSetName = 'Alpha', Position = 2)]
          [Parameter(ParameterSetName = 'Beta', Position = 12)]
          [Parameter(ParameterSetName = 'Delta', Position = 21)]
          [object]$DuplicatePosB,

          [Parameter(ParameterSetName = 'Alpha', Position = 3)]
          [Parameter(ParameterSetName = 'Beta', Position = 13)]
          [Parameter(ParameterSetName = 'Delta', Position = 22)]
          [object]$DuplicatePosC,

          [Parameter(ParameterSetName = 'SamePos', Mandatory, Position = 111)]
          [object]$SameA,

          [Parameter(ParameterSetName = 'SamePos', Position = 111)]
          [object]$SameB
        )
      }

      function script:test-WithMultipleRuleViolations {
        param(
          [Parameter()]
          [object]$Chaff,

          [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 1, ValueFromPipeline = $true)]
          [Parameter(ParameterSetName = 'Beta', Mandatory, Position = 11)]
          [object]$DuplicatePosA,

          [Parameter(ParameterSetName = 'Alpha', Position = 2, ValueFromPipeline = $true)]
          [Parameter(ParameterSetName = 'Beta', Position = 12)]
          [Parameter(ParameterSetName = 'Delta', Position = 21)]
          [object]$DuplicatePosB,

          [Parameter(ParameterSetName = 'Alpha', Position = 3)]
          [Parameter(ParameterSetName = 'Beta', Position = 13)]
          [Parameter(ParameterSetName = 'Delta', Position = 22)]
          [object]$DuplicatePosC
        )
      }

      function script:test-MultipleClaimsToPipelineValue {
        param(
          [parameter(ValueFromPipeline = $true)]
          [object]$Chaff,

          [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 1, ValueFromPipeline = $true)]
          [object]$ClaimA,

          [Parameter(ParameterSetName = 'Alpha', Position = 2, ValueFromPipeline = $true)]
          [object]$ClaimB,

          [Parameter(ParameterSetName = 'Alpha', Position = 3, ValueFromPipeline = $true)]
          [object]$ClaimC,

          [Parameter(ParameterSetName = 'Beta', Position = 1, ValueFromPipeline = $true)]
          [object]$ClaimD,

          [Parameter(ParameterSetName = 'Beta', Position = 2, ValueFromPipeline = $true)]
          [object]$ClaimE
        )
      }

      function script:test-MultipleInAllParameterSetsByAccident {
        param(
          [object]$Wheat,

          [parameter()]
          [object]$Chaff,

          [Parameter()]
          [Parameter(ParameterSetName = 'Alpha', Mandatory, Position = 1)]
          [Parameter(ParameterSetName = 'Another', Mandatory, Position = 1)]
          [Parameter(ParameterSetName = 'Ok', Mandatory, Position = 1)]
          [object]$AccidentalA,

          [Parameter()]
          [Parameter(ParameterSetName = 'Beta', Position = 2)]
          [Parameter(ParameterSetName = 'Ok', Mandatory, Position = 2)]
          [object]$AccidentalB,

          [parameter()]
          [Parameter(ParameterSetName = 'Delta', Position = 3)]
          [object]$AccidentalC
        )
      }
    }
  }

  Context 'given: Invoke-Command' {
    It 'should: not report any violations' {
      'Invoke-Command' | Show-ParameterSetReport -Test;
    }
  }

  Context 'given: a command containing a Param Set with duplicated position numbers' {
    It 'should: report UNIQUE-POSITIONS violation' {
      InModuleScope Elizium.Loopz {
        'test-MultipleSetsWithDuplicatedPositions' | Show-ParameterSetReport -Test;
      }
    }
  }

  Context 'given: a command containing a duplicated Param Sets' {
    It 'should: report UNIQUE-PARAM-SET violation' {
      InModuleScope Elizium.Loopz {
        'test-WithDuplicateParamSets' | Show-ParameterSetReport -Test;
      }
    }
  }

  Context 'given: a command containing a duplicated Param Sets' {
    It 'should: report SINGLE-PIPELINE-PARAM violation' {
      InModuleScope Elizium.Loopz {
        'test-MultipleClaimsToPipelineValue' | Show-ParameterSetReport -Test;
      }
    }
  }

  Context 'given: a command containing a duplicated Param Sets' {
    It 'should: report ACCIDENTAL-ALL-SETS violation' {
      InModuleScope Elizium.Loopz {
        'test-MultipleInAllParameterSetsByAccident' | Show-ParameterSetReport -Test;
      }
    }
  }

  Context 'given: a command with multiple rule violations' {
    It 'should: report all violation types' {
      InModuleScope Elizium.Loopz {
        'test-WithMultipleRuleViolations' | Show-ParameterSetReport -Test;
      }
    }
  }

  Context 'given: byName' {
    It 'should: Show parameter set info' {
      Show-ParameterSetReport -Name 'Invoke-MirrorDirectoryTree' -Test
    }
  }

  Context 'given: Command alias' {
    It 'should: should: Show parameter set info' {
      Show-ParameterSetReport -Name 'Mirror-Directory' -Test
    }
  }

  Context 'given: bad Command' {
    It 'should: Not Show parameter set info' {
      Show-ParameterSetReport -Name 'blah' -Test -ErrorAction SilentlyContinue
    }
  }
}
