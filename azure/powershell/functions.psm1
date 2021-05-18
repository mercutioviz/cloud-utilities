# Azure env functions
function get_rg_list {
    param (
        $location
    )
    $rg_list = az group list --query "[?location=='${location}']" | json_pp | jq -r '.[] | .name'
    return $rg_list
}

function get_vnets {
    param (
        $location
    )
    $vnet_json=az network vnet list --query "[?location=='${location}']" | json_pp
    $vnets = $vnet_json | ConvertFrom-Json
    return $vnets
}

function get_nics {
    param (
        $location
    )
    $nic_json=az network nic list --query "[?location=='${location}']" | json_pp
    $nics = $nic_json | ConvertFrom-Json
    return $nics
}

function get_rgs {
    param (
        $location
    )
    $rg_json=az group list --query "[?location=='${location}']" | json_pp
    $rgs = $rg_json | ConvertFrom-Json
    return $rgs
}

function get_regions {
    $region_json=az account list-locations --query "[?metadata.regionType=='Physical']" | json_pp
    $regions = $region_json | ConvertFrom-Json
    return $regions
}
