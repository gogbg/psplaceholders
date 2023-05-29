# PSPlaceholders

PSPlaceholders is a utility module to find and replace placeholders in strings or files. Placeholders should be specified following the pattern: {{placeholderName}}.

```powershell
Update-PSPlaceholder -String 'My name is {{FirstName}}' -Values @{FirstName='John'}
#should return:
'My name is John'
```

There are 2 type of placeholders: [Generic](#generic-placeholders) and [Executable](#executable-placeholders). Placeholders are supported in both file content and file names. Placeholder replacement in file content or string can also be adapted to the destination format using the **AdaptTo** parameter.

## Generic placeholders

Generic placeholders are defined as {{`<placeholdername`>}}. When you invoke Update-PSPlaceholders they will be replaced with the string representation of the value supplied in the hashtable passed to -Values

**Example 1:**

```powershell
Update-PSPlaceholder -String 'My name is {{FirstName}}' -Values @{FirstName='John'}
#should return:
'My name is John'
```

**Example 2:**

```powershell
Update-PSPlaceholder -String 'My name is {{FirstName}} {{LastName}}' -Values @{
  FirstName ='John'
  LastName  ='Dow'
}
#should return:
'My name is John Dow'
```

## Executable placeholders

Executable placeholders are defined as {{& `<powershell code block`>}}. When you invoke Update-PSPlaceholders it will invoke the powershell code in a sandbox context. Matching keys from the -Values hashtable will be binded to the variables inside the powershell code block, which provides a way to send input to the executable placeholders. Executable placeholders does not strive to support all possible expressions but to provide an easy way to transform the placeholder input or insert dynamic content

**Example 1:**

```powershell
Update-PSPlaceholder -String 'My colleagues are {{& [String]::Join(", ",$people)}}' -Values @{people='John','Bill','Mark'}
#should return
'My colleagues are John, Bill, Mark'
```

**Example 2:**

```powershell
Update-PSPlaceholder -String 'Today is: {{& get-date -Format "dd.MM.yyyy"}}'
#should return
'Today is: 18.05.2022' # where the date is the actual date
```

## Placeholders in files

Furthermore placeholders are supported in file content and file name, and you can specify which file or which folder should be evaluated.

**Example 1:**

```powershell
#initial file content is:
Get-Content -Path '.\file.txt'
'My name is {{FirstName}} {{LastName}}'

#update placeholders in specific file
Update-PSPlaceholder -Path '.\file.txt' -Values @{
  FirstName ='John'
  LastName  ='Dow'
}

#updated file content is:
Get-Content -Path '.\file.txt'
'My name is John Dow'
```

**Example 2:**

```powershell
Update-PSPlaceholder -Path 'c:\file1-{{& get-date -Format "dd_MM_yyyy"}}'
#should replace all placeholders in it's content, and rename the file to
'c:\file1-18_05_2022' # where the date is the actual date
```

## Placeholder adaptation

Using the '-AdaptTo' parameter you can specify that the placeholder replacing mechanism can make small adjustments to better replace the values depending of the destination format. At the moment only 'json' is supported.

**Example 1:**

```powershell
Update-PSPlaceholder -String '{
  "FirstName":"John",
  "LastName:"Dow",
  "Colleagues":"{{Colleagues}}"
}' -Values @{Colleagues=@('John','Bill','Mark')} -AdaptTo json
#should return
'{
  "FirstName":"John",
  "LastName:"Dow",
  "Colleagues":["John","Bill","Mark"]
}'
#Note that the double quotes(") before and after the placeholder {{Colleagues}} is omitted and the placeholder was replaced with the proper representation of the collection of strings in json. This allows the placeholders to be neatly inserted into json documents without breaking the json IDE parser
```
