#!/bin/bash
#
# create-mappings.sh
#
# Reads in the .raw files produced by the get-latest-ami-ids.sh script
#  Produces JSON and YAML "Mappings" blocks that can be pasted into CFTs
#

## WAF BYOL
echo '  Mappings:' > waf-byol.yaml
echo '    RegionMap:' >> waf-byol.yaml
cat waf-byol.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        ImageID: $1\n"; } else { print "      $_:\n"; }' >> waf-byol.yaml

echo '  "Mappings": {' > waf-byol.json
echo '    "RegionMap": {' >> waf-byol.json
cat waf-byol.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        \"ImageID\": \"$1\"\n      \},\n"; } else { print "      \"$_\": \{\n"; }' >> waf-byol.json
/bin/sed -i '$ s/.$//' waf-byol.json
echo '    }' >> waf-byol.json
echo '  }' >> waf-byol.json

## WAF PAYG
echo '  Mappings:' > waf-payg.yaml
echo '    RegionMap:' >> waf-payg.yaml
cat waf-payg.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        ImageID: $1\n"; } else { print "      $_:\n"; }' >> waf-payg.yaml

echo '  "Mappings": {' > waf-payg.json
echo '    "RegionMap": {' >> waf-payg.json
cat waf-payg.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        \"ImageID\": \"$1\"\n      \},\n"; } else { print "      \"$_\": \{\n"; }' >> waf-payg.json
/bin/sed -i '$ s/.$//' waf-payg.json
echo '    }' >> waf-payg.json
echo '  }' >> waf-payg.json

## CGF BYOL
echo '  Mappings:' > cgf-byol.yaml
echo '    RegionMap:' >> cgf-byol.yaml
cat cgf-byol.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        ImageID: $1\n"; } else { print "      $_:\n"; }' >> cgf-byol.yaml

echo '  "Mappings": {' > cgf-byol.json
echo '    "RegionMap": {' >> cgf-byol.json
cat cgf-byol.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        \"ImageID\": \"$1\"\n      \},\n"; } else { print "      \"$_\": \{\n"; }' >> cgf-byol.json
/bin/sed -i '$ s/.$//' cgf-byol.json
echo '    }' >> cgf-byol.json
echo '  }' >> cgf-byol.json

## CGF PAYG
echo '  Mappings:' > cgf-payg.yaml
echo '    RegionMap:' >> cgf-payg.yaml
cat cgf-payg.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        ImageID: $1\n"; } else { print "      $_:\n"; }' >> cgf-payg.yaml

echo '  "Mappings": {' > cgf-payg.json
echo '    "RegionMap": {' >> cgf-payg.json
cat cgf-payg.raw | tr -d '"' | perl -n -e 'chomp; next if /^$/; if ( /(ami.*)/ ) { print "        \"ImageID\": \"$1\"\n      \},\n"; } else { print "      \"$_\": \{\n"; }' >> cgf-payg.json
/bin/sed -i '$ s/.$//' cgf-payg.json
echo '    }' >> cgf-payg.json
echo '  }' >> cgf-payg.json

