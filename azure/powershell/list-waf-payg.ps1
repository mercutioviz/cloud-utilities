$wafs=az vm image list -p barracudanetworks -l westus --all -f waf -s hourly `
    --query "[?sku=='hourly']" | ConvertFrom-Json
$wafs
