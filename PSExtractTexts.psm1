$rendBlackList = "centre", "nikaya", "book", "chapter", "subhead", "title"

$nodeBackList = "hi", "pb", "note"

$wordBlackList = @() # "paṇṇāsakaṃ"

$sequencesToRemove = "…pe…", "\([^()]*\)", "[.,?‘;’–\-…]"
  | ForEach-Object { [Text.RegularExpressions.Regex]::new("^($_)", [Text.RegularExpressions.RegexOptions]::Compiled -bOr [Text.RegularExpressions.RegexOptions]::IgnoreCase) }

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
    $includedSubNodes = [object[]]::new($childNodes.Length)
    $excludedSubNodes = [object[]]::new($childNodes.Length)

    for ($i=0; $i -lt $childNodes.Length; $i++) {
      if ($nodeBackList -notcontains $childNodes[$i].Name) {
        $includedSubNodes[$i] = $childNodes[$i]
      } else {
        $excludedSubNodes[$i] = $childNodes[$i]
      }
    }

    [array] $includedSubNodeTexts = $includedSubNodes | ForEach-Object { "$($_.InnerText)" }
    [array] $excludedSubNodeTexts = $excludedSubNodes | ForEach-Object { "$($_.InnerText)" }
    for ($i=0; $i -lt $childNodes.Length; $i++) {
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
