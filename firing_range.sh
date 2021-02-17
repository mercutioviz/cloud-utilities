#!/bin/bash
#
# Setup firing range of vulnerable web apps
#
# Tested on Debian 10 Buster and Ubuntu 18.04 LTS
# Strongly recommend 2 vCPUs and 7+ GB RAM, ex B2ms or DS2_v3
#
# Run under sudo or as root
#
# If first time it will install docker and install the docker containers
# Subsequent times it will just launch the containers
#   Perfect for manually starting all the vulnerable apps

#!/bin/bash
if [ "$EUID" -ne 0 ]
then echo "Please run as sudo/root"
  exit
fi

apt-get update
apt-get upgrade -y
apt install docker.io -y

docker run -d -p 1000:80 vulnerables/web-dvwa
docker run -d -p 2000:80 szsecurity/mutillidae
docker run -d -p 3000:80 szsecurity/webgoat
docker run -d -p 4000:80 raesene/bwapp
docker run -d -p 5000:3000 bkimminich/juice-shop
docker run -d -p 6001:8080 eystsen/altoro
docker run -d -p 7000:80 kennethreitz/httpbin
docker run -d -p 8000:80 mutzel/all-in-one-hackazon:postinstall supervisord -n
docker run -d -p 9000:8080 swaggerapi/petstore
