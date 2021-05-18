$wafs=az vm image list -p barracudanetworks -l westus --all -f waf `
    --query "[?sku=='byol']" | ConvertFrom-Json
$wafs
