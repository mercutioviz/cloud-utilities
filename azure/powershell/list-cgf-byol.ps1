$cgfs=az vm image list -p barracudanetworks -l westus --all -f "barracuda-ng-firewall" `
--query "[?sku=='byol']" | ConvertFrom-Json
$cgfs
