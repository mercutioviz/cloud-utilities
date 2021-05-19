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

function get_subnets {
    param (
        $vnetName, $resourceGroup
    )
    $subnet_json=az network vnet subnet list --resource-group $resourceGroup --vnet-name $vnetName | json_pp
    $subnets = $subnet_json | ConvertFrom-Json
    return $subnets
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


## Handy get selection from user function
## Hat tip: https://jpearson.blog/2019/11/08/prompting-the-user-for-input-with-powershell/

function Get-SelectionFromUser {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Options,
        [Parameter(Mandatory=$true)]
        [string]$Prompt        
    )
    
    [int]$Response = 0;
    [bool]$ValidResponse = $false    

    while (!($ValidResponse)) {            
        [int]$OptionNo = 0

        Write-Host $Prompt -ForegroundColor DarkYellow
        Write-Host "[0]: Cancel"

        foreach ($Option in $Options) {
            $OptionNo += 1
            Write-Host ("[$OptionNo]: {0}" -f $Option)
        }

        if ([Int]::TryParse((Read-Host), [ref]$Response)) {
            if ($Response -eq 0) {
                return ''
            }
            elseif($Response -le $OptionNo) {
                $ValidResponse = $true
            }
        }
    }

    return $Options.Get($Response - 1)
} 