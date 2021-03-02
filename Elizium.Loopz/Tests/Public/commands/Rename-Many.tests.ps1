using namespace System.Management.Automation;
using namespace System.Collections;
using namespace System.IO;
using namespace System.Text;
using module Elizium.Krayola;
using module Elizium.Klassy;

Describe 'Rename-Many' -Tag 'remy' {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking

    Import-Module Assert;
    [boolean]$script:whatIf = $false;

    [string]$script:directoryPath = './Tests/Data/fefsi/';

    Mock -ModuleName Elizium.Loopz rename-FsItem {
      param(
        [FileSystemInfo]$From,
        [string]$To,
        [UndoRename]$UndoOperant
      )

      #
      # This mock result works only because the actual returned FileSystemInfo returned
      # does not drive any control logic.

      if ($expected) {
        # NOTE: Since this rename-FsItem mock is only invoked, if there is actually a rename to be
        # performed, expectations do not need (or rather should not) add expectations for scenarios
        # where the new name is the same as the original name (ie not renamed due to a non match).
        #
        test-expect -Expects $expected -Item $From.Name -Actual $To;
      }
      return $To;
    }

    Mock -ModuleName Elizium.Loopz Get-IsLocked {
      return $true;
    }

    function test-expect {
      param(
        [Parameter(Position = 0)][HashTable]$Expects,
        [Parameter(Position = 1)][string]$Item,
        [Parameter(Position = 2)][string]$Actual
      )
      if ($Expects.ContainsKey($Item)) {
        Write-Debug "test-expect; EXPECT: '$($Expects[$Item])'";
        Write-Debug "test-expect; ACTUAL: '$Actual'";
        $Actual | Should -BeExactly $Expects[$Item];
      }
      else {
        $false | Should -BeTrue -Because "Bad test!!, Item: '$Item' not defined in Expects";
      }
    }
  }

  BeforeEach {
    $script:expected = $null;
  }

  # All these tests should be converted to work on a copy of the test files. Or perhaps, we can get
  # Rename-Many to invoke an internal function, so that the new name can be intercepted and tested.
  # No, you just need to intercept rename-FsItem
  #
  Context 'given: MoveToAnchor' {
    Context 'and: TargetType is Anchor' {
      Context 'and Relation is Before' {
        Context 'and: Source matches Pattern' {
          Context 'and: Source matches Anchor' {
            It 'should: do rename; move Pattern match before Anchor' {
              $script:expected = @{
                'loopz.data.t1.txt' = 'data.loopz.t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'data.' -Anchor 'loopz' -Relation 'before' -WhatIf;
            }

            It 'should: do rename; move Pattern match before Anchor and Drop' {
              $script:expected = @{
                'loopz.data.t1.txt' = 'data.loopz.-t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.-t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.-t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'data.' -Anchor 'loopz' -Relation 'before' -Drop '-' -WhatIf;
            }
          } # and: Source matches Anchor

          Context 'and: Whole Pattern' {
            It 'should: do rename; move Pattern match before Anchor' {
              $script:expected = @{
                'loopz.data.t1.txt' = 'dataloopz..t1.txt';
                'loopz.data.t2.txt' = 'dataloopz..t2.txt';
                'loopz.data.t3.txt' = 'dataloopz..t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'data' -Anchor 'loopz' -Relation 'before' -Whole p -WhatIf;
            }
          }

          Context 'and: Source matches Last Anchor' {
            It 'should: do rename; move Pattern match before Last Anchor' {
              $script:expected = @{
                'loopz.application.t1.log' = 'applicloopz.ation.t1.log';
                'loopz.application.t2.log' = 'applicloopz.ation.t2.log';
                'loopz.data.t1.txt'        = 'datloopz.a.t1.txt';
                'loopz.data.t2.txt'        = 'datloopz.a.t2.txt';
                'loopz.data.t3.txt'        = 'datloopz.a.t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor 'a', l -Relation 'before' -WhatIf;
            }

            Context 'and: top 2' {
              It 'should: process the first 2 items only' {
                $script:expected = @{
                  'loopz.application.t1.log' = 'applicloopz.ation.t1.log';
                  'loopz.application.t2.log' = 'applicloopz.ation.t2.log';
                }

                Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                  -Pattern 'loopz.' -Anchor 'a', l -Relation 'before' -Top 2 -WhatIf;
              }
            } 
          }

          Context 'and: Source matches Pattern, but differs by case' {
            It 'should: do rename; move Pattern match before Anchor' {
              $script:expected = @{
                'loopz.data.t1.txt' = 'data.loopz.t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'DATA\./i' -Anchor 'loopz' -Relation 'before' -WhatIf;
            }
          }

          Context 'and: Source does not match Anchor' {
            It 'should: NOT do rename' {
              $script:expected = @{
                'loopz.data.t1.txt' = 'loopz.data.t1.txt';
                'loopz.data.t2.txt' = 'loopz.data.t2.txt';
                'loopz.data.t3.txt' = 'loopz.data.t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'data.' -Anchor 'blooper' -Relation 'before' -WhatIf;
            }
          }
        } # and: Source matches Pattern

        Context 'and: Transform' {
          It 'should: transform Rename' -Tag 'INVALID' -Skip { # Transform only allowed with InPlace not move with Anchor
            $script:expected = @{
              'loopz.application.t1.log' = '_applicloopz.ation.t1_.log';
              'loopz.application.t2.log' = '_applicloopz.ation.t2_.log';
              'loopz.data.t1.txt'        = '_datloopz.a.t1_.txt';
              'loopz.data.t2.txt'        = '_datloopz.a.t2_.txt';
              'loopz.data.t3.txt'        = '_datloopz.a.t3_.txt';
            }

            [scriptblock]$transform = [scriptblock] {
              param(
                [string]$Original,
                [string]$Renamed,
                [string]$PatternCapture
              )

              return $("_{0}_" -f $Renamed);
            }

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern 'loopz.' -Anchor 'a', l -Relation 'before' -Transform $transform -WhatIf;
          }
        }
      } # and Relation is Before

      Context 'and Relation is After' {
        Context 'and: Source matches Pattern' {
          Context 'and: Source matches Anchor' {
            It 'should: do rename; move Pattern match after Anchor' {
              $script:expected = @{
                'loopz.data.t1.txt' = 'data.loopz.t1.txt';
                'loopz.data.t2.txt' = 'data.loopz.t2.txt';
                'loopz.data.t3.txt' = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor 'data.' -Relation 'after' -WhatIf;
            }

            Context 'and: Whole Anchor' {
              It 'should: do rename; move Pattern match after Anchor' {
                $script:expected = @{
                  'loopz.data.t1.txt' = 'dataloopz..t1.txt';
                  'loopz.data.t2.txt' = 'dataloopz..t2.txt';
                  'loopz.data.t3.txt' = 'dataloopz..t3.txt';
                }

                Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                  -Pattern 'loopz.' -Anchor 'data' -Relation 'after' -Whole a -WhatIf;
              }
            }
          } # and: Source matches Anchor

          Context 'and: Source matches Last Anchor' {
            It 'should: do rename; move Pattern match after Last Anchor' {
              $script:expected = @{
                'loopz.application.t1.log' = 'application.loopz.t1.log';
                'loopz.application.t2.log' = 'application.loopz.t2.log';
                'loopz.data.t1.txt'        = 'data.loopz.t1.txt';
                'loopz.data.t2.txt'        = 'data.loopz.t2.txt';
                'loopz.data.t3.txt'        = 'data.loopz.t3.txt';
              }

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor '\.', l -Relation 'after' -WhatIf;
            }
          }

          Context 'and: Source does not match Anchor' {
            It 'should: NOT do rename' {
              $script:expected = @{}
              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern 'loopz.' -Anchor 'blooper' -Relation 'after' -WhatIf;
            }
          }
        } # and: Source matches Pattern
      } # and Relation is After
    } # and: TargetType is Anchor

    Context 'and: Hybrid Anchor' -Skip {
      # Hybrid just means Anchor specified with either Start or End
      #
      Context 'and: Anchor matches Pattern' {
        Context 'and: Start specified' {
          It 'should: ignore Start and move to Anchor' {
            $script:expected = @{
              'loopz.data.t1.txt' = 'data.loopz.t1.txt';
              'loopz.data.t2.txt' = 'data.loopz.t2.txt';
              'loopz.data.t3.txt' = 'data.loopz.t3.txt';
            }

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern 'data.' -Anchor 'loopz' -Start -Relation 'before' -WhatIf;
          }
        }

        Context 'and: End specified' {
          It 'should: ignore End and move to Anchor' {
            $script:expected = @{
              'loopz.data.t1.txt' = 'data.loopz.t1.txt';
              'loopz.data.t2.txt' = 'data.loopz.t2.txt';
              'loopz.data.t3.txt' = 'data.loopz.t3.txt';
            }

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern 'data.' -Anchor 'loopz' -End -Relation 'before' -WhatIf;
          }
        }
      } # and: Anchor matches Pattern

      Context 'and: Anchor does NOT match Pattern' {
        Context 'and: Start specified' {
          It 'should: move to start' {
            $script:expected = @{
              'loopz.application.t1.log' = 't1.loopz.application.log';
              'loopz.application.t2.log' = 't2.loopz.application.log';
              'loopz.data.t1.txt'        = 't1.loopz.data.txt';
              'loopz.data.t2.txt'        = 't2.loopz.data.txt';
              'loopz.data.t3.txt'        = 't3.loopz.data.txt';
            }

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern '\.(?<tail>t\d)' -Anchor 'blooper' -Start -Paste '${tail}' -WhatIf;
          }
        }

        Context 'and: End specified' {
          It 'should: move to end' {
            $script:expected = @{
              'loopz.application.t1.log' = 'application.t1.loopz.log';
              'loopz.application.t2.log' = 'application.t2.loopz.log';
              'loopz.data.t1.txt'        = 'data.t1.loopz.txt';
              'loopz.data.t2.txt'        = 'data.t2.loopz.txt';
              'loopz.data.t3.txt'        = 'data.t3.loopz.txt';
            }

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern '(?<header>loopz)\.' -Anchor 'blooper' -End -Paste '.${header}' -WhatIf;
          }
        }
      } #
    } # and: Hybrid Anchor
  } # given: MoveToAnchor

  Context 'given: MoveToStart' {
    Context 'and: Source matches Pattern in middle' {
      It 'should: do rename; move Pattern match to start' {
        $script:expected = @{
          'loopz.data.t1.txt' = 'data.loopz.t1.txt';
          'loopz.data.t2.txt' = 'data.loopz.t2.txt';
          'loopz.data.t3.txt' = 'data.loopz.t3.txt';
        }
        Get-ChildItem -Path $directoryPath -Filter '*.txt' | Rename-Many -File `
          -Pattern 'data.' -Start -WhatIf;
      }
    } # and: Source matches Pattern in middle

    Context 'and: Source matches Pattern already at start' {
      It 'should: NOT do rename' {
        $script:expected = @{}
        Get-ChildItem -Path $directoryPath -Filter '*.txt' | Rename-Many -File `
          -Pattern 'loopz.' -Start -WhatIf;
      }
    } # and: Source matches Pattern in middle
  } # given: MoveToStart

  Context 'given: MoveToEnd' {
    Context 'and: Source matches Pattern in middle' {
      It 'should: do rename; move Pattern match to end' {
        $script:expected = @{
          'loopz.data.t1.txt' = 'loopz.t1.data.txt';
          'loopz.data.t2.txt' = 'loopz.t2.data.txt';
          'loopz.data.t3.txt' = 'loopz.t3.data.txt';
        }
        Get-ChildItem -Path $directoryPath -File | Rename-Many -File `
          -Pattern '.data' -End -WhatIf;
      }
    }

    Context 'and: Source matches Pattern already at end' {
      It 'should: NOT do rename' {
        $script:expected = @{}
        Get-ChildItem -Path $directoryPath | Rename-Many -File `
          -Pattern 't1' -End -WhatIf;
      }
    } # and: Source matches Pattern in middle
  } # given: MoveToEnd

  Context 'given: Prepend' {
    It 'should: prepend literal text' {
      $script:expected = @{
        'loopz.application.t1.log' = 'PREFIX-loopz.application.t1.log';
        'loopz.application.t2.log' = 'PREFIX-loopz.application.t2.log';
        'loopz.data.t1.txt'        = 'PREFIX-loopz.data.t1.txt';
        'loopz.data.t2.txt'        = 'PREFIX-loopz.data.t2.txt';
        'loopz.data.t3.txt'        = 'PREFIX-loopz.data.t3.txt';
      }

      Get-ChildItem -Path $directoryPath -File | Rename-Many -Prepend 'PREFIX-' -WhatIf;
    }

    It 'should: prepend literal text' {
      $script:expected = @{
        'loopz.application.t1.log' = 't1_PREFIX-loopz.application.t1.log';
        'loopz.application.t2.log' = 't2_PREFIX-loopz.application.t2.log';
        'loopz.data.t1.txt'        = 't1_PREFIX-loopz.data.t1.txt';
        'loopz.data.t2.txt'        = 't2_PREFIX-loopz.data.t2.txt';
        'loopz.data.t3.txt'        = 't3_PREFIX-loopz.data.t3.txt';
      }

      [string]$copy = '(?<header>[\w]+)\.(?<mid>[\w]+).(?<tail>[\w]+)';
      Get-ChildItem -Path $directoryPath -File | Rename-Many -Prepend '${tail}_PREFIX-' `
        -Copy $copy -Diagnose;
    }

    Context 'and: Copy does not match' {
      It 'should: not rename' {
        $script:expected = @{}

        [string]$copy = 'blah';
        Get-ChildItem -Path $directoryPath -File | Rename-Many -Prepend '${tail}_PREFIX-' `
          -Copy $copy -Diagnose;
      }
    }
  }

  Context 'given: Append' {
    It 'should: append literal text' {
      $script:expected = @{
        'loopz.application.t1.log' = 'loopz.application.t1-POSTFIX.log';
        'loopz.application.t2.log' = 'loopz.application.t2-POSTFIX.log';
        'loopz.data.t1.txt'        = 'loopz.data.t1-POSTFIX.txt';
        'loopz.data.t2.txt'        = 'loopz.data.t2-POSTFIX.txt';
        'loopz.data.t3.txt'        = 'loopz.data.t3-POSTFIX.txt';
      }

      Get-ChildItem -Path $directoryPath -File | Rename-Many -Append '-POSTFIX' -WhatIf;
    }

    It 'should: append literal text' {
      $script:expected = @{
        'loopz.application.t1.log' = 'loopz.application.t1-POSTFIX_t1.log';
        'loopz.application.t2.log' = 'loopz.application.t2-POSTFIX_t2.log';
        'loopz.data.t1.txt'        = 'loopz.data.t1-POSTFIX_t1.txt';
        'loopz.data.t2.txt'        = 'loopz.data.t2-POSTFIX_t2.txt';
        'loopz.data.t3.txt'        = 'loopz.data.t3-POSTFIX_t3.txt';
      }

      [string]$copy = '(?<header>[\w]+)\.(?<mid>[\w]+).(?<tail>[\w]+)';
      Get-ChildItem -Path $directoryPath -File | Rename-Many -Append '-POSTFIX_${tail}' `
        -Copy $copy -Diagnose;
    }

    Context 'and: Copy does not match' {
      It 'should: not rename' {
        $script:expected = @{}

        [string]$copy = 'foo';
        Get-ChildItem -Path $directoryPath -File | Rename-Many -Append '-POSTFIX_${tail}' `
          -Copy $copy -Diagnose;
      }
    }
  }

  Context 'given: ReplaceWith' {
    Context 'and: Source matches Pattern' {
      Context 'and: Copy is non-regex static text' -Skip {
        # It seems like this makes no sense; there's no point in testing static -Copy text as
        # in reality, the user should use -With. However, the user might use -Copy for
        # static text and if they do, there's no reason why it shouldn't just work, even though
        # With is designed for this scenario.
        #

        Context 'Copy does NOT match' {
          It 'should: do rename; replace First Pattern for Copy text' -Tag 'INVALID' -Skip {
            $script:expected = @{}

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy 'bar' -WhatIf;
          }
        }

        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' -Tag 'INVALID' -Skip {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.tpplication.t1.log';
              'loopz.application.t2.log' = 'loopz.tpplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dtta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dtta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dtta.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy 't' -WhatIf;
          }
        } # and: First Only

        Context 'and: replace 3rd match' {
          It 'should: do rename; replace 3rd Occurrence for Copy text' -Tag 'INVALID' -Skip {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.applicati0n.t1.log';
              'loopz.application.t2.log' = 'loopz.applicati0n.t2.log';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'o', 3 -Copy '0' -WhatIf;
          }
        } # and: replace 3rd match

        Context 'and: Last Only' {
          It 'should: do rename; replace Last Pattern for Copy text' -Tag 'INVALID' -Skip {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.applic@tion.t1.log';
              'loopz.application.t2.log' = 'loopz.applic@tion.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dat@.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dat@.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dat@.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', l -With '@' -WhatIf;
          }
        } # and: Last Only
      } # and: Copy is non-regex static text

      Context 'and: Copy is regex' {
        Context 'and: Whole Copy' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.t1pplication.t1.log';
              'loopz.application.t2.log' = 'loopz.t2pplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dt1ta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dt2ta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dt3ta.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy 't\d' -Paste '${_c}' -Whole c -WhatIf;
          }
        } # and: Whole Copy

        Context 'and: Source matches Last Copy' {
          It 'should: do rename; replace Pattern match with Last Copy' {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.(ca)-application.t1.log';
              'loopz.application.t2.log' = 'loopz.(ca)-application.t2.log';
              'loopz.data.t1.txt'        = 'loopz.(ta)-data.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.(ta)-data.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.(ta)-data.t3.txt';
            }

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern 'loopz.' -Copy '\wa', l -Paste '$0(${_c})-' -WhatIf;
          }
        }

        Context 'Copy does NOT match' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:expected = @{}

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy '\d{4}' -Paste '${_c}' -WhatIf;
          }
        }

        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.t1pplication.t1.log';
              'loopz.application.t2.log' = 'loopz.t2pplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.dt1ta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.dt2ta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.dt3ta.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy 't\d' -Paste '${_c}' -WhatIf;
          }
        } # and: First Only
      } # and: Copy is regex

      Context 'and: Copy needs escape' {
        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz..pplpplication.t1.log';
              'loopz.application.t2.log' = 'loopz..pplpplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.d.dtata.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.d.dtata.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.d.dtata.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Copy ($(esc('.')) + '\w{3}') -Paste '${_c}' -WhatIf;
          }
        } # and: First Only
      } # and: Copy needs escapes

      Context 'With' -Skip { # Paste
        Context 'and: First Only' {
          It 'should: do rename; replace First Pattern for Copy text' {
            $script:expected = @{
              'loopz.application.t1.log' = 'loopz.@pplication.t1.log';
              'loopz.application.t2.log' = 'loopz.@pplication.t2.log';
              'loopz.data.t1.txt'        = 'loopz.d@ta.t1.txt';
              'loopz.data.t2.txt'        = 'loopz.d@ta.t2.txt';
              'loopz.data.t3.txt'        = 'loopz.d@ta.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Paste '@' -WhatIf;
          }

          Context 'and: replace 3rd match' {
            It 'should: do rename; replace 3rd Occurrence for Copy text' {
              $script:expected = @{
                'loopz.application.t1.log' = 'loopz.applicati0n.t1.log';
                'loopz.application.t2.log' = 'loopz.applicati0n.t2.log';
              }

              Get-ChildItem -Path $directoryPath | Rename-Many -File `
                -Pattern 'o', 3 -Paste '0' -WhatIf;
            }
          } # and: replace 3rd match

          Context 'and: Last Only' {
            It 'should: do rename; replace Last Pattern for Copy text' {
              $script:expected = @{
                'loopz.application.t1.log' = 'loopz.applic@tion.t1.log';
                'loopz.application.t2.log' = 'loopz.applic@tion.t2.log';
                'loopz.data.t1.txt'        = 'loopz.dat@.t1.txt';
                'loopz.data.t2.txt'        = 'loopz.dat@.t2.txt';
                'loopz.data.t3.txt'        = 'loopz.dat@.t3.txt';
              }

              Get-ChildItem -Path $directoryPath | Rename-Many -File `
                -Pattern 'a', l -Paste '@' -WhatIf;
            }
          } # and: Last Only
        } # and: First Only

        Context 'and: Transform' {
          It 'should: transform Rename' -Tag 'Bug' {
            $script:expected = @{
              'loopz.application.t1.log' = '_loopz.@pplication.t1_.log';
              'loopz.application.t2.log' = '_loopz.@pplication.t2_.log';
              'loopz.data.t1.txt'        = '_loopz.d@ta.t1_.txt';
              'loopz.data.t2.txt'        = '_loopz.d@ta.t2_.txt';
              'loopz.data.t3.txt'        = '_loopz.d@ta.t3_.txt';
            }

            [scriptblock]$transform = [scriptblock] {
              param(
                [string]$Original,
                [string]$Renamed,
                [string]$PatternCapture
              )

              return $("_{0}_" -f $Renamed);
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'a', f -Paste '@' -Transform $transform -WhatIf;
          }
        }
      } # With

      Context 'and: Except' {
        Context 'and: Source matches Pattern' {
          It 'should: do rename; replace Last Pattern for Copy text, Except excluded items' {
            $script:expected = @{
              'loopz.application.t1.log' = 'h00pz.application.t1.log';
              'loopz.application.t2.log' = 'h00pz.application.t2.log';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'loopz' -Except 'data' -Copy 'h00pz' -Paste '${_c}' -WhatIf;
          }
        }
      } # and: Except

      Context 'and: Include' {
        Context 'and: Source matches Pattern' {
          It 'should: do rename; replace Last Pattern for Copy text, for Include items only' {
            $script:expected = @{
              'loopz.data.t1.txt' = 'loopz.dat@.t1.txt';
              'loopz.data.t2.txt' = 'loopz.dat@.t2.txt';
              'loopz.data.t3.txt' = 'loopz.dat@.t3.txt';
            }

            Get-ChildItem -Path $directoryPath | Rename-Many -File `
              -Pattern 'loopz' -Include 'data' -Copy 'h00pz' -Paste '${_c}' -WhatIf;
          }
        }
      } # and: Except

      Context 'and: Context' {
        It 'should: show the Context' {
          $script:expected = @{
            'loopz.application.t1.log' = 'loopz.applic@tion.t1.log';
            'loopz.application.t2.log' = 'loopz.applic@tion.t2.log';
            'loopz.data.t1.txt'        = 'loopz.dat@.t1.txt';
            'loopz.data.t2.txt'        = 'loopz.dat@.t2.txt';
            'loopz.data.t3.txt'        = 'loopz.dat@.t3.txt';
          }

          [PSCustomObject]$context = [PSCustomObject]@{
            Title             = 'TITLE';
            ItemMessage       = 'Widget *{_fileSystemItemType}';
            SummaryMessage    = '... and finally';
            Locked            = 'LOOPZ_REMY_LOCKED';
            UndoDisabledEnVar = 'LOOPZ_REMY_UNDO_DISABLED';
          }

          Get-ChildItem -Path $directoryPath | Rename-Many -Context $context -File `
            -Pattern 'a', l -Paste '@' -WhatIf;
        }
      }

      Context 'and: "Cut" (without replacement)' { # New Cut param
        It 'should: do rename; cut the Pattern' -Tag 'INVALID', 'Cut' -Skip {
          $script:expected = @{
            'loopz.application.t1.log' = 'application.t1.log';
            'loopz.application.t2.log' = 'application.t2.log';
            'loopz.data.t1.txt'        = 'data.t1.txt';
            'loopz.data.t2.txt'        = 'data.t2.txt';
            'loopz.data.t3.txt'        = 'data.t3.txt';
          }

          Get-ChildItem -Path $directoryPath | Rename-Many -File `
            -Pattern $(esc('loopz.')) -WhatIf;
        }
      } # and: "Cut" (without replacement)

      Context 'and: Source denotes Directories' {
        It 'should: do rename; replace First Pattern for Copy text' {
          $script:expected = @{
            'Arkives'   = 'Arkiv3s';
            'Consumed'  = 'Consum3d';
            'EX'        = '3X';
            # 'Musik'     = 'Musik';
            'Sheet One' = 'Sh3et One';
          }
          [string]$plastikmanPath = './Tests/Data/traverse/Audio/MINIMAL/Plastikman';

          Get-ChildItem -Path $plastikmanPath | Rename-Many -Directory `
            -Pattern 'e' -Copy '3' -Paste '${_c}' -WhatIf;
        }
      }
    } # and: Source matches Pattern
  } # given: ReplaceWith

  Context 'given: Diagnose enabled' { # THESE TESTS ARE IN WRONG SECTION
    Context 'MoveToAnchor' {
      Context 'and: Source matches with Named Captures' -Tag 'RE-WRITE' -Skip { # Paste/Anchor not compatible
        Context 'and: Copy matches' {
          Context 'and: Anchor matches' {
            It 'should: do rename; move Pattern match with Copy capture' {
              $script:expected = @{
                'loopz.application.t1.log' = 'application.BEGIN-.t1-application.-loopz-END.log';
                'loopz.application.t2.log' = 'application.BEGIN-.t2-application.-loopz-END.log';
                'loopz.data.t1.txt'        = 'data.BEGIN-.t1-data.-loopz-END.txt';
                'loopz.data.t2.txt'        = 'data.BEGIN-.t2-data.-loopz-END.txt';
                'loopz.data.t3.txt'        = 'data.BEGIN-.t3-data.-loopz-END.txt';
              }

              [string]$pattern = '^(?<header>[\w]+)\.';
              [string]$anchor = '\.(?<tail>t\d)';
              [string]$copy = '(?<body>[\w]+)\.';
              [string]$paste = '.BEGIN-${_a}-${_c}-${header}-END';

              Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                -Pattern $pattern -Copy $copy -Anchor $anchor -Relation 'after' -Paste $paste -WhatIf -Diagnose;
            }

            Context 'and: Drop' {
              It 'should: do rename; move Pattern match with Copy capture' {
                $script:expected = @{
                  'loopz.application.t1.log' = '[loopz, application.]_application.BEGIN-.t1-application.-loopz-END.log';
                  'loopz.application.t2.log' = '[loopz, application.]_application.BEGIN-.t2-application.-loopz-END.log';
                  'loopz.data.t1.txt'        = '[loopz, data.]_data.BEGIN-.t1-data.-loopz-END.txt';
                  'loopz.data.t2.txt'        = '[loopz, data.]_data.BEGIN-.t2-data.-loopz-END.txt';
                  'loopz.data.t3.txt'        = '[loopz, data.]_data.BEGIN-.t3-data.-loopz-END.txt';
                }

                [string]$pattern = '^(?<header>[\w]+)\.';
                [string]$anchor = '\.(?<tail>t\d)';
                [string]$copy = '(?<body>[\w]+)\.';
                [string]$paste = '.BEGIN-${_a}-${_c}-${header}-END';

                Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
                  -Pattern $pattern -Copy $copy -Anchor $anchor -Relation 'after' -Paste $paste `
                  -Diagnose -Drop '[${header}, ${_c}]_';
              }
            }
          }
        }

        Context 'and: Copy match does NOT match source' {
          It 'should: show Copy match failure' {
            [string]$pattern = '^(?<header>[\w]+)\.';
            [string]$anchor = '\.(?<tail>t\d)';
            [string]$copy = 'blooper';
            [string]$paste = '.BEGIN-${_a}-${_c}-${header}-END';

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern $pattern -Copy $copy -Anchor $anchor -Relation 'after' -Paste $paste -WhatIf -Diagnose;
          }
        } # and: Source match does NOT match Pattern
      } # and: Source matches with Named Captures
    } # MoveToAnchor

    Context 'ReplaceWith' {
      Context 'and: Source matches with Named Captures' {
        Context 'and: Copy matches' {
          It 'should: do rename; move Pattern match with Copy capture' {
            $script:expected = @{
              'loopz.application.t1.log' = 'BEGIN-.t1-loopz-application-END.t1.log';
              'loopz.application.t2.log' = 'BEGIN-.t2-loopz-application-END.t2.log';
              'loopz.data.t1.txt'        = 'BEGIN-.t1-loopz-data-END.t1.txt';
              'loopz.data.t2.txt'        = 'BEGIN-.t2-loopz-data-END.t2.txt';
              'loopz.data.t3.txt'        = 'BEGIN-.t3-loopz-data-END.t3.txt';
            }

            [string]$pattern = '^(?<header>[\w]+)\.(?<body>[\w]+)';
            [string]$copy = '\.(?<tail>t\d)'
            [string]$paste = 'BEGIN-${_c}-${header}-${body}-END';

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern $pattern -Copy $copy -Paste $paste -WhatIf -Diagnose;
          }

          It 'should: do rename; move Pattern match with Copy capture' {
            $script:expected = @{
              'loopz.application.t1.log' = 'BEGIN-.t1-loopz-application-END.t1.log';
              'loopz.application.t2.log' = 'BEGIN-.t2-loopz-application-END.t2.log';
              'loopz.data.t1.txt'        = 'BEGIN-.t1-loopz-data-END.t1.txt';
              'loopz.data.t2.txt'        = 'BEGIN-.t2-loopz-data-END.t2.txt';
              'loopz.data.t3.txt'        = 'BEGIN-.t3-loopz-data-END.t3.txt';
            }

            [string]$pattern = '^(?<header>[\w]+)\.(?<body>[\w]+)';
            [string]$copy = '\.(?<tail>[\w]+)'
            [string]$paste = 'BEGIN-${_c}-${header}-${body}-END';

            Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
              -Pattern $pattern -Copy $copy -Paste $paste -WhatIf -Diagnose;
          }
        }
      }

      Context 'and: accidental/incorrect escape' {
        Context 'and: invalid With' {
          It 'should: throw' {
            {
              Get-ChildItem -Path $directoryPath | Rename-Many -File `
                -Pattern 'o', 3 -With $(esc('(name)')) -Anchor 'z' -WhatIf;
            } | Should -Throw;
          }
        }

        Context 'and: invalid Paste' {
          It 'should: throw' {
            {
              Get-ChildItem -Path $directoryPath | Rename-Many -File `
                -Pattern 'o', 3 -Paste $(esc('(o)')) -WhatIf;
            } | Should -Throw;
          }
        }
      }
    } # ReplaceWith
  } # given: Diagnose enabled

  Context 'given: invalid Pattern expression' {
    It 'should: throw' {
      {
        [string]$badPattern = '(((';
        Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
          -Pattern $badPattern -Anchor 'loopz' -Relation 'before' -WhatIf;
      } | Should -Throw;
    }
  } # given: invalid Pattern expression

  Context 'given: invalid Copy expression' {
    It 'should: throw' {
      {
        [string]$badWith = '(((';
        Get-ChildItem -Path $directoryPath | Rename-Many -File `
          -Pattern 'o', 3 -Copy $badWith -Paste '${_c}' -WhatIf;
      } | Should -Throw;
    }
  } # given: invalid Copy expression

  Context 'given: invalid Anchor expression' {
    It 'should: throw' {
      {
        [string]$badAnchor = '(((';
        Get-ChildItem -File -Path $directoryPath | Rename-Many -File `
          -Pattern 'data.' -Anchor $badAnchor -Relation 'before' -WhatIf;

      } | Should -Throw;
    }
  } # given: invalid Anchor expression
} # Rename-Many

Describe 'Rename-Many parameter sets' -Tag 'remy' {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking;

    InModuleScope Elizium.Loopz {
      [hashtable]$script:_signals = Get-Signals;
      [hashtable]$script:_theme = Get-KrayolaTheme;
    }
  }

  BeforeEach {
    InModuleScope Elizium.Loopz {
      [StringBuilder]$script:_builder = [StringBuilder]::new();
      [krayon]$script:_krayon = New-Krayon -Theme $_theme;

      [string]$commandName = 'Rename-Many';
      [DryRunner]$script:_runner = New-DryRunner -CommandName $commandName `
        -Signals $_signals -Krayon $_krayon;
    }
  } # BeforeEach

  context 'given: using DryRunner' {
    Context 'given: Valid Parameter Set' {
      It 'should: resolve <parameters> to <paramSet>' -Tag 'Current' -TestCases @(
        # MoveToAnchor
        #
        @{ Parameters = 'underscore', 'Pattern', 'Anchor';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'With';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'Drop';
          ParamSet    = 'MoveToAnchor' 
        },
        @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'With', 'Relation';
          ParamSet    = 'MoveToAnchor' 
        }
        # ReplacePaste
        #
        # @{ Parameters = 'underscore', 'Pattern', 'Anchor', 'Paste';
        #   ParamSet    = 'ReplacePaste' 
        # }
      ) {
        InModuleScope -ModuleName Elizium.Loopz -Parameters @{ Parameters = $parameters; ParamSet = $paramSet } {
          param(
            $Parameters, $ParamSet
          )
          [CommandParameterSetInfo[]]$paramSets = $_runner.Resolve($Parameters);
          $paramSets.Count | Should -Be 1 -Because "of [$($Parameters -join ', ')]";
          $paramSets[0].Name | Should -Be $ParamSet;
        }
      }
    } # given: Valid Parameter Set
  } # given: using DryRunner

} # Rename-Many parameter sets

Describe 'Rename-Many' -Skip {
  BeforeAll {
    Get-Module Elizium.Loopz | Remove-Module
    Import-Module .\Output\Elizium.Loopz\Elizium.Loopz.psm1 `
      -ErrorAction 'stop' -DisableNameChecking

    Import-Module Assert;
    [boolean]$script:whatIf = $false;

    [string]$script:directoryPath = './Tests/Data/fefsi/';

    # Mock -ModuleName Elizium.Loopz rename-FsItem {
    #   param(
    #     [FileSystemInfo]$From,
    #     [string]$To,
    #     [HashTable]$Undo,
    #     $Shell,
    #     [switch]$WhatIf
    #   )
    #   return $To;
    # }
  }

  Context 'given: Parameter Set' {
    [string]$script:sourcePath = './Tests/Data/fefsi';
    [string]$script:filter = 'bling.*';
    [scriptblock]$script:successCondition = ( { return $true; })

    Context 'is: valid' {
      Context 'MoveToAnchor' {
        It 'should: not throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Whole p -Pattern 'data.' -Anchor 't\d{1}\.' -Copy 'repl' -Except 'fake' `
              -Condition $successCondition -Relation 'before' -WhatIf:$whatIf; } `
          | Should -Not -Throw;
        }

        Context 'and: Hybrid Anchor' -Skip {
          It 'should: not throw ParameterBindingException' {
            {
              Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
                -Whole p -Pattern 'data.' -Anchor 't\d{1}\.' -Start -Copy 'repl' -Except 'fake' `
                -Condition $successCondition -Relation 'before' -WhatIf:$whatIf; } `
          | Should -Not -Throw;
          }

          It 'should: not throw ParameterBindingException' {
            {
              Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
                -Whole p -Pattern 'data.' -Anchor 't\d{1}\.' -End -Copy 'repl' -Except 'fake' `
                -Condition $successCondition -Relation 'before' -WhatIf:$whatIf; } `
          | Should -Not -Throw;
          }
        }
      } # MoveToAnchor

      Context 'MoveToStart' {
        It 'should: not throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Whole p -Pattern 'data.' -Start -Copy 'repl' -Except 'fake' -Condition $successCondition `
              -WhatIf:$whatIf; } `
          | Should -Not -Throw;
        }
      } # MoveToStart

      Context 'MoveToEnd' {
        It 'should: not throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Whole p -Pattern 'data.' -End -Copy 'repl' -Except 'fake' -Condition $successCondition `
              -WhatIf:$whatIf; } `
          | Should -Not -Throw;
        }
      } # MoveToEnd

      Context 'ReplaceWith' {
        It 'should: not throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Whole p -Pattern 'data.' -Copy 'info.' -Except 'fake' `
              -Condition $successCondition -WhatIf:$whatIf; } `
          | Should -Not -Throw;
        }
      } # ReplaceWith

      Context 'Prepend' {
        It 'should: not throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Prepend 'pre-fix_${_c}_' -Copy '.', f -WhatIf:$whatIf; } `
          | Should -Not -Throw;
        }
      }

      Context 'Append' {
        It 'should: not throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Append '${_c}_post-fix' -Copy '.', l -WhatIf:$whatIf; } `
          | Should -Not -Throw;
        }
      }
    } # is: valid

    Context 'is not: valid (MoveToAnchor)' { #Is this a valid test, First doesn't exist
      Context 'and: "First" specified' {
        # Since the default behaviour of move, is to move the token after the
        # first match of the pattern, it does not need to be specified for the move token
        # operation.
        #
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -Anchor 't\d{1}\.' -First -WhatIf:$whatIf;
          } | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      }
    } # is not: valid

    Context 'is not: valid (MoveToStart)' {
      Context 'and: "Relation" specified' {
        It 'should: ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -Start -Relation 'after' -Whole p -Condition $successCondition -WhatIf:$whatIf; } `
          | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      } # and: "Relation" specified

      Context 'and: "End" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -Start -End -WhatIf:$whatIf;
          } | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      } # and: "End" specified

      Context 'and: "Anchor" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -Start -Anchor 't\d{1}\.' -WhatIf:$whatIf;
          } | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      } # and: "Anchor" specified
    } # is not: valid (MoveToStart)

    Context 'is not: valid (MoveToEnd)' {
      Context 'and: "Relation" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -End -Relation 'after' -Whole p -Condition $successCondition -WhatIf:$whatIf; } `
          | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      } # and: "Relation" specified

      Context 'and: "Start" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -Start -End -WhatIf:$whatIf;
          } | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      } # and: "Start" specified

      Context 'and: "Anchor" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'data.' -End -Anchor 't\d{1}\.' -WhatIf:$whatIf;
          } | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      } # and: "Anchor" specified
    } # is not: valid (MoveToEnd)

    Context 'is not: valid (Prepend)' {
      Context 'and: "Pattern" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'blah' -Prepend 'prefix' -WhatIf:$whatIf; } `
          | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      }

      Context 'and: "Anchor" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Anchor 'blah' -Prepend 'prefix' -WhatIf:$whatIf; } `
          | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      }
    } # 'is not: valid (Prepend)'

    Context 'is not: valid (Append)' {
      Context 'and: "Pattern" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Pattern 'blah' -Append 'postfix' -WhatIf:$whatIf; } `
          | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      }

      Context 'and: "Anchor" specified' {
        It 'should: throw ParameterBindingException' {
          {
            Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
              -Anchor 'blah' -Append 'postfix' -WhatIf:$whatIf; } `
          | Assert-Throw -ExceptionType ([ParameterBindingException]);
        }
      }
    } # 'is not: valid (Prepend)'

    Context 'is not: valid; given: File & Directory specified together' {
      It 'should: throw ParameterBindingException' {
        {
          Get-ChildItem -File -Path $sourcePath -Filter $filter | Rename-Many -File `
            -Directory -Whole p -Pattern 'data.' -Anchor 't\d{1}\.' -WhatIf:$whatIf;
        } | Assert-Throw -ExceptionType ([ParameterBindingException]);
      }
    }
  } # given: Parameter Set
}
