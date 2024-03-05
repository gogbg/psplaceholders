BeforeAll {
  . "$PSScriptRoot/Initialize-TestContext.ps1"
}

Describe '-Path' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }

  Context 'is missing file' {
    BeforeAll {
      $commonParams = @{
        Path = $missingFilePath
      }
    }
    It 'Should throw' {
      { Get-PSPlaceholder @commonParams } | Should -Throw -ExpectedMessage "Path: '$missingFilePath' not found"
    }
  }

  Context 'is single file without placeholders' {
    BeforeAll {
      $commonParams = @{
        Path = $filePathWithoutPlaceholders
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not return result' {
      Get-PSPlaceholder @commonParams | Should -BeNullOrEmpty
    }
  }

  Context 'is single file with 1 placeholder in content' {
    BeforeAll {
      $commonParams = @{
        Path = $filePathWithSinglePlaceholderInContent
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return one result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 1
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).gettype().name | Should -Be placeholder
    }
    It 'Should find the placeholder:placeholder_firstName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName'
    }
  }

  Context 'is single file with 2 placeholder in content' {
    BeforeAll {
      $commonParams = @{
        Path = $filePathWithTwoPlaceholderInContent
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return two result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 2
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).foreach{ $_.gettype().name } | Should -BeIn placeholder
    }
    It 'Should find the placeholders:placeholder_firstName,placeholder_lastName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName', 'placeholder_lastName'
    }
  }

  Context 'is folder with 2 unqiue placeholder in content' {
    BeforeAll {
      $commonParams = @{
        Path = $folderWithPlaceholdersInContent
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return one result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 2
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).foreach{ $_.gettype().name } | Should -BeIn placeholder
    }
    It 'Should find the unique placeholders:placeholder_firstName,placeholder_lastName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName', 'placeholder_lastName'
    }
    It 'Should count repeating placeholders:placeholder_firstName' {
      $ph = Get-PSPlaceholder @commonParams
      $ph.where{ $_.Name -eq 'placeholder_firstName' }.InFileCount | Should -Be 2
    }
  }

  Context 'is single file with 1 placeholder in name' {
    BeforeAll {
      $commonParams = @{
        Path = $fileWithOnePlaceholderInName
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return one result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 1
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).gettype().name | Should -Be placeholder
    }
    It 'Should find the placeholder:placeholder_person' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_person'
    }
  }
}

Describe '-String' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }

  Context 'contains no placeholders' {
    BeforeAll {
      $commonParams = @{
        String = Get-Content -Path $filePathWithoutPlaceholders -Raw
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not return result' {
      Get-PSPlaceholder @commonParams | Should -BeNullOrEmpty
    }
  }

  Context 'contains 1 placeholder' {
    BeforeAll {
      $commonParams = @{
        String = Get-Content -Path $filePathWithSinglePlaceholderInContent -Raw
      }
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return one result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 1
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).gettype().name | Should -Be placeholder
    }
    It 'Should find the placeholder:placeholder_firstName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName'
    }
  }

  Context 'contains 2 placeholders' {
    BeforeAll {
      $commonParams = @{
        String = Get-Content -Path $filePathWithTwoPlaceholderInContent -Raw
      }
    }
    It 'Should return two result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 2
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).foreach{ $_.gettype().name } | Should -BeIn placeholder
    }
    It 'Should find the placeholders:placeholder_firstName,placeholder_lastName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName', 'placeholder_lastName'
    }
  }
}

Describe '-Path -FileStatistics' {
  BeforeAll {
    $module = Import-Module -Name $moduleFolder -PassThru -Force -ErrorAction Stop
  }
  AfterAll {
    Remove-Module -Name 'psplaceholders' -Force -ErrorAction Stop
  }

  Context 'is single file without placeholders' {
    BeforeAll {
      $commonParams = @{
        Path = $filePathWithoutPlaceholders
      }
    }
    BeforeEach {
      [ref]$refStats = $null
      $commonParams['FileStatistics'] = $refStats
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should not return result' {
      Get-PSPlaceholder @commonParams | Should -BeNullOrEmpty
    }
    It 'refStats should be null' {
      Get-PSPlaceholder @commonParams
      $refStats.Value | Should -BeNullOrEmpty
    }
  }

  Context 'is single file with 1 placeholder in content' {
    BeforeAll {
      $commonParams = @{
        Path = $filePathWithSinglePlaceholderInContent
      }
    }
    BeforeEach {
      [ref]$refStats = $null
      $commonParams['FileStatistics'] = $refStats
    }
    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return one result' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 1
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).gettype().name | Should -Be placeholder
    }
    It 'Should find the placeholder:placeholder_firstName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName'
    }
    It 'refStats should be 1 object' {
      Get-PSPlaceholder @commonParams
      $refStats.Value | Should -HaveCount 1
    }
    It 'refStats should be of type [FileWithPlaceholders]' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.GetType().name | Should -Be FileWithPlaceholders
    }
    It 'refStats should have .PlaceholderInContent={{placeholder_firstName}}' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.PlaceholderInContent | Should -Be '{{placeholder_firstName}}'
    }
  }

  Context 'is single file with 2 placeholder in content' {
    BeforeAll {
      $commonParams = @{
        Path = $filePathWithTwoPlaceholderInContent
      }
    }
    BeforeEach {
      [ref]$refStats = $null
      $commonParams['FileStatistics'] = $refStats
    }

    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return 2 results' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 2
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).foreach{ $_.gettype().name } | Should -BeIn placeholder
    }
    It 'Should find the placeholders:placeholder_firstName,placeholder_lastName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName', 'placeholder_lastName'
    }
    It 'refStats should be 1 objects' {
      Get-PSPlaceholder @commonParams
      $refStats.Value | Should -HaveCount 1
    }
    It 'refStats should be of type [FileWithPlaceholders]' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.GetType().name | Should -BeIn FileWithPlaceholders
    }
    It 'refStats should have .PlaceholderInContent={{placeholder_firstName}},{{placeholder_lastName}}' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.PlaceholderInContent | Should -Be '{{placeholder_firstName}}', '{{placeholder_lastName}}'
    }
  }

  Context 'is folder with 2 unqiue placeholder in content' {
    BeforeAll {
      $commonParams = @{
        Path = $folderWithPlaceholdersInContent
      }
    }
    BeforeEach {
      [ref]$refStats = $null
      $commonParams['FileStatistics'] = $refStats
    }

    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return 2 results' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 2
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).foreach{ $_.gettype().name } | Should -BeIn placeholder
    }
    It 'Should find the unique placeholders:placeholder_firstName,placeholder_lastName' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_firstName', 'placeholder_lastName'
    }
    It 'Should count repeating placeholders:placeholder_firstName' {
      $ph = Get-PSPlaceholder @commonParams
      $ph.where{ $_.Name -eq 'placeholder_firstName' }.InFileCount | Should -Be 2
    }
    It 'refStats should be 2 objects' {
      Get-PSPlaceholder @commonParams
      $refStats.Value | Should -HaveCount 2
    }
    It 'refStats should be of type [FileWithPlaceholders]' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.foreach{ $_.GetType().name } | Should -BeIn FileWithPlaceholders
    }
    It 'refStats should have .Name=fileWithSinglePlaceholder.json and .PlaceholderInContent={{placeholder_firstName}}' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.Where{ $_.Name -eq 'fileWithSinglePlaceholder.json' }.PlaceholderInContent | Should -Be '{{placeholder_firstName}}'
    }
    It 'refStats should have .Name=fileWithTwoPlaceholder.json and .PlaceholderInContent={{placeholder_firstName}},{{placeholder_lastName}}' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.Where{ $_.Name -eq 'fileWithTwoPlaceholder.json' }.PlaceholderInContent | Should -Be '{{placeholder_firstName}}', '{{placeholder_lastName}}'
    }
  }

  Context 'is single file with 1 placeholder in name' {
    BeforeAll {
      $commonParams = @{
        Path = $fileWithOnePlaceholderInName
      }
    }
    BeforeEach {
      [ref]$refStats = $null
      $commonParams['FileStatistics'] = $refStats
    }

    It 'Should not throw' {
      { Get-PSPlaceholder @commonParams } | Should -Not -Throw
    }
    It 'Should return one object' {
      Get-PSPlaceholder @commonParams | Should -HaveCount 1
    }
    It 'Should return result of type [Placeholder]' {
            (Get-PSPlaceholder @commonParams).gettype().name | Should -Be placeholder
    }
    It 'Should find the placeholder:placeholder_person' {
            (Get-PSPlaceholder @commonParams).Name | Should -Be 'placeholder_person'
    }
    It 'refStats should be 1 object' {
      Get-PSPlaceholder @commonParams
      $refStats.Value | Should -HaveCount 1
    }
    It 'refStats should be of type [FileWithPlaceholders]' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.GetType().name | Should -Be FileWithPlaceholders
    }
    It 'refStats should have .PlaceholderInName={{placeholder_person}}' {
      Get-PSPlaceholder @commonParams
      $refStats.Value.PlaceholderInName | Should -Be '{{placeholder_person}}'
    }
  }
}