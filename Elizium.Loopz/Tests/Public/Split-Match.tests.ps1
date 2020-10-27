
Describe 'Split-Match' {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;

    [string]$script:source = 'Greetings; spot: 23-05-2017, tom-next: 22-05-2017, cob: 21-05-2017.';
    [string]$script:pattern = '\d{2}-\d{2}-\d{4}';
  }

  Context 'given: Pattern does match' {
    Context 'and: multiple matches' {
      Context 'and: CapturedOnly' {
        Context 'and: First' {
          It 'should: Get first Occurrence' {
            Split-Match -Source $source -Pattern $pattern -Occurrence 'F' -CapturedOnly | `
              Should -BeExactly '23-05-2017';
          }
        } # and: First
      } # and: CapturedOnly

      Context 'and: NOT CapturedOnly' {
        Context 'and: First' {
          It 'should: Get first Occurrence' {
            [string]$captured, [string]$remainder, $matchInfo = `
              Split-Match -Source $source -Pattern $pattern -Occurrence 'F';
            $captured | Should -BeExactly '23-05-2017';
            $remainder | Should -BeExactly 'Greetings; spot: , tom-next: 22-05-2017, cob: 21-05-2017.';
            $matchInfo | Should -Not -BeNullOrEmpty;
          }
        } # and: First

        Context 'and: Last' {
          It 'should: Get last Occurrence' {
            [string]$captured, [string]$remainder, $matchInfo = `
              Split-Match -Source $source -Pattern $pattern -Occurrence 'L';
            $captured | Should -BeExactly '21-05-2017';
            $remainder | Should -BeExactly 'Greetings; spot: 23-05-2017, tom-next: 22-05-2017, cob: .';
            $matchInfo | Should -Not -BeNullOrEmpty;
          }
        } # and: Last

        Context 'and: 2nd' {
          It 'should: Get second Occurrence' {
            [string]$captured, [string]$remainder, $matchInfo = `
              Split-Match -Source $source -Pattern $pattern -Occurrence '2';
            $captured | Should -BeExactly '22-05-2017';
            $remainder | Should -BeExactly 'Greetings; spot: 23-05-2017, tom-next: , cob: 21-05-2017.';
            $matchInfo | Should -Not -BeNullOrEmpty;
          }
        } # and: 2nd
      }
    } # and: multiple matches
  } # given: Pattern does match
} # Split-Match