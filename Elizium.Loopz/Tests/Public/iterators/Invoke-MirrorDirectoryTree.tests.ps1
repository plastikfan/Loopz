﻿
Describe 'Invoke-MirrorDirectoryTree' {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module -Force;
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking -Force;

    # WhatIf set on function calls. This makes the test output very chatty when set to true.
    # WARNING: setting whatIf to true will break the tests, but you can see the directory and
    # file locations.
    #
    [boolean]$script:whatIf = $false;
    [string]$script:sourcePath = '.\Tests\Data\traverse\';
    [string]$script:destinationPath = 'TestDrive:\dev\TEST\';
    New-Item -ItemType 'Directory' -Path $destinationPath;
  }

  Context 'given: no filters applied' {
    Context 'and: directory tree without Creation option specified' {
      It 'Should: traverse without creating files or directories' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -WhatIf:$whatIf;
      }
    }

    Context 'and: function specified' {
      It 'Should: traverse and invoke function for each directory' {
        function global:Test-ShowMirror {
          [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
          param(
            [Parameter(Mandatory)]
            [System.IO.DirectoryInfo]$Underscore,

            [Parameter(Mandatory)]
            [int]$Index,

            [Parameter(Mandatory)]
            [hashtable]$Exchange,

            [Parameter(Mandatory)]
            [boolean]$Trigger,

            [Parameter(Mandatory)]
            [string]$Format
          )

          [string]$result = $Format -f ($Underscore.Name);
          Write-Debug "Custom function; Show-Mirror: '$result'";
          @{ Product = $Underscore }
        }

        [hashtable]$parameters = @{
          'Format' = '---- {0} ----';
        }
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs `
          -Functee 'Test-ShowMirror' -FuncteeParams $parameters -WhatIf:$whatIf;
      }
    }

    Context 'and: script block with extra custom parameters specified' {
      It 'Should: traverse and invoke script block for each directory' {
        $container = @{
          count = 0;
        };

        [scriptblock]$block = {
          param(
            [System.IO.DirectoryInfo]$DirInfo,
            [int]$Index,
            [hashtable]$Exchange,
            [boolean]$Trigger,
            [string]$Format
          )
          $container.count++;
          [string]$result = $Format -f ($DirInfo.Name);
          Write-Debug "### Custom block: '$result'";
          @{ Product = $DirInfo }
        }
        $parameters = , @('---- {0} ----');

        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs `
          -Block $block -BlockParams $parameters -WhatIf:$whatIf;
        $container.count | Should -Be 19;
      }
    }

    Context 'and: script-block specified' {
      It 'Should: traverse and invoke function for each directory' {
        [scriptblock]$testShowMirrorBlock = {
          param(
            [Parameter(Mandatory)]
            [System.IO.DirectoryInfo]$Underscore,

            [Parameter(Mandatory)]
            [int]$Index,

            [Parameter(Mandatory)]
            [hashtable]$Exchange,

            [Parameter(Mandatory)]
            [boolean]$Trigger,

            [Parameter(Mandatory)]
            [string]$Format = "DEFAULT: >>>> {0} >>>>"
          )

          [string]$result = $Format -f ($Underscore.Name);
          Write-Debug "Custom function; Show-Mirror: '$result'";
          @{ Product = $Underscore }
        }

        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs `
          -Block $testShowMirrorBlock -WhatIf:$whatIf;
      }
    }

    Context 'and: directory tree with Directory Creation option specified' {
      It 'Should: traverse creating directories only' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs -WhatIf:$whatIf;

        $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
        Test-Path -Path $testPath | Should -BeTrue;
      }
    }

    Context 'and: directory tree with Directory and File Creation options specified' {
      It 'Should: traverse creating files and directories' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs -CopyFiles -WhatIf:$whatIf;

        $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
        Test-Path -Path $testPath | Should -BeTrue;

        $testFile = Join-Path -Path $destinationPath -ChildPath 'Audio\audio-catalogue.txt';
        Test-Path -Path $testFile | Should -BeTrue;
      }
    }
  } # given: no filters applied

  Context 'given: Include file filters applied' {
    Context 'and: directory tree with Directory and File Creation options specified' {
      It 'Should: traverse creating files and directories' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs -CopyFiles -FileIncludes @('cover.*') -WhatIf:$whatIf;

        $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
        Test-Path -Path $testPath | Should -BeTrue;

        $coverFile = Join-Path -Path $destinationPath `
          -ChildPath 'Audio\GOTHIC\Fields Of The Nephilim\Earth Inferno\cover.fotn.earth-inferno.jpg.txt';
        Test-Path -Path $coverFile | Should -BeTrue -Because "'cover.fotn.earth-inferno.jpg.txt' matches include";

        $excludedFile = Join-Path -Path $destinationPath -ChildPath 'Audio\audio-catalogue.txt';
        Test-Path -Path $excludedFile | Should -BeFalse;
      }
    }

    Context 'and: filter without wild-card' {
      Context 'and: filter without preceding "."' {
        It 'Should: traverse creating files and directories' {
          Invoke-MirrorDirectoryTree -Path $sourcePath `
            -DestinationPath $destinationPath -CreateDirs -CopyFiles -FileIncludes @('jpg.txt') -WhatIf:$whatIf;

          $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
          Test-Path -Path $testPath | Should -BeTrue;

          $coverFile = Join-Path -Path $destinationPath `
            -ChildPath 'Audio\GOTHIC\Fields Of The Nephilim\Earth Inferno\cover.fotn.earth-inferno.jpg.txt';
          Test-Path -Path $coverFile | Should -BeTrue -Because "Path $coverFile does not exist";

          $excludedFile = Join-Path -Path $destinationPath -ChildPath 'Audio\audio-catalogue.txt';
          Test-Path -Path $excludedFile | Should -BeFalse;
        }
      }

      Context 'and: filter with preceding "."' {
        It 'Should: traverse creating files and directories' {
          Invoke-MirrorDirectoryTree -Path $sourcePath `
            -DestinationPath $destinationPath -CreateDirs -CopyFiles -FileIncludes @('.jpg.txt') -WhatIf:$whatIf;

          $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
          Test-Path -Path $testPath | Should -BeTrue -Because "Path $testPath does not exist";

          $coverFile = Join-Path -Path $destinationPath `
            -ChildPath 'Audio\GOTHIC\Fields Of The Nephilim\Earth Inferno\cover.fotn.earth-inferno.jpg.txt';
          Test-Path -Path $coverFile | Should -BeTrue -Because "Path $coverFile does not exist";

          $excludedFile = Join-Path -Path $destinationPath -ChildPath 'Audio\audio-catalogue.txt';
          Test-Path -Path $excludedFile | Should -BeFalse;
        }
      }
    } # and: filter without wild-card
  } # given: Include file filters applied

  Context 'given: Exclude file filters applied' {
    Context 'and: directory tree with Directory and File Creation options specified' {
      It 'Should: traverse creating files and directories' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs -CopyFiles -FileExcludes @('*mp3*') -WhatIf:$whatIf;

        $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
        Test-Path -Path $testPath | Should -BeTrue -Because "Path $testPath does not exist";

        $coverFile = Join-Path -Path $destinationPath `
          -ChildPath 'Audio\GOTHIC\Fields Of The Nephilim\Earth Inferno\cover.fotn.earth-inferno.jpg.txt';
        Test-Path -Path $coverFile | Should -BeTrue -Because "Path $coverFile does not exist";

        $testFile = Join-Path -Path $destinationPath -ChildPath 'Audio\MINIMAL\Plastikman\Consumed\A1 - Contain.mp3.txt';
        Test-Path -Path $testFile | Should -BeFalse -Because "Path $testFile has been excluded";
      }
    }
  } # given: Exclude file filters applied

  Context 'given: Include file filters applied' {
    Context 'and: directory tree with Directory Creation option specified' {
      It 'Should: traverse creating files and directories' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs -DirectoryIncludes @('*o*') -WhatIf:$whatIf;

        $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
        Test-Path -Path $testPath | Should -BeTrue -Because "Path: $testPath does not exist";
      }
    }

    Context 'and: File copy specified without directory creation' {
      It 'should: still copy matching files' {
        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CopyFiles -FileIncludes @('cover.*') `
          -DirectoryIncludes @('*o*') -WhatIf:$whatIf;

        $testPath = Join-Path -Path $destinationPath -ChildPath 'Audio';
        Test-Path -Path $testPath | Should -BeTrue -Because "Path $testPath does not exist";

        $coverFile = Join-Path -Path $destinationPath `
          -ChildPath 'Audio\GOTHIC\Fields Of The Nephilim\Earth Inferno\cover.fotn.earth-inferno.jpg.txt';
        Test-Path -Path $coverFile | Should -BeTrue -Because "Path $coverFile does not exist";

        $excludedPath = Join-Path -Path $destinationPath `
          -ChildPath 'Audio\MINIMAL\FUSE\Dimension Intrusion\cover.fuse.dimension-instrusion.jpg.txt';
        Test-Path -Path $excludedPath | Should -BeFalse -Because "'MINIMAL' has not been included";
      }
    }
  } # given: Include file filters applied

  Context 'given: HoistDescendent specified' {
    Context 'and: Include directory filters applied' {
      It 'Should: traverse creating files and hoisted descendant directories' {
        [scriptblock]$sessionSummary = {
          param(
            [int]$_count,
            [int]$_skipped,
            [int]$_errors,
            [boolean]$_triggered,
            [hashtable]$_exchange
          )

          $_count | Should -Be 11;
        }

        [hashtable]$verifiedCountPassThru = @{}

        Invoke-MirrorDirectoryTree -Path $sourcePath `
          -DestinationPath $destinationPath -CreateDirs -DirectoryIncludes @('*e*') `
          -Hoist -SessionSummary $sessionSummary -Exchange $verifiedCountPassThru -WhatIf:$whatIf;
      }
    }
  } # given: HoistDescendent specified
} # Invoke-MirrorDirectoryTree
