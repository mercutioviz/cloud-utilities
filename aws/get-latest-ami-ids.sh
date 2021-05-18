#!/bin/bash
#
# get-latest-ami-ids.sh
#
# Cycles through and collects latest WAF and CGF AMI Ids from AWS
#  Produces raw JSON output plus several "mappings" snippets
#

echo "Collecting WAF BYOL..."
echo '' > waf-byol.raw
for region in `aws ec2 describe-regions --output text | cut -f4`; do echo ${region} >> waf-byol.raw && aws ec2 describe-images --region $region --filters "Name=name,Values=CudaW*fw1*BYOL*" --query 'sort_by(Images, &CreationDate)[-1].ImageId' >> waf-byol.raw; done

echo "Collecting WAF PAYG..."
echo '' > waf-payg.raw
for region in `aws ec2 describe-regions --output text | cut -f4`; do echo ${region} >> waf-payg.raw && aws ec2 describe-images --region $region --filters "Name=name,Values=CudaW*fw1*PAYG*" --query 'sort_by(Images, &CreationDate)[-1].ImageId' >> waf-payg.raw; done

echo "Collecting CGF BYOL..."
echo '' > cgf-byol.raw
for region in `aws ec2 describe-regions --output text | cut -f4`; do echo ${region} >> cgf-byol.raw && aws ec2 describe-images --region $region --filters "Name=name,Values=CudaCGFBYOL*" --query 'sort_by(Images, &CreationDate)[-1].ImageId' >> cgf-byol.raw; done

echo "Collecting CGF PAYG (Hourly)..."
echo '' > cgf-payg.raw
for region in `aws ec2 describe-regions --output text | cut -f4`; do echo ${region} >> cgf-payg.raw && aws ec2 describe-images --region $region --filters "Name=name,Values=CudaCGFHourly*" --query 'sort_by(Images, &CreationDate)[-1].ImageId' >> cgf-payg.raw; done

