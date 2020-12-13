param (
  [Parameter(Mandatory)]
  $srcDir,
  [Parameter(Mandatory)]
  $dstDir
)

Import-Module .\PSExtractTexts.psm1 -Force

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
      Select-Xml -Path $file.FullName -XPath "//body/p"

    Write-Host "[$($nodes.Length) nodes]`t" -NoNewline

    $includedLines = @()
    $excludedLines = @()
    $nodes `
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
  # TODO: Parallelize this
  [array] $results = Get-ChildItem -Filter "*.xml" (Join-Path $srcDir "cscd") | Where-Object {
    -not $_.FullName.EndsWith(".toc.xml")
  } | ProcessFile $srcDir $dstDir
  $failedCount = ($results | Where-Object { -not $_ }).Length
  Write-Host ("Summary: Duration {0:mm\:ss\.fff} Complete {1}, Failed {2}." -f ([datetime]::Now - $now), $results.Length, $failedCount)
}

# Test cases
# dir "D:\src\dpt\cst\cscd\abh01a.att0.xml" | ProcessFile $srcDir $dstDir # Has 830 nodes
# dir "D:\src\dpt\cst\cscd\vin07t.nrf9.xml" | ProcessFile $srcDir $dstDir # Has 1 node
# dir "D:\src\dpt\cst\cscd\s0201m.mul0.xml" | ProcessFile $srcDir $dstDir

ProcessDirectory $srcDir $dstDir
