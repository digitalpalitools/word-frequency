﻿param (
  [Parameter(Mandatory)]
  $srcDir,
  [Parameter(Mandatory)]
  $dstDir
)

$rendBlackList = "centre", "nikaya", "book", "chapter", "subhead", "title"
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
    $text.Replace("…pe…", "") -replace "[().,?‘;’–-…]"
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

    [array] $nodes = `
      Select-Xml -Path $file.FullName -XPath "//body/p" `
      | MarkNodesExcludedFromWC `

    Write-Host "[$($nodes.Length) nodes]`t" -NoNewline

    $includedFilePath = [io.path]::ChangeExtension($dstFilePath, "included.txt")
    [array] $includedLines =
      $nodes `
      | GetAllIncludedText `
      | RemovePunctuation
    $includedLines | Out-File -FilePath $includedFilePath -Encoding utf8

    $excludedFilePath = [io.path]::ChangeExtension($dstFilePath, "excluded.txt")
    [array] $excludedLines =
      $nodes `
      | GetAllExcludedText
    $excludedLines | Out-File -FilePath $excludedFilePath -Encoding utf8

    if ($includedLines.Length -ne $excludedLines.Length) {
      Write-Host "[$($includedLines.Length)/$($excludedLines.Length) lines]`t" -NoNewline
      Write-Host "[Check failed]" -ForegroundColor Red
      $False
    } else {
      Write-Host "[$($includedLines.Length) lines]`t" -NoNewline
      Write-Host "[Checked]" -ForegroundColor Green
      $True
    }
  }
}

function ProcessDirectory {
  param(
    $srcDir,
    $dstDir
  )

  $now = [datetime]::Now
  [array] $results = Get-ChildItem -Filter "*.xml" (Join-Path $srcDir "cscd") | Where-Object {
    -not $_.FullName.EndsWith(".toc.xml")
  } | ProcessFile $srcDir $dstDir
  $failedCount = ($results | Where-Object { -not $_ }).Length
  Write-Host ("Summary: Duration {0:mm\:ss\.fff} Complete {1}, Failed {2}." -f ([datetime]::Now - $now), $results.Length, $failedCount)
}

# dir "D:\src\dpt\cst\cscd\abh01a.att0.xml" | ProcessFile $srcDir $dstDir # Has 830 nodes
# dir "D:\src\dpt\cst\cscd\vin07t.nrf9.xml" | ProcessFile $srcDir $dstDir # Has 1 node
ProcessDirectory $srcDir $dstDir
