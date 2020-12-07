param (
  [Parameter(Mandatory)]
  $srcDir,
  [Parameter(Mandatory)]
  $dstDir
)

$rendBlackList = "centre", "nikaya", "book", "chapter", "subhead"
$nodeBackList = "hi", "pb", "note"

$includeForWCPropName = "_includeForWC"

function ExcludeForWC {
  param ($node)

  $node.SetAttribute($includeForWCPropName, $False)
}

function IsNodeExcluded {
  param ($node)

  $node.Attributes -and $node.Attributes[$includeForWCPropName].Value -ceq "False"
}

function GetAllExcludedText {
  param (
    [Parameter(ValueFromPipeline = $true)]
    $node
  )

  Process {
    if (IsNodeExcluded $node.Node) {
      $node.Node.InnerText
    } else {
      $innerNodeTexts = Select-Xml -Xml ([xml]$node.Node.OuterXml) -XPath "//*[@$($includeForWCPropName)='False']" | ForEach-Object {
        $_.Node.InnerText
      }

      $innerNodeTexts -join " "
    }
  }
}

function GetAllIncludedText {
  param (
    [Parameter(ValueFromPipeline = $true)]
    $node
  )

  Process {
    if (-not (IsNodeExcluded $node.Node)) {
      # NOTE: Cloning so as to avoid mutating the original node
      $nodeClone = (Select-Xml -Xml ([xml]$_.Node.OuterXml) -XPath "*")[0]
      $toRemove = $nodeClone.Node.ChildNodes | Where-Object { IsNodeExcluded $_ }
      $toRemove | ForEach-Object { $_.ParentNode.RemoveChild($_) } | Out-Null
      $nodeClone.Node.InnerXml.ToLower() # Keep it InnerXml so we catch any children that haven't been removed.
    } else {
      ""
    }
  }
}

function MarkNodesExcludedFromWC {
  param(
    [Parameter(ValueFromPipeline = $true)]
    $node
  )

  Process {
    if ($_.Node.rend -in $rendBlackList) {
      ExcludeForWC $node.Node
    } else {
      $nodeBackList | ForEach-Object {
        Select-Xml -Xml $node.Node -XPath $_
      } | ForEach-Object {
        ExcludeForWC $_.Node
      }
    }

    $node
  }
}

function RemovePunctuation {
  param(
    [Parameter(ValueFromPipeline = $true)]
    $text
  )

  Process {
    $text.Replace("…pe…", "") -replace "[.,?‘;’–-…]"
  }
}

function ProcessFile {
  param(
    $srcRoot,
    $dstRoot,
    [Parameter(ValueFromPipeline = $true)]
    $file
  )

  Process {
    Write-Host "Processing $($file.FullName)... `t" -NoNewline
    $dstFilePath = $file.FullName.ToLower().Replace($srcRoot.ToLower(), $dstRoot)

    $nodes = `
      Select-Xml -Path $file.FullName -XPath "//body/p" `
      | MarkNodesExcludedFromWC `

    $includedFilePath = [io.path]::ChangeExtension($dstFilePath, "included.txt")
    $includedLines =
      $nodes `
      | GetAllIncludedText `
      | RemovePunctuation
    $includedLines | Out-File -FilePath $includedFilePath -Encoding utf8

    $excludedFilePath = [io.path]::ChangeExtension($dstFilePath, "excluded.txt")
    $excludedLines =
      $nodes `
      | GetAllExcludedText
    $excludedLines | Out-File -FilePath $excludedFilePath -Encoding utf8

    if ($includedLines.Length -ne $excludedLines.Length) {
      Write-Host "[Check failed!]" -ForegroundColor Red
    } else {
      Write-Host "[Checked]" -ForegroundColor Green
    }
  }
}

function ProcessDirectory {
  param(
    $srcDir,
    $dstDir
  )

  Get-ChildItem -Filter "*.xml" (Join-Path $srcDir "cscd") | Where-Object {
    -not $_.FullName.EndsWith(".toc.xml")
  } | ProcessFile $srcDir $dstDir
}

ProcessDirectory $srcDir $dstDir
