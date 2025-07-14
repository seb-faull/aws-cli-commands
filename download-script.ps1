# Define variables
$bucket = "ppluk-usgrcptfs-v1-p1"
$prefix = "IncomingUsageFiles"
$localFolder = "C:\Users\FaullS\.aws\s3Downloads-2.5-to-4.9MB"
$profile = "uhub-prod"
$numOfFilesToDownload = 1369
$minSize = 2.5 * 1024 * 1024   # 2.5MB in bytes
$maxSize = 4.9 * 1024 * 1024   # 4.9MB in bytes

# Create local folder if it doesn't exist
if (-not (Test-Path $localFolder)) {
    New-Item -ItemType Directory -Path $localFolder -Force | Out-Null
}

# Get filtered list of keys and sizes
$objects = aws s3api list-objects-v2 `
  --bucket $bucket `
  --prefix $prefix `
  --query "Contents[?LastModified>'2024-12-31T23:59:59Z' && !ends_with(Key, '.keep')].[Key, Size]" `
  --output text `
  --profile $profile

# Filter keys based on size and folder name
$filteredObjects = $objects | ForEach-Object {
    $parts = $_ -split "\t"
    $key = $parts[0]
    $size = [int64]$parts[1]

    if ($key -notmatch '^IncomingUsageFiles/[0-9]' -and $size -ge $minSize -and $size -le $maxSize) {
        [PSCustomObject]@{ Key = $key; Size = $size }
    }
} | Select-Object -First $numOfFilesToDownload

# Loop over keys and download files
foreach ($obj in $filteredObjects) {
    $key = $obj.Key
    $relativePath = $key -replace "^$prefix/", ""
    $destinationPath = Join-Path $localFolder $relativePath
    $destinationDir = Split-Path $destinationPath

    # Ensure directory exists
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    # Download the file
    Write-Host "Downloading $key ($($obj.Size) bytes)..."
    aws s3 cp "s3://$bucket/$key" "$destinationPath" --profile $profile
}