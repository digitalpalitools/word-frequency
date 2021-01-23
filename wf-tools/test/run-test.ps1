echo "Running e2e tests..."
$lhs = "$PSScriptRoot/selected-nodes.txt.wf-baseline.csv"
$rhs = "$PSScriptRoot/selected-nodes.txt.wf.csv"
echo "Comparing '$lhs' <=> '$rhs'"
$res = Compare-Object (Get-Content $lhs) (Get-Content $rhs)
$res | Format-Table
if ($res.Length -ne 0) {
  throw "Test failed. See the output above."
}

