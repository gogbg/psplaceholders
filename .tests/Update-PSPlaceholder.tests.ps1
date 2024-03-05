BeforeAll {
  . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
}

Describe '-String' {
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }

  Context 'contains no placeholders' {
    BeforeAll {
      $commonParams = @{
        String = 'There are no placeholders here'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }
  Context 'contains 1 placeholder' {
    BeforeAll {
      $commonParams = @{
        String = 'Firstname  is: {{placeholder_firstname}}'
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
  }
  Context 'contains 2 placeholder' {
    BeforeAll {
      $commonParams = @{
        String = 'Firstname  is: {{placeholder_firstname}}, Lastname is: {{placeholder_lastname}}'
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname, placeholder_lastname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
  }
}

Describe '-String -AllowEmptyPlaceholders' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }

  Context 'contains no placeholders' {
    BeforeAll {
      $commonParams = @{
        String                 = 'There are no placeholders here'
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }

  Context 'contains 1 placeholder' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{placeholder_firstname}}'
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }

  Context 'contains 2 placeholder' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{placeholder_firstname}}, Lastname is: {{placeholder_lastname}}'
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }
}

Describe '-String -Values' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }

  Context 'contains no placeholders and values in empty' {
    BeforeAll {
      $commonParams = @{
        String = 'There are no placeholders here'
        Values = @{}
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }

  Context 'contains no placeholders and -values is not empty' {
    BeforeAll {
      $commonParams = @{
        String = 'There are no placeholders here'
        Values = @{
          placeholder_bogus = 'bogus'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue | Should -Be $commonParams['String']
    }
    It 'Should return warning about unused placeholder value' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue -WarningVariable war
      $war | Should -Be 'Unused placeholder values: placeholder_bogus'
    }
  }

  Context 'contains 1 placeholder and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String = 'Firstname  is: {{placeholder_firstname}}'
        Values = @{
          placeholder_firstname = 'Neal'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal'
    }
  }

  Context 'contains 1 placeholder and -Values does not contains value for it' {
    BeforeAll {
      $commonParams = @{
        String = 'Firstname  is: {{placeholder_firstname}}'
        Values = @{
          placeholder_bogus = 'bogus'
        }
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
  }

  Context 'contains 2 placeholder and -Values contains value for them' {
    BeforeAll {
      $commonParams = @{
        String = 'Firstname  is: {{placeholder_firstname}}, Lastname is: {{placeholder_lastname}}'
        Values = @{
          placeholder_firstname = 'Neal'
          placeholder_lastname  = 'Armstrong'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal, Lastname is: Armstrong'
    }
    It 'Should not return warning' {
      Update-PSPlaceholder @commonParams -WarningVariable war
      $war | Should -BeNullOrEmpty
    }
  }

  Context 'contains 1 executable placeholder, -Values contains enumerable value for it' {
    BeforeAll {
      $commonParams = @{
        String = 'These are: {{& $placeholder_names}}'
        Values = @{
          placeholder_names = @('Neal', 'Joe', 'Kevin')
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'These are: System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]'
    }
  }
}

Describe '-String -Values -AllowEmptyPlaceholders' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }
    
  Context 'contains no placeholders and value is empty' {
    BeforeAll {
      $commonParams = @{
        String                 = 'There are no placeholders here'
        AllowEmptyPlaceholders = $true
        Values                 = @{}
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }
  Context 'contains no placeholders and value is not empty' {
    BeforeAll {
      $commonParams = @{
        String                 = 'There are no placeholders here'
        AllowEmptyPlaceholders = $true
        Values                 = @{
          placeholder_bogus = 'bogus'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue | Should -Be $commonParams['String']
    }
    It 'Should return warning about unused placeholder value' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue -WarningVariable war
      $war | Should -Be 'Unused placeholder values: placeholder_bogus'
    }
  }
  Context 'contains 1 placeholder and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{placeholder_firstname}}'
        Values                 = @{
          placeholder_firstname = 'Neal'
        }
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal'
    }
  }
  Context 'contains 2 placeholder and -Values contains value for one of them' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{placeholder_firstname}}, Lastname is: {{placeholder_lastname}}'
        Values                 = @{
          placeholder_firstname = 'Neal'
        }
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal, Lastname is: {{placeholder_lastname}}'
    }
  }
  Context 'contains 1 executable placeholder and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{& $placeholder_firstname}}'
        Values                 = @{
          placeholder_firstname = 'Neal'
        }
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal'
    }
  }
  Context 'contains 2 executable placeholder and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{& $placeholder_firstname}}, Lastname is: {{& $placeholder_lastname}}'
        Values                 = @{
          placeholder_firstname = 'Neal'
          placeholder_lastname  = 'Armstrong'
        }
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal, Lastname is: Armstrong'
    }
  }
}

Describe '-String -Values -AdaptTo Json' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }

  Context 'contains no placeholders and values in empty' {
    BeforeAll {
      $commonParams = @{
        String  = 'There are no placeholders here'
        Values  = @{}
        AdaptTo = 'Json'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }

  Context 'contains no placeholders and -values is not empty' {
    BeforeAll {
      $commonParams = @{
        String  = 'There are no placeholders here'
        Values  = @{
          placeholder_bogus = 'bogus'
        }
        AdaptTo = 'Json'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue | Should -Be $commonParams['String']
    }
    It 'Should return warning about unused placeholder value' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue -WarningVariable war
      $war | Should -Be 'Unused placeholder values: placeholder_bogus'
    }
  }

  Context 'contains 1 placeholder and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String  = 'Firstname  is: {{placeholder_firstname}}'
        Values  = @{
          placeholder_firstname = 'Neal'
        }
        AdaptTo = 'Json'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal'
    }
  }

  Context 'contains 1 placeholder and -Values does not contains value for it' {
    BeforeAll {
      $commonParams = @{
        String  = 'Firstname  is: {{placeholder_firstname}}'
        Values  = @{
          placeholder_bogus = 'bogus'
        }
        AdaptTo = 'Json'
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
  }

  Context 'contains 2 placeholder and -Values contains value for them' {
    BeforeAll {
      $commonParams = @{
        String  = 'Firstname  is: {{placeholder_firstname}}, Lastname is: {{placeholder_lastname}}'
        Values  = @{
          placeholder_firstname = 'Neal'
          placeholder_lastname  = 'Armstrong'
        }
        AdaptTo = 'Json'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal, Lastname is: Armstrong'
    }
    It 'Should not return warning' {
      Update-PSPlaceholder @commonParams -WarningVariable war
      $war | Should -BeNullOrEmpty
    }
  }

  Context 'contains 1 executable placeholder, -Values contains enumerable value for it' {
    BeforeAll {
      $commonParams = @{
        String  = 'These are: {{& $placeholder_firstname}}'
        Values  = @{
          placeholder_firstname = @('Neal', 'Joe', 'Kevin')
        }
        AdaptTo = 'Json'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'These are: System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]'
    }
  }

  Context 'contains 1 placeholder in json document and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String  = '{"Names": "{{placeholder_names}}"}'
        Values  = @{
          placeholder_names = @('Neal', 'Joe', 'Kevin')
        }
        AdaptTo = 'Json'
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be '{"Names": ["Neal","Joe","Kevin"]}'
    }
  }
}

Describe '-Path' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }

  Context 'is single file without placeholders' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithoutPlaceholders -Raw -ErrorAction Stop
      $commonParams = @{
        Path = $filePathWithoutPlaceholders
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not update the file content' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file with 1 placeholder in content' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithSinglePlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path = $filePathWithSinglePlaceholderInContent
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
    It 'Should not update the file content' {
      { Update-PSPlaceholder @commonParams } | Should -Throw
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file with 2 placeholder in content' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithTwoPlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path = $filePathWithTwoPlaceholderInContent
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname, placeholder_lastname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
    It 'Should not update the file content' {
      { Update-PSPlaceholder @commonParams } | Should -Throw
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file with 1 placeholder in name' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $fileWithOnePlaceholderInName -Raw -ErrorAction Stop
      $commonParams = @{
        Path = $fileWithOnePlaceholderInName
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_person. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
    It 'Should not update the file name' {
      { Update-PSPlaceholder @commonParams } | Should -Throw
      $commonParams['Path'] | Should -Exist
    }
  }
}

Describe '-Path -AllowEmptyPlaceholders' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }

  Context 'is single file without placeholders' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithoutPlaceholders -Raw -ErrorAction Stop
      $commonParams = @{
        Path                   = $filePathWithoutPlaceholders
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not update the file content' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file with 1 placeholder in content' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithSinglePlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path                   = $filePathWithSinglePlaceholderInContent
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not update the file content' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file with 2 placeholder in content' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithTwoPlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path                   = $filePathWithTwoPlaceholderInContent
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not update the file content' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file with 1 placeholder in name' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $fileWithOnePlaceholderInName -Raw -ErrorAction Stop
      $commonParams = @{
        Path                   = $fileWithOnePlaceholderInName
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not update the file name' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -Exist
    }
  }
}

Describe '-Path -Values' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  BeforeEach {
    . "$PSScriptRoot/Initialize-TestContext.ps1" -TempFolder $TestDrive
  }

  Context 'is single file without placeholders and -values is empty' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithoutPlaceholders -Raw -ErrorAction Stop
      $commonParams = @{
        Path   = $filePathWithoutPlaceholders
        Values = @{}
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not update the file content' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
  }
  Context 'is single file without placeholders and -values is not empty' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithoutPlaceholders -Raw -ErrorAction Stop
      $commonParams = @{
        Path   = $filePathWithoutPlaceholders
        Values = @{
          placeholder_bogus = 'bogus'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Not -Throw
    }
    It 'Should not update the file content' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly $initialFileContent
    }
    It 'Should return warning about unused placeholder value' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue -WarningVariable war
      $war | Should -Be 'Unused placeholder values: placeholder_bogus'
    }
  }
  Context 'is single file with 1 placeholder and -Values contains value for it' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithSinglePlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path   = $filePathWithSinglePlaceholderInContent
        Values = @{
          placeholder_firstName = 'Neal'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should update the file content' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly '{
    "FirstName": "Neal",
    "LastName": "Armstrong"
}'
    }
  }
  Context 'is single file with 1 placeholder and -Values does not contains value for it' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithSinglePlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path   = $filePathWithSinglePlaceholderInContent
        Values = @{
          placeholder_bogus = 'bogus'
        }
      }
    }
    It 'Should throw' {
      { Update-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage 'Unspecified placeholders: placeholder_firstname. Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders'
    }
  }
  Context 'is single file with 2 placeholders and -Values contains value for them' {
    BeforeAll {
      $initialFileContent = Get-Content -Path $filePathWithTwoPlaceholderInContent -Raw -ErrorAction Stop
      $commonParams = @{
        Path   = $filePathWithTwoPlaceholderInContent
        Values = @{
          placeholder_firstname = 'Neal'
          placeholder_lastname  = 'Armstrong'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams
      $commonParams['Path'] | Should -FileContentMatchMultilineExactly '{
    "FirstName": "Neal",
    "LastName": "Armstrong"
}'
    }
    It 'Should not return warning' {
      Update-PSPlaceholder @commonParams -WarningVariable war
      $war | Should -BeNullOrEmpty
    }
  }
}

Describe '-Path -Values -AllowEmptyPlaceholders' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }
  Context 'contains no placeholders and value is empty' {
    BeforeAll {
      $commonParams = @{
        String                 = 'There are no placeholders here'
        AllowEmptyPlaceholders = $true
        Values                 = @{}
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams | Should -Be $commonParams['String']
    }
  }
  Context 'contains no placeholders and value is not empty' {
    BeforeAll {
      $commonParams = @{
        String                 = 'There are no placeholders here'
        AllowEmptyPlaceholders = $true
        Values                 = @{
          placeholder_bogus = 'bogus'
        }
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue } | Should -Not -Throw
    }
    It 'Should return the same string' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue | Should -Be $commonParams['String']
    }
    It 'Should return warning about unused placeholder value' {
      Update-PSPlaceholder @commonParams -WarningAction SilentlyContinue -WarningVariable war
      $war | Should -Be 'Unused placeholder values: placeholder_bogus'
    }
  }
  Context 'contains 1 placeholder and -Values contains value for it' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{placeholder_firstname}}'
        Values                 = @{
          placeholder_firstname = 'Neal'
        }
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal'
    }
  }
  Context 'contains 2 placeholder and -Values contains value for one of them' {
    BeforeAll {
      $commonParams = @{
        String                 = 'Firstname  is: {{placeholder_firstname}}, Lastname is: {{placeholder_lastname}}'
        Values                 = @{
          placeholder_firstname = 'Neal'
        }
        AllowEmptyPlaceholders = $true
      }
    }
    It 'Should not throw' {
      { Update-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return modified string' {
      Update-PSPlaceholder @commonParams | Should -Be 'Firstname  is: Neal, Lastname is: {{placeholder_lastname}}'
    }
  }
}