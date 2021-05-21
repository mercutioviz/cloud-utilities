$wafs = @{}
$regions=aws ec2 describe-regions | ConvertFrom-Json
foreach ($region in $regions.Regions.RegionName) {
    $regionwafs = aws ec2 describe-images --region $region --filters "Name=name,Values=CudaW*fw*" | ConvertFrom-Json
    $wafs[$region.Regions.RegionName] = $regionwafs.Images
}