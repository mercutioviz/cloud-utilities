$wafs = @{}
$versions = @{}
$regions=aws ec2 describe-regions | ConvertFrom-Json

if ( Test-Path ./wafs.dat ) {
    #$wafs = Get-Content -Path ./wafs.dat
    foreach ($region in $regions.Regions.RegionName) {
        Write-Host "Reading Json data for $region..." -ForegroundColor Yellow
    	$fname = "./{0}.json" -f $region
        $regionwafsjson = Get-Content $fname
	$regionwafs = $regionwafsjson | ConvertFrom-Json -Depth 20
	$wafs[$region] = $regionwafs.Images
    }
} else {
    #$regions=aws ec2 describe-regions | ConvertFrom-Json
    foreach ($region in $regions.Regions.RegionName) {
    	Write-Host "Region: $region..." -ForegroundColor Magenta
        $regionwafsjson = aws ec2 describe-images --region $region --filters "Name=name,Values=CudaW*fw*"
	$regionwafs = $regionwafsjson | ConvertFrom-Json -Depth 20
        $wafs[$region] = $regionwafs.Images
        $fname = "./{0}.json" -f $region
        Write-Host "File: $fname" -ForegroundColor Cyan
        $regionwafsjson | Out-File -Filepath $fname
    }
}
$wafs | Out-File -Filepath ./wafs.dat
# Break out in format:
#  version => region => sku
#
#  Ex:
#  "Mappings": {
#    "amiMapMap": {
#      "latest": {
#        "mapName": "10.1.1.016"
#        },
#      "10.1.1.016": {
#        "us-west-2": {
#          "Hourly": "ami-",
#          "BYOL": "ami-",
#          "Metered": "ami-"
#        },
#
# Sample w/ regex to parse out info
# foreach ($waf in $wafs['us-west-2']) { if ( $waf.Description -match "CudaWAF(?:-p\d)?-(?<vm>vm[^-]+)-fw(?<fw>[^-]+)-(?<date>[^-]+)-(?<sku>.*)" ) { write-host $Matches.fw "us-west-2" $Matches.sku $waf.ImageId } else { Write-Host "NOPE" -ForegroundColor Red } }

foreach ( $region in $regions.Regions.RegionName ) {
    write-host "Region: $region" -ForegroundColor Cyan
    #$wafs["$region"]
    foreach ( $image in $wafs[$region] ) {
        Write-Host("Processing {0} {1}" -f $region, $image.Description) -ForegroundColor Green
	if ( $image.Description -match
	  "CudaWAF(?:-p\d)?-(?<vm>vm[^-]+)-fw(?<fw>[^-]+)-(?<date>[^-]+)-(?<sku>.*)" ) {
	    Write-Host $Matches.fw $region $Matches.sku $image.ImageId
	    if ( $versions.ContainsKey($Matches.fw) ) {
	        if ( $versions[$Matches.fw].ContainsKey($region) ) {
		    $versions[$Matches.fw][$region][$Matches.sku] = $image.ImageId
		} else {
		    $versions[$Matches.fw][$region] = @{}
		    $versions[$Matches.fw][$region][$Matches.sku] = $image.ImageId
		}
	    } else {
	        $versions[$Matches.fw] = @{}
		$versions[$Matches.fw][$region] = @{}
		$versions[$Matches.fw][$region][$Matches.sku] = $image.ImageId
	    }
        }
    }    
}

$sorted = [ordered]@{}

foreach ( $version in $versions.Keys | Sort-Object { [version] $_ } -Descending ) {
    $sorted[$version] = [ordered]@{}
    foreach ( $region in $regions.Regions.RegionName | Sort-Object ) {
        $sorted[$version][$region] = [ordered]@{}
	if ( $versions.ContainsKey($version) ) {
	    #Write-Host "FW Version: $version" -ForegroundColor Magenta
	    if ( $versions[$version].ContainsKey($region) ) {
	        ## Filter out "vmr-" and "expanded-" version names
		foreach ( $sku in $versions[$version][$region].Keys | Sort-Object ) {
		    if ( $sku -match "vmr-(?<sku>.*)" ) {
		        $sorted[$version][$region][$Matches.sku] = $versions[$version][$region][$sku]
		    } elseif ( $sku -match "(?<sku>.*?)-Expanded" ) {
		        $sorted[$version][$region][$Matches.sku] = $versions[$version][$region][$sku]
		    } else {
	                $sorted[$version][$region][$sku] = $versions[$version][$region][$sku]
		    }
		}
	    }
	}
    }
}

# Final cleanup- remove empty keys
foreach ( $version in $sorted.Keys ) {
    $deleteme = New-Object System.Collections.ArrayList
    foreach ( $region in $sorted[$version].Keys ) {
        if ( $sorted[$version][$region].Count -eq 0 ) {
	    Write-Host "Found region: $region in $version" -ForegroundColor Red
	    $null = $deleteme.Add($region)
	}
    }
    foreach ( $region in $deleteme ) {
        $sorted[$version].Remove($region)
    }
}


# Build mappings
#  "Mappings": {
#     "amiMapMap": {
#        "Latest-BYOL": {
#           "mapName": "10.1.1.016"
#

$mappings = @{}
$mappings['Mappings'] = [ordered]@{}
$mappings['Mappings']['amiMapMap'] = [ordered]@{}
foreach ( $version in $sorted.Keys ) {
    $mappings['Mappings']['amiMapMap'][$version] = @{}
    $mappings['Mappings']['amiMapMap'][$version]['mapName'] = $version
}

## Final touch - insert version maps after 'amiMapMap' and create final JSON data
foreach ( $version in $sorted.Keys ) {
    $mappings['Mappings'][$version] = $sorted[$version]
}

$wafsjson = $mappings | ConvertTo-Json -Depth 10
Set-Content -Path ./wafs.json -Value $wafsjson
