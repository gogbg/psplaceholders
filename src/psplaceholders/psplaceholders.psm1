
class PlaceholderMatch
{
  hidden [string]$Tag
  Hidden [char]$PreChar
  hidden [char]$PostChar
  hidden [uint]$IndexOfTag
}

class Placeholder
{
  [string]$Tag
  [string]$Type
  [string]$Name
  [string]$Value
  hidden [bool]$HasValue
  [uint]$InFileCount = 0
  [uint]$InFileNameCount = 0
}

class FileWithPlaceholders
{
  [string]$Name
  [string]$Folder
  [string]$Path
  hidden [System.Collections.Generic.List[string]]$PlaceholderInName = [System.Collections.Generic.List[string]]::new()
  hidden [System.Collections.Generic.List[string]]$PlaceholderInContent = [System.Collections.Generic.List[string]]::new()
}

class PlaceholderMatchEvaluators
{
  [bool]$AllowEmptyPlaceholders
  [hashtable]$PlaceholderValues
  static [string]$Pattern = '(?''pre''[^{}]{1})?(?''placeholder''{{(?''executionFlag''&)?(?''value''.*?)}})(?''post''[^{}]{1})?'
  [object]GetValue([GenericPlaceholderMatch]$placeholderMatch)
  {
    if ($this.PlaceholderValues.ContainsKey($placeholderMatch.Name))
    {
      return $this.PlaceholderValues[$placeholderMatch.Name]
    }
    elseif ($this.AllowEmptyPlaceholders)
    {
      return $placeholderMatch.Tag
    }
    else
    {
      throw "Missing value for placeholder: '$($placeholderMatch.Name)'"
    }
  }
  [object]GetValue([ExecutablePlaceholderMatch]$placeholderMatch)
  {
    #Find required input
    $executionVariables = [System.Collections.Generic.List[psvariable]]::new()
    $missingVariables = [System.Collections.Generic.HashSet[String]]::new()
    foreach ($ip In $placeholderMatch.Input.Name)
    {
      if ($this.PlaceholderValues.ContainsKey($ip))
      {
        $executionVariables.Add([psvariable]::new($ip, $this.PlaceholderValues[$ip]))
      }
      else
      {
        $null = $missingVariables.Add($ip)
      }
    }
    if ($missingVariables.Count -gt 0)
    {
      if (-not $this.AllowEmptyPlaceholders)
      {
        throw "Missing value for placeholder: $($ip)"
      }
      else
      {
        return $placeholderMatch.Tag
      }
    }

    #execute
    $executionResult = $placeholderMatch.ScriptBlock.InvokeWithContext($null, $executionVariables)

    #return result
    if ($executionResult.Count -gt 1)
    {
      #result is an array
      $result = $executionResult
    }
    else
    {
      #result is not an array, however scriptblock execution always returns an array
      $result = $executionResult[0]
    }
    return $result
  }

  #AdaptTo methods
  [string]Generic([System.Text.RegularExpressions.Match]$match)
  {
    $placeholderMatch = ConvertTo-PlaceholderMatch -Match $match
    $sb = [System.Text.StringBuilder]::new()
    if ($placeholderMatch.PreChar)
    {
      $sb.Append($placeholderMatch.PreChar)
    }
    $sb.Append($this.GetValue($placeholderMatch))
    if ($placeholderMatch.PostChar)
    {
      $sb.Append($placeholderMatch.PostChar)
    }
    return $sb.ToString()
  }
  [string]Json([System.Text.RegularExpressions.Match]$match)
  {
    $placeholderMatch = ConvertTo-PlaceholderMatch -Match $match
    $value = $this.GetValue($placeholderMatch)
    $sb = [System.Text.StringBuilder]::new()
    if (($placeholderMatch.PreChar -eq '"') -and ($placeholderMatch.PostChar -eq '"'))
    {
      $convertToJsonParams = @{
        Depth    = 20
        Compress = $true
      }
      if ([System.Management.Automation.LanguagePrimitives]::IsObjectEnumerable($value))
      {
        $convertToJsonParams['AsArray'] = $true
      }
      $sb.Append(($value | ConvertTo-Json @convertToJsonParams -ErrorAction Stop))
    }
    else
    {
      if ($placeholderMatch.PreChar)
      {
        $sb.Append($placeholderMatch.PreChar)
      }
      $sb.Append($value)
      if ($placeholderMatch.PostChar)
      {
        $sb.Append($placeholderMatch.PostChar)
      }
    }
    return $sb.ToString()
  }
}

class ExecutablePlaceholderInputMatch : PlaceholderMatch
{
  hidden [string]$Type = 'ExecutionInput'
  [string]$Name
  [string]ToString()
  {
    return $this.Name
  }
}

class ExecutablePlaceholderMatch : PlaceholderMatch
{
  hidden [string]$Type = 'Executable'
  [scriptblock]$ScriptBlock
  [System.Collections.Generic.HashSet[ExecutablePlaceholderInputMatch]]$Input = [System.Collections.Generic.HashSet[ExecutablePlaceholderInputMatch]]::new()
}

class GenericPlaceholderMatch : PlaceholderMatch
{
  hidden [string]$Type = 'generic'
  [string]$Name
}

function ConvertTo-Placeholder
{
  [CmdletBinding()]
  [Outputtype([Placeholder])]
  param
  (
    [Parameter(Mandatory)]
    [PlaceholderMatch]$Match
  )

  $result = [Placeholder]@{
    Tag = $Match.Tag
  }
  $result.Type = $Match.Type
  #calculate Name
  switch ($Match)
  {
    { $_ -is [ExecutablePlaceholderMatch] }
    {
      $result.Name = $_.ScriptBlock.ToString().Trim()
      break
    }
    { $_ -is [GenericPlaceholderMatch] }
    {
      $result.Name = $_.Name
      break
    }
    { $_ -is [ExecutablePlaceholderInputMatch] }
    {
      $result.Name = $_.Name
      break
    }
  }

  #return result
  $result
}

function ConvertTo-PlaceholderMatch
{
  [CmdletBinding()]
  [Outputtype([PlaceholderMatch])]
  param
  (
    [Parameter(Mandatory)]
    [System.Text.RegularExpressions.Match]$Match
  )

  if ($Match.Groups.Where({ $_.Name -eq 'executionFlag' }).Success)
  {
    $result = [ExecutablePlaceholderMatch]@{
      ScriptBlock = [scriptblock]::Create($Match.Groups.Where({ $_.Name -eq 'value' }).Value)
    }
    Get-AstStatement -Ast $result.ScriptBlock.Ast -Type VariableExpressionAst | ForEach-Object -Process {
      $null = $result.Input.Add([ExecutablePlaceholderInputMatch]@{
          Name       = $_.VariablePath
          Tag        = $_.Extent.Text
          IndexOfTag = $Match.Groups.Where({ $_.Name -eq 'placeholder' }).Index + 2 + $_.Extent.StartColumnNumber
        })
    }
  }
  else
  {
    $result = [GenericPlaceholderMatch]@{
      Name = $Match.Groups.Where({ $_.Name -eq 'value' }).Value
    }
  }

  $result.Tag = $Match.Groups.Where({ $_.Name -eq 'placeholder' }).Value
  $result.IndexOfTag = $Match.Groups.Where({ $_.Name -eq 'placeholder' }).Index
  if ($Match.Groups.Where({ $_.Name -eq 'pre' }).Success)
  {
    $result.PreChar = $Match.Groups.Where({ $_.Name -eq 'pre' }).Value
  }
  if ($Match.Groups.Where({ $_.Name -eq 'post' }).Success)
  {
    $result.PostChar = $Match.Groups.Where({ $_.Name -eq 'post' }).Value
  }

  #return result
  $result
}

function Get-PlaceholderMatchInString
{
  [CmdletBinding()]
  [Outputtype([PlaceholderMatch[]])]
  param
  (
    [Parameter(Mandatory)]
    [string]$String
  )

  [regex]::Matches($String, [PlaceholderMatchEvaluators]::Pattern) | ForEach-Object {
    $placeholderMatch = ConvertTo-PlaceholderMatch -Match $_
    if ($placeholderMatch -is [ExecutablePlaceholderMatch])
    {
      foreach ($pmi in $placeholderMatch.Input)
      {
        #return as separate placeholder
        $pmi
      }
    }
    #return placeholdermatch
    $placeholderMatch
  }
}

function Update-PlaceholderInString
{
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
  [CmdletBinding(SupportsShouldProcess)]
  [Outputtype([string])]
  param
  (
    [Parameter(Mandatory)]
    [string]$String,

    [Parameter()]
    [hashtable]$PlaceholderValues = @{},

    [Parameter()]
    [ValidateSet('json', 'generic')]
    [string]$AdaptTo = 'generic',

    [Parameter()]
    [switch]$AllowEmptyPlaceholders
  )

  #Pick Evaluator
  $matchEvaluator = [PlaceholderMatchEvaluators]::New()
  $matchEvaluator.PlaceholderValues = $PlaceholderValues
  $matchEvaluator.AllowEmptyPlaceholders = $AllowEmptyPlaceholders.IsPresent
  switch ($AdaptTo)
  {
    'generic'
    {
      $matchEvaluatorDelegate = [System.Delegate]::CreateDelegate([System.Text.RegularExpressions.MatchEvaluator], $matchEvaluator, 'Generic')
      break
    }
    'json'
    {
      $matchEvaluatorDelegate = [System.Delegate]::CreateDelegate([System.Text.RegularExpressions.MatchEvaluator], $matchEvaluator, 'Json')
      break
    }
  }

  [regex]::Replace($String, [PlaceholderMatchEvaluators]::Pattern, $matchEvaluatorDelegate)
}

<#
  .SYNOPSIS
  Find unique placeholder in files or string.

  .DESCRIPTION
  Find unique placeholder in files or string in their usage statistics. File names will also be evaluated for placeholders. Placeholder pattern is:
  - {{placeholder name}} - for generic placeholders
  - {{& powershell code}} - for executable placeholders. The purpose of this placeholder is to allow the proper formatting of the date not to implement complex activities. Standard powershell variables might be used as placeholders
  - {{& $inputData }} - powershell variables inside executable placeholders will be parsed as generic placeholders

  .PARAMETER String
  Specify string to search for placeholders

  .PARAMETER Path
  Specify Files or Folders to search for placeholders. Folders will be evaluated recursively

  .PARAMETER FileStatistics
  Specify reference variable to collect the statistics of files and placeholders found in their content or name

  .EXAMPLE
  # will find the placeholder 'placeholder_holiday'
  Get-PSPlaceholder -string 'Happy Happy {{placeholder_holiday}}'

  .EXAMPLE
  # will find all placeholder in specified files/s
  [ref]$fileStat = $null
  Get-PSPlaceholder -Path <file/s path> -FileStatistics $fileStat

  .EXAMPLE
  # will find all placeholder in all files recursively to the provided folder
  [ref]$fileStat = $null
  Get-PSPlaceholder -Path <folder Path Here> -FileStatistics $fileStat

  .EXAMPLE
  # will find the executable placeholder and the 'Holydays' placeholder
  Get-PSPlaceholder -string 'Happy Happy {{& [string]::Join(",",$Holydays)}}'

  .EXAMPLE
  # will find the placeholder 'Name'
  Get-PSPlaceholder -string 'Happy Happy {{& $Name)}}'
#>
function Get-PSPlaceholder
{
  [CmdletBinding(DefaultParameterSetName = 'inString')]
  [Outputtype([Placeholder[]])]
  param
  (
    [Parameter(Mandatory, ParameterSetName = 'inString')]
    [string]$String,

    [Parameter(Mandatory, ParameterSetName = 'inFiles')]
    [string[]]$Path,

    [Parameter(ParameterSetName = 'inFiles')]
    [ref]$FileStatistics
  )

  begin
  {
    $uniquePlaceholders = [System.Collections.Generic.Dictionary[string, Placeholder]]::new()
    $filesWithPlaceholderStatistics = [System.Collections.Generic.List[FileWithPlaceholders]]::new()
  }
  process
  {
    if ($PSBoundParameters.ContainsKey('String'))
    {
      Get-PlaceholderMatchInString -String $String | ForEach-Object -Process {
        #add placeholder to all placeholders collection
        if (-not $uniquePlaceholders.ContainsKey($_.Tag))
        {
          $ph = ConvertTo-Placeholder -Match $_
          $uniquePlaceholders.Add($ph.Tag, $ph)
        }
      }
    }
    else
    {
      #Find all items in scope
      $filesToCheck = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
      foreach ($p in $Path)
      {
        if ([System.IO.File]::Exists($p))
        {
          $filesToCheck.Add([System.IO.FileInfo]::new($p))
        }
        elseif (Test-Path -Path $p -PathType Container)
        {
          Get-ChildItem -Path $p -Recurse -File -ErrorAction Stop | ForEach-Object -Process {
            $filesToCheck.Add($_)
          }
        }
        else
        {
          throw "Path: '$p' not found"
        }
      }

      #Check all files in scope for placeholders
      foreach ($file in $filesToCheck)
      {
        $fileWithPlaceholders = [FileWithPlaceholders]@{
          Path   = $file.FullName
          Name   = $file.Name
          Folder = $file.Directory.FullName
        }

        #check file content for placeholders
        #Get file content using System.IO.File instead of get-content as it cannot read files that might contains the placeholder characters, e.g. [{}]
        $fileContent = [System.IO.File]::ReadAllText($fileWithPlaceholders.Path)
        if ($fileContent)
        {
          Get-PlaceholderMatchInString -String $fileContent -ErrorAction Stop | ForEach-Object -Process {
            #add placeholder to all placeholders collection
            if (-not $uniquePlaceholders.ContainsKey($_.Tag))
            {
              $ph = ConvertTo-Placeholder -Match $_
              $uniquePlaceholders.Add($ph.Tag, $ph)
            }
            $uniquePlaceholders[$_.Tag].InFileCount++

            #mark placeholder as present in the file content
            $null = $fileWithPlaceholders.PlaceholderInContent.Add($_.Tag)
          }
        }

        #check file name for placeholders
        Get-PlaceholderMatchInString -String $fileWithPlaceholders.Name -ErrorAction Stop | ForEach-Object -Process {
          #add placeholder to all placeholders collection
          if (-not $uniquePlaceholders.ContainsKey($_.Tag))
          {
            $ph = ConvertTo-Placeholder -Match $_
            $uniquePlaceholders.Add($ph.Tag, $ph)
          }
          $uniquePlaceholders[$_.Tag].InFileNameCount++

          #mark placeholder as present in the file content
          $null = $fileWithPlaceholders.PlaceholderInName.Add($_.Tag)
        }

        #include file in filesWithPlaceholderStatistics if it contains at least one placeholder
        if ($fileWithPlaceholders.PlaceholderInName.Count -gt 0 -or
          $fileWithPlaceholders.PlaceholderInContent.Count -gt 0
        )
        {
          $filesWithPlaceholderStatistics.Add($fileWithPlaceholders)
        }
      }

      #return file with placeholder statistics if required
      if ($PSBoundParameters.ContainsKey('FileStatistics'))
      {
        $FileStatistics.Value = $filesWithPlaceholderStatistics | ForEach-Object -Process { $_ }
      }
    }
  }
  end
  {
    $uniquePlaceholders.Values
  }
}

<#
  .SYNOPSIS
  Find and replace placeholder in files or string

  .DESCRIPTION
  Find and replace placeholder in files or strings. File names will also be evaluated for placeholders. Placeholder pattern is:
  - {{placeholder name}} - for generic placeholders
  - {{& powershell code}} - for executable placeholders. The purpose of this placeholder is to allow the proper formatting of the date not to implement complex activities. Standard powershell variables might be used as placeholders
  - {{& $inputData }} - powershell variables inside executable placeholders will be parsed as generic placeholders

  .PARAMETER String
  Specify string to search for placeholders and replace them

  .PARAMETER Path
  Specify Files or Folders to search for placeholders and replace them. Folders will be evaluated recursively

  .PARAMETER Values
  Specify set of placeholder names and their desired values to be used when replacing

  .PARAMETER AllowEmptyPlaceholders
  Allow the replacement of placeholder although not all values are provided.

  .PARAMETER AdaptTo
  Allows the language specific modifications outside of the placeholder string to be made where it make sense. For:
  - json: it will remove the surrounding double quotes(") if the placeholder resolves to an object and format that object as json sub element
  - generic: n/a

  .EXAMPLE
  # will replace the placeholder 'placeholder_holiday' with 'Easter'
  Update-PSPlaceholder -string 'Happy Happy {{placeholder_holiday}}' -Values @{placeholder_holiday='Easter'}

  .EXAMPLE
  # will replace the executable placeholder with 'Easter and Christmas'
  Update-PSPlaceholder -string 'Happy Happy {{& [string]::Join(" and ",$Holydays)}}' -Values @{Holydays='Easter','Christmas'}
#>
function Update-PSPlaceholder
{
  [CmdletBinding(SupportsShouldProcess)]
  param
  (
    [Parameter(Mandatory, ParameterSetName = 'inString')]
    [string]$String,

    [Parameter(Mandatory, ParameterSetName = 'inFiles')]
    [string[]]$Path,

    [Parameter()]
    [hashtable]$Values = @{},

    [Parameter()]
    [switch]$AllowEmptyPlaceholders,

    [Parameter()]
    [ValidateSet('json', 'generic')]
    [string]$AdaptTo = 'generic'
  )

  #Get placeholders
  if ($PSBoundParameters.ContainsKey('String'))
  {
    $placeholders = Get-PSPlaceholder -String $String
  }
  else
  {
    [ref]$filesWithPlaceholders = $null
    $placeholders = Get-PSPlaceholder -Path $Path -FileStatistics $filesWithPlaceholders
  }

  #Bind values to placeholders
  $unUsedPlacehodlerValues = @{} + $Values
  foreach ($p in $placeholders.Where({ $_.Type -in 'Generic', 'ExecutionInput' }))
  {
    if ($Values.ContainsKey($p.Name))
    {
      $p.Value = $Values[$p.Name]
      $p.HasValue = $true
    }

    #remove values to be able to track unused ones
    $unUsedPlacehodlerValues.Remove($p.Name)
  }

  #warn if there are unused placeholder values
  if ($unUsedPlacehodlerValues.Count -gt 0)
  {
    Write-Warning -Message "Unused placeholder values: $($unUsedPlacehodlerValues.Keys -join ',')"
  }

  #Replace placeholders
  if ($PSCmdlet.ShouldProcess("Placeholders to be replaced:$($placeholders | Select-Object -Property Name,Value | Sort-Object -Property Name | Out-String)", '', ''))
  {

    #check for placeholders without value
    if (-not $AllowEmptyPlaceholders.IsPresent)
    {
      $emptyPlaceholders = $placeholders.Where({ ($_.Type -eq 'Generic') -and (-not $_.HasValue) })
      if ($emptyPlaceholders)
      {
        throw "Unspecified placeholders: $($emptyPlaceholders.Name -join ', '). Use -AllowEmptyPlaceholders if you want to replace only part of the placeholders"
      }
    }

    #replace placeholders
    if ($PSBoundParameters.ContainsKey('String'))
    {
      Update-PlaceholderInString -String $String -PlaceholderValues $Values -AllowEmptyPlaceholders:$AllowEmptyPlaceholders.IsPresent -AdaptTo $AdaptTo
    }
    else
    {
      foreach ($file in $filesWithPlaceholders.Value)
      {
        #replace placeholder in content
        if ($file.PlaceholderInContent.count -gt 0)
        {
          $fileContent = [System.IO.File]::ReadAllText($file.Path)
          $updatedFileContent = Update-PlaceholderInString -String $fileContent -AllowEmptyPlaceholders:$AllowEmptyPlaceholders.IsPresent -PlaceholderValues $Values -AdaptTo $AdaptTo
          [System.IO.File]::WriteAllText($file.Path, $updatedFileContent)
        }

        #replace placeholder in file name
        if ($file.PlaceholderInName.Count -gt 0)
        {
          $newFileName = Update-PlaceholderInString -String $file.Name -PlaceholderValues $Values -AdaptTo $AdaptTo -AllowEmptyPlaceholders:$AllowEmptyPlaceholders.IsPresent
          [System.IO.File]::Move($file.Path, (Join-Path -Path $file.Folder -ChildPath $newFileName))
        }
      }
    }
  }
}

Export-ModuleMember -Function @(
  'Get-PSPlaceholder'
  'Update-PSPlaceholder'
)
