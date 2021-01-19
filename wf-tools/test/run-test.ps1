$res = Compare-Object (Get-Content "$PSScriptRoot/selected-nodes.txt.wf-baseline.csv") (Get-Content "$PSScriptRoot/selected-nodes.txt.wf.csv")
$res | Format-Table
if ($res.Length -ne 0) {
  throw "Test failed. See the output above."
}

