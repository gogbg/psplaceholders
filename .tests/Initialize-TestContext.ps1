[CmdletBinding()]
param
(
    [Parameter()]
    $TempFolder
)

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$moduleFolder = Join-Path -Path $repoRoot -ChildPath src -AdditionalChildPath 'psplaceholders'
if ($PSBoundParameters.ContainsKey('TempFolder'))
{
    $initialExamplesFolder = Join-Path -Path $repoRoot -ChildPath '.examples' -AdditionalChildPath '*'
    Copy-Item -Path $initialExamplesFolder -Destination $TestDrive -Container -Recurse -Force -ErrorAction Stop
    $examplesFolder = $TestDrive
}
else
{
    $examplesFolder = Join-Path -Path $repoRoot -ChildPath '.examples'
}

#files without placeholders in content
$folderWithoutPlaceholdersInContent = Join-Path -Path $examplesFolder -ChildPath 'withoutPlaceholders'
$filePathWithoutPlaceholders = Join-Path -Path $folderWithoutPlaceholdersInContent -ChildPath 'fileWithoutPlaceholder.json'

#files with placeholders in content
$folderWithPlaceholdersInContent = Join-Path -Path $examplesFolder -ChildPath 'placeholdersInContent'
$filePathWithSinglePlaceholderInContent = Join-Path -Path $folderWithPlaceholdersInContent -ChildPath 'fileWithSinglePlaceholder.json'
$filePathWithTwoPlaceholderInContent = Join-Path -Path $folderWithPlaceholdersInContent -ChildPath 'fileWithTwoPlaceholder.json'
    
#files with placeholders in name
$folderWithPlaceholdersInName = Join-Path -Path $examplesFolder -ChildPath 'placeholdersInName'
$fileWithOnePlaceholderInName = Join-Path -Path $folderWithPlaceholdersInName -ChildPath 'fileWithPlaceholdersInName-{{placeholder_person}}.json'