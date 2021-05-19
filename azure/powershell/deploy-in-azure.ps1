# deploy-in-azure.ps1
#
# Deploy Barracuda WAF or CGF into azure
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $location,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]
    $deploy_method,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [switch]
    $nogreeting = $false,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [switch]
    $noninteractive = $false,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [switch]
    $ha = $false,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [validateset("WAF","CGF")]
    [string]
    $product
)

# Import functions
Import-Module ./functions.psm1

if ( $noninteractive -eq $true ) {
    $nogreeting = $true
}
# Welcome message
if ( $nogreeting -eq $false ) {
    Write-Host "Welcome to the Barracuda WAF and CGF deployment script for Azure."
    Write-Host "This script will assist with deploying WAF or CGF into an Azure environment."
    Write-Host "You will need to supply the following information:"
    Write-Host "  Product to deploy (WAF or CGF)"
    Write-Host "  Location (i.e. region)"
    Write-Host "  Deployment type: standalone or high availability pair"
    Write-Host "  Deployment methond: all new infrastructure or use existing VNet"
    Write-Host
    Read-Host "Press <Enter> to continue"    
}

if ( $location -eq '' ) {
    #$location = Read-Host "Enter location (ex: westus, eastus2)"
    Write-Host "Location not specified. Enter region name or press <ENTER> to pick from list"
    $answer = Read-Host "Choice "
    if ( $answer -ne '' ) {
        $location = $answer
    } else {
        Write-Host "Reading geo and region data..."
        $regions = get_regions
        $geolist = $regions.metadata.geographyGroup |Sort-Object -Unique
        $geogroup = Get-SelectionFromUser -Options $geolist -Prompt "Select Geography Group"
        if ( $geogroup -eq '' ) {
            Write-Host "Operation Aborted." -ForegroundColor Red 
            exit
        } else {
            Write-Host "Geo group $geogroup selected" -ForegroundColor Cyan
        }

        $myregions = $regions | Where-Object {$_.metadata.geographyGroup -eq $geogroup }
        $region = Get-SelectionFromUser -Options $myregions.displayName -Prompt "Select Region"
        if ( $region -eq '' ) {
            Write-Host "Operation Aborted." -ForegroundColor Red 
            exit
        } else {
            Write-Host "Selected region $region" -ForegroundColor Cyan
        }

        $myregion = $myregions | Where-Object {$_.displayName -eq $region}
        $location = $myregion.name
        #Write-Host "Deploying into region $location" -ForegroundColor Green
    }
} elseif ( $noninteractive -eq $false ) {
    $answer = Read-Host "Enter location (<enter> = $location)"
    if ( $answer -ne '' ) {
        $location = $answer
    }
}
Write-Host "Location: " $location -ForegroundColor Green

if ( $product -eq '' ) {
    $product = Read-Host "Select product (WAF or CGF)"
} elseif ( $noninteractive -eq $false ) {
    $answer = Read-Host "Select product (<enter> = $product)"
    if ( $answer -ne '' ) {
        $product = $answer
    }
}
Write-Host "Product: " $product -ForegroundColor Green

if ( $deploy_method -eq '' ) {
    $deploy_method = Read-Host "Create (N)ew infrastructure or use (E)xisting VNet (N or E, <enter>=New)"
    if ( $deploy_method -eq '' ) {
        $deploy_method = 'new'
    }
} elseif ( $noninteractive -eq $false ) {
    $answer = Read-Host "Select product (<enter> = $deploy_method)"
    if ( $answer -ne '' ) {
        $deploy_method = $answer
    }
}
Write-Host "Deploy Method: " $deploy_method -ForegroundColor Green

if ( $noninteractive -eq $false ) {
    Write-Host "Deployment type: single unit or high availability (HA) pair."
    $answer = Read-Host "Would you like to deploy an HA Pair? (Y/N <enter>=No)"
    #Write-Host "'$answer'" -ForegroundColor Magenta
    if ( $answer -eq '' -or $answer -match "^[Nn]" ) {
        $ha = $false
    } else {
        $ha = $true
    }
}
Write-Host "HA Deployment: " $ha -ForegroundColor Green

Write-Host "Gathering information about your Azure environment..."
$vnets = get_vnets
$rg_list = get_rg_list
$nics = get_nics

# Initialize variables that we need for building the Terraform tfvars file
$rg_name = ''
$vnet_name = ''
$vnet_addr_space = ''
$device_subnet_name = ''
$device_subnet_cidr = ''
$device1_ip_addr = ''
$device2_ip_addr = ''
$subnet_nsg = @{}

# Identify specific items to deploy
if ( $deploy_method -eq 'new' ) {
    # New deploy, ask user for items that haven't already been specified
    $rg_name = Read-Host "Enter name of resource group (RG) to create"
} else {
    # Use existing- show user what is in Azure env and let them choose
    ## Here is a list of RGs, VNets, Subnets, resources

}
