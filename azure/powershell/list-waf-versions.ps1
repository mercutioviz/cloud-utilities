$wafs=./list-waf-byol.ps1
$wafs.version | Sort-Object { [version] $_ } -Descending