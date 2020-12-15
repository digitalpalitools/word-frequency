<#
- Types of munging:
  - Blacklisted line tag excluded
  - Line tag with blacklisted workd excluded
  - Child tags excluded (e.g. note)
  - Nested child tags excluded
  - Parts of line exlucded (e.g. /\(.*\)/, ...pe...)
  - Characters nuked
  - ToLowerCase

- #TODO:
  - here's pattern to exclude, the vagga always ends with "tassuddānaṃ " (recitation of this) and a reciters verse. exclude that and whatever comes below it, normally 2-4 lines of verse

#>

$rendBlackList = "centre", "nikaya", "book", "chapter", "subhead", "title", "subsubhead"

$nodeBackList = "hi", "pb", "note"

$wordBlackList = @("partho") # NOTE: This feature is currently not needed but keeping it around for a bit longer.

$sequencesToRemove = "…pe…", "\([^()]*\)", "[.,?‘;’–\-…]"
  | ForEach-Object { [Text.RegularExpressions.Regex]::new("^($_)", [Text.RegularExpressions.RegexOptions]::Compiled -bOr [Text.RegularExpressions.RegexOptions]::IgnoreCase) }

function Add-NodeToAppropriateList {
  param(
    [ref]
    $IncludedNodes,
    [ref]
    $ExcludedNodes,
    [Parameter(ValueFromPipeline = $true)]
    $Node
  )

  if ($nodeBackList -inotcontains $Node.Name) {
    $IncludedNodes.Value.Add($Node) | Out-Null
    $ExcludedNodes.Value.Add($null) | Out-Null
  } else {
    $IncludedNodes.Value.Add($null) | Out-Null
    $ExcludedNodes.Value.Add($Node) | Out-Null
  }
}

function Get-TextFromNode {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [Xml.XmlNode]
    $Node
  )

  Process {
    if ($Node.rend -in $rendBlackList) {
      , @("", $Node.InnerText)
      return
    }

    if ($wordBlackList | Where-Object { $Node.InnerText -imatch $_ } | Select-Object -First 1) {
      , @("", $Node.InnerText)
      return
    }

    [array] $childNodes = $Node.ChildNodes
    $includedSubNodes = [Collections.ArrayList]@()
    $excludedSubNodes = [Collections.ArrayList]@()

    for ($i=0; $i -lt $childNodes.Length; $i++) {
      $childNode = $childNodes[$i]
      if ($childNode.Name -ieq "hi" -and $childNode.rend -ieq "bold") {
        [array] $grandChildNodes = $childNode.ChildNodes
        for ($j=0; $j -lt $grandChildNodes.Length; $j++) {
          $grandChildNodes[$j] | Add-NodeToAppropriateList ([ref]$includedSubNodes) ([ref]$excludedSubNodes)
        }
      } else {
        $childNodes[$i] | Add-NodeToAppropriateList ([ref]$includedSubNodes) ([ref]$excludedSubNodes)
      }
    }

    [array] $includedSubNodeTexts = $includedSubNodes | ForEach-Object { "$($_.InnerText)" }
    [array] $excludedSubNodeTexts = $excludedSubNodes | ForEach-Object { "$($_.InnerText)" }
    if ($includedSubNodeTexts.Length -ne $excludedSubNodeTexts.Length) {
      throw 'Something went wrong: includedSubNodeTexts and excludedSubNodeTexts are not of same length!'
    }
    $subNodeTextsLength = $includedSubNodeTexts.Length # NOTE: Also equal to $excludedSubNodeTexts.Length
    for ($i=0; $i -lt $subNodeTextsLength; $i++) {
      $text = $includedSubNodeTexts[$i]
      $includedSubNodeTexts[$i] = ""
      while ($text) {
        $seq = $sequencesToRemove | Where-Object { $text -imatch "^($_)" } | Select-Object -First 1

        if ($seq) {
          $excludedSubNodeTexts[$i] = $excludedSubNodeTexts[$i] + $Matches[0]
          $text = $text.Substring($Matches[0].Length)
        } else {
          $includedSubNodeTexts[$i] = $includedSubNodeTexts[$i] + $text[0]
          $text = $text.Substring(1)
        }
      }
    }

    , @(($includedSubNodeTexts -join "").ToLowerInvariant(), ($excludedSubNodeTexts -join ""))
  }
}
