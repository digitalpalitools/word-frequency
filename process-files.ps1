param (
  [Parameter(Mandatory)]
  $SrcDir,
  [Parameter(Mandatory)]
  $DstDir,
  [Parameter(Mandatory)]
  $Segment,
  [Parameter(Mandatory)]
  $TotalSegments,
  $Filter = "*"
)

Import-Module "$PSScriptRoot\PSExtractTexts.psm1" -Force

function CheckLines {
  param(
    $Nodes,
    $IncludedLines,
    $ExcludedLines
  )

  if (-not (($Nodes.Length -eq $includedLines.Length) -and ($Nodes.Length -eq $excludedLines.Length))) {
    return "Different number of lines"
  }

  [array] $mismatchLengthLines =
    0..$Nodes.Length | Where-Object {
      $Nodes[$_].InnerText.Length -ne ($includedLines[$_].Length + $excludedLines[$_].Length)
    }

  if ($mismatchLengthLines.Length) {
    return "Mismatched lines: $($mismatchLengthLines -join ",")"
  }

  return ""
}

function ProcessFile {
  param(
    $SrcRoot,
    $DstRoot,
    [Parameter(ValueFromPipeline = $true)]
    $FilePath
  )

  Begin {
    $fileNumber = 0
  }

  Process {
    $now = [datetime]::Now
    Write-Host ("... ... [{0,3}] {1}... `t" -f @($fileNumber, $FilePath)) -NoNewline
    $dstFilePath = $FilePath.ToLower().Replace($SrcRoot.ToLower(), $DstRoot)

    [array] $nodes = Select-Xml -Path $FilePath -XPath "//body/p"

    Write-Host "[$($nodes.Length) nodes]`t" -NoNewline

    $includedLines = @()
    $excludedLines = @()
    $nodes
    | ForEach-Object { $_.Node } `
    | Get-TextFromNode `
    | ForEach-Object {
      $includedLines += $_[0]
      $excludedLines += $_[1]
    }

    $includedFilePath = [io.path]::ChangeExtension($dstFilePath, "included.txt")
    $includedLines | Out-File -FilePath $includedFilePath -Encoding utf8BOM

    $excludedFilePath = [io.path]::ChangeExtension($dstFilePath, "excluded.txt")
    $excludedLines | Out-File -FilePath $excludedFilePath -Encoding utf8BOM

    if (-not (CheckLines $nodes $includedLines $excludedLines)) {
      Write-Host "[$($includedLines.Length)/$($excludedLines.Length) lines]`t" -NoNewline
      Write-Host "[Check failed]" -ForegroundColor Red -NoNewline
      Write-Host (" [{0:mm\:ss\.fff}]s" -f ([datetime]::Now - $now))
      $False
    } else {
      Write-Host "[$($includedLines.Length) lines]`t" -NoNewline
      Write-Host "[Checked]" -ForegroundColor Green -NoNewline
      Write-Host (" [{0:mm\:ss\.fff}]" -f ([datetime]::Now - $now))
      $True
    }

    $fileNumber = $fileNumber + 1
  }
}

function ProcessSegment {
  param(
    $SrcDir,
    $DstDir,
    $Segment,
    $TotalSegments,
    $Filter = "*"
  )

  $now = [datetime]::Now
  [array] $files =
    Get-ChildItem -Filter "$Filter.xml" (Join-Path $SrcDir "cscd")
    | Where-Object { -not $_.FullName.EndsWith(".toc.xml") }
    | ForEach-Object { $_.FullName }
    | Sort-Object

  $segmentSize = [Math]::Ceiling($files.Length / $TotalSegments)
  $firstFile = $segmentSize * $Segment
  $lastFile = $firstFile + $segmentSize - 1

  Write-Host ("Staring: Segment {0} of {1}..." -f $Segment, $TotalSegments)
  Write-Host ("... Files {0} to {1} of {2}" -f $firstFile, $lastFile, $files.Length)
  Write-Host "...      Source Dir: $SrcDir"
  Write-Host "... Destimation Dir: $DstDir"
  Write-Host "...          Filter: $Filter"

  $results =
    $files[$firstFile..$lastFile]
    | ProcessFile $SrcDir $DstDir
  $failedCount = ($results | Where-Object { -not $_ }).Length
  Write-Host ("Summary: Duration {0:mm\:ss\.fff} Complete {1}, Failed {2}." -f ([datetime]::Now - $now), $results.Length, $failedCount)
}

# Test cases
# dir "D:\src\dpt\cst\cscd\abh01a.att0.xml" | ProcessFile $SrcDir $DstDir # Has 830 nodes
# dir "D:\src\dpt\cst\cscd\vin07t.nrf9.xml" | ProcessFile $SrcDir $DstDir # Has 1 node
# dir "D:\src\dpt\cst\cscd\s0201m.mul0.xml" | ProcessFile $SrcDir $DstDir

#dir "D:\src\dpt\cst\cscd\abh03m10.mul14.xml" | ProcessFile $SrcDir $DstDir # Has 830 nodes

#ProcessDirectory $SrcDir $DstDir $Filter

ProcessSegment $SrcDir $DstDir $Segment $TotalSegments $Filter
