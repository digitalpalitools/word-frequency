$rendBlackList = "centre", "nikaya", "book", "chapter", "subhead", "title"
$nodeBackList = "hi", "pb", "note"
$sequencesToRemove = "…pe…", ".", ",", "?", "‘", ";", "’", "–", "…"

function Get-TextFromNode {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [Xml.XmlNode]
    $Node
  )

  Process {
    if ($_.rend -in $rendBlackList) {
      "", (($_.ChildNodes | ForEach-Object { $_.InnerText }) -join "")
      return
    }

    [array] $childNodes = $_.ChildNodes
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
        $seq = $sequencesToRemove | Where-Object { $text.StartsWith($_) } | Select-Object -First 1

        if ($seq) {
          $excludedSubNodeTexts[$i] = $excludedSubNodeTexts[$i] + $seq
          $text = $text.Substring($seq.Length)
        } else {
          $includedSubNodeTexts[$i] = $includedSubNodeTexts[$i] + $text[0]
          $text = $text.Substring(1)
        }
      }
    }

    ($includedSubNodeTexts -join "").ToLowerInvariant(), ($excludedSubNodeTexts -join "")
  }
}
