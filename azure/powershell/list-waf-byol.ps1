$vms=az vm image list -p barracudanetworks -l westus --all -f waf -s byol | ConvertFrom-Json
$vms
