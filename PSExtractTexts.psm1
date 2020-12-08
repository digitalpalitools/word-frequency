$rendBlackList = "centre", "nikaya", "book", "chapter", "subhead", "title"
$nodeBackList = "hi", "pb", "note"
$regExCharClassToExlude = "[.,?‘;’–-…]"

function Get-TextFromNode {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [Xml.XmlNode]
    $Node,
    [Switch]
    $ForInclusion
  )

  Process {
    if ($_.rend -in $rendBlackList) {
      if ($ForInclusion) {
        ""
      } else {
        $_.InnerText
      }

      return
    }

    $text = $node.InnerXml # Keep it InnerXml so we catch any children that haven't been removed.
    $excludedText = ""
    [array] $subNodesToExclude = Select-Xml -Xml $node -XPath "*" | Where-Object {
      $nodeBackList -contains $_.Node.Name
    }
    if ($subNodesToExclude) {
      if ($ForInclusion) {
        # NOTE: Cloning so as to avoid mutating the original node
        $nodeClone = (Select-Xml -Xml ([xml]$node.OuterXml) -XPath "*")[0]
        $toRemove = $nodeClone.Node.ChildNodes | Where-Object { $nodeBackList -contains $_.Name }
        $toRemove | ForEach-Object { $_.ParentNode.RemoveChild($_) } | Out-Null
        $text = $nodeClone.Node.InnerXml # Keep it InnerXml so we catch any children that haven't been removed.
      } else {
        $excludedText = ($subNodesToExclude | ForEach-Object { $_.Node.InnerText }) -join " "
      }
    }

    if ($ForInclusion) {
      $text.ToLowerInvariant().Replace("…pe…", "") -replace $regExCharClassToExlude
    } else {
      $excludedText
    }
  }
}
