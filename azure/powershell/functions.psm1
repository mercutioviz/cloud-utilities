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

## Utility functions ##
function dprint {
    param (
        [string]$message,
        [Parameter(Mandatory=$false)]
        [string]
        [validateset("Red","Green","Yellow","Cyan","Magenta","Gray","White")]
        $color = "Yellow"
    )
    
    Write-Host "Debug pref is $DebugPreference ($Debug)"
    Write-Host "$message" -ForegroundColor $color
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

###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-IPv4Subnet.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Calculate a subnet based on an IP-Address and the subnetmask or CIDR
# Repository   :  https://github.com/BornToBeRoot/PowerShell
###############################################################################################################

<#
    .SYNOPSIS
    Calculate a subnet based on an IP-Address and the subnetmask or CIDR

    .DESCRIPTION
    Calculate a subnet based on an IP-Address within the subnet and the subnetmask or CIDR. The result includes the NetworkID, Broadcast, total available IPs and usable IPs for hosts.
                
    .EXAMPLE
    Get-IPv4Subnet -IPv4Address 192.168.24.96 -CIDR 27
    
    NetworkID     Broadcast      IPs Hosts
    ---------     ---------      --- -----
    192.168.24.96 192.168.24.127  32    30
            
    .EXAMPLE
    Get-IPv4Subnet -IPv4Address 192.168.1.0 -Mask 255.255.255.0 | Select-Object -Property *

    NetworkID : 192.168.1.0
    FirstIP   : 192.168.1.1
    LastIP    : 192.168.1.254
    Broadcast : 192.168.1.255
    IPs       : 256
    Hosts     : 254

    .LINK
    https://github.com/BornToBeRoot/PowerShell/blob/master/Documentation/Function/Get-IPv4Subnet.README.md
#>

function Get-IPv4Subnet
{
    [CmdletBinding(DefaultParameterSetName='CIDR')]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address which is in the subnet')]
        [IPAddress]$IPv4Address,

        [Parameter(
            ParameterSetName='CIDR',
            Position=1,
            Mandatory=$true,
            HelpMessage='CIDR like /24 without "/"')]
        [ValidateRange(0,31)]
        [Int32]$CIDR,

        [Parameter(
            ParameterSetName='Mask',
            Position=1,
            Mandatory=$true,
            Helpmessage='Subnetmask like 255.255.255.0')]
        [ValidateScript({
            if($_ -match "^(254|252|248|240|224|192|128).0.0.0$|^255.(254|252|248|240|224|192|128|0).0.0$|^255.255.(254|252|248|240|224|192|128|0).0$|^255.255.255.(254|252|248|240|224|192|128|0)$")
            {
                return $true
            }
            else 
            {
                throw "Enter a valid subnetmask (like 255.255.255.0)!"
            }
        })]
        [String]$Mask
    )

    Begin{
   
    }

    Process{
        # Convert Mask or CIDR - because we need both in the code below
        switch($PSCmdlet.ParameterSetName)
        {
            "CIDR" {                          
                $Mask = (Convert-Subnetmask -CIDR $CIDR).Mask            
            }

            "Mask" {
                $CIDR = (Convert-Subnetmask -Mask $Mask).CIDR          
            }              
        }
        
        # Get CIDR Address by parsing it into an IP-Address
        $CIDRAddress = [System.Net.IPAddress]::Parse([System.Convert]::ToUInt64(("1"* $CIDR).PadRight(32, "0"), 2))
    
        # Binary AND ... this is how subnets work.
        $NetworkID_bAND = $IPv4Address.Address -band $CIDRAddress.Address

        # Return an array of bytes. Then join them.
        $NetworkID = [System.Net.IPAddress]::Parse([System.BitConverter]::GetBytes([UInt32]$NetworkID_bAND) -join ("."))
        
        # Get HostBits based on SubnetBits (CIDR) // Hostbits (32 - /24 = 8 -> 00000000000000000000000011111111)
        $HostBits = ('1' * (32 - $CIDR)).PadLeft(32, "0")
        
        # Convert Bits to Int64
        $AvailableIPs = [Convert]::ToInt64($HostBits,2)

        # Convert Network Address to Int64
        $NetworkID_Int64 = (Convert-IPv4Address -IPv4Address $NetworkID.ToString()).Int64

        # Calculate the first Host IPv4 Address by add 1 to the Network ID
        $FirstIP = [System.Net.IPAddress]::Parse((Convert-IPv4Address -Int64 ($NetworkID_Int64 + 1)).IPv4Address)

        # Calculate the last Host IPv4 Address by subtract 1 from the Broadcast Address
        $LastIP = [System.Net.IPAddress]::Parse((Convert-IPv4Address -Int64 ($NetworkID_Int64 + ($AvailableIPs - 1))).IPv4Address)

        # Convert add available IPs and parse into IPAddress
        $Broadcast = [System.Net.IPAddress]::Parse((Convert-IPv4Address -Int64 ($NetworkID_Int64 + $AvailableIPs)).IPv4Address)

        # Change useroutput ==> (/27 = 0..31 IPs -> AvailableIPs 32)
        $AvailableIPs += 1

        # Hosts = AvailableIPs - Network Address + Broadcast Address
        $Hosts = ($AvailableIPs - 2)
            
        # Build custom PSObject
        $Result = [pscustomobject] @{
            NetworkID = $NetworkID
            FirstIP = $FirstIP
            LastIP = $LastIP
            Broadcast = $Broadcast
            IPs = $AvailableIPs
            Hosts = $Hosts
        }

        # Set the default properties
        $Result.PSObject.TypeNames.Insert(0,'Subnet.Information')

        $DefaultDisplaySet = 'NetworkID', 'Broadcast', 'IPs', 'Hosts'

        $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultDisplaySet)

        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)

        $Result | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        
        # Return the object to the pipeline
        $Result
    }

    End{

    }
}

###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Convert-Subnetmask.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Convert a subnetmask to CIDR and vise versa
# Repository   :  https://github.com/BornToBeRoot/PowerShell
###############################################################################################################

<#
    .SYNOPSIS
    Convert a subnetmask to CIDR and vise versa

    .DESCRIPTION
    Convert a subnetmask like 255.255.255 to CIDR (/24) and vise versa.
                
    .EXAMPLE
    Convert-Subnetmask -CIDR 24

    Mask          CIDR
    ----          ----
    255.255.255.0   24

    .EXAMPLE
    Convert-Subnetmask -Mask 255.255.0.0

    Mask        CIDR
    ----        ----
    255.255.0.0   16
    
    .LINK
    https://github.com/BornToBeRoot/PowerShell/blob/master/Documentation/Function/Convert-Subnetmask.README.md
   
#>

function Convert-Subnetmask
{
    [CmdLetBinding(DefaultParameterSetName='CIDR')]
    param( 
        [Parameter( 
            ParameterSetName='CIDR',       
            Position=0,
            Mandatory=$true,
            HelpMessage='CIDR like /24 without "/"')]
        [ValidateRange(0,32)]
        [Int32]$CIDR,

        [Parameter(
            ParameterSetName='Mask',
            Position=0,
            Mandatory=$true,
            HelpMessage='Subnetmask like 255.255.255.0')]
        [ValidateScript({
            if($_ -match "^(254|252|248|240|224|192|128).0.0.0$|^255.(254|252|248|240|224|192|128|0).0.0$|^255.255.(254|252|248|240|224|192|128|0).0$|^255.255.255.(255|254|252|248|240|224|192|128|0)$")
            {
                return $true
            }
            else 
            {
                throw "Enter a valid subnetmask (like 255.255.255.0)!"    
            }
        })]
        [String]$Mask
    )

    Begin {

    }

    Process {
        switch($PSCmdlet.ParameterSetName)
        {
            "CIDR" {                          
                # Make a string of bits (24 to 11111111111111111111111100000000)
                $CIDR_Bits = ('1' * $CIDR).PadRight(32, "0")
                
                # Split into groups of 8 bits, convert to Ints, join up into a string
                $Octets = $CIDR_Bits -split '(.{8})' -ne ''
                $Mask = ($Octets | ForEach-Object -Process {[Convert]::ToInt32($_, 2) }) -join '.'
            }

            "Mask" {
                # Convert the numbers into 8 bit blocks, join them all together, count the 1
                $Octets = $Mask.ToString().Split(".") | ForEach-Object -Process {[Convert]::ToString($_, 2)}
                $CIDR_Bits = ($Octets -join "").TrimEnd("0")

                # Count the "1" (111111111111111111111111 --> /24)                     
                $CIDR = $CIDR_Bits.Length             
            }               
        }

        [pscustomobject] @{
            Mask = $Mask
            CIDR = $CIDR
        }
    }

    End {
        
    }
}

###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Convert-IPv4Address
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Convert an IPv4-Address to Int64 and vise versa
# Repository   :  https://github.com/BornToBeRoot/PowerShell
###############################################################################################################

<#
    .SYNOPSIS
    Convert an IPv4-Address to Int64 and vise versa

    .DESCRIPTION
    Convert an IPv4-Address to Int64 and vise versa. The result will contain the IPv4-Address as string and Tnt64.
    
    .EXAMPLE
    Convert-IPv4Address -IPv4Address "192.168.0.1"   

    IPv4Address      Int64
    -----------      -----
    192.168.0.1 3232235521

    .EXAMPLE
    Convert-IPv4Address -Int64 2886755428

    IPv4Address         Int64
    -----------         -----
    172.16.100.100 2886755428

    .LINK
    https://github.com/BornToBeRoot/PowerShell/blob/master/Documentation/Function/Convert-IPv4Address.README.md
#>

function Convert-IPv4Address
{
    [CmdletBinding(DefaultParameterSetName='IPv4Address')]
    param(
        [Parameter(
            ParameterSetName='IPv4Address',
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address as string like "192.168.1.1"')]
        [IPAddress]$IPv4Address,

        [Parameter(
                ParameterSetName='Int64',
                Position=0,
                Mandatory=$true,
                HelpMessage='IPv4-Address as Int64 like 2886755428')]
        [long]$Int64
    ) 

    Begin {

    }

    Process {
        switch($PSCmdlet.ParameterSetName)
        {
            # Convert IPv4-Address as string into Int64
            "IPv4Address" {
                $Octets = $IPv4Address.ToString().Split(".")
                $Int64 = [long]([long]$Octets[0]*16777216 + [long]$Octets[1]*65536 + [long]$Octets[2]*256 + [long]$Octets[3]) 
            }
    
            # Convert IPv4-Address as Int64 into string 
            "Int64" {            
                $IPv4Address = (([System.Math]::Truncate($Int64/16777216)).ToString() + "." + ([System.Math]::Truncate(($Int64%16777216)/65536)).ToString() + "." + ([System.Math]::Truncate(($Int64%65536)/256)).ToString() + "." + ([System.Math]::Truncate($Int64%256)).ToString())
            }      
        }

        [pscustomobject] @{    
            IPv4Address = $IPv4Address
            Int64 = $Int64
        }        	
    }

    End {

    }      
}

