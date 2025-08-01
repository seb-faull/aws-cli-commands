# Define variables
$bucket = "ppluk-usgrcptfs-v1-p1"
$inputFile = "C:\Users\FaullS\.aws\airplay_2025_s3_metadata_keys.txt"
$localFolder = "C:\Users\FaullS\.aws\airplay_2025_s3Downloads"
$profile = "uhub-prod"

# Create local folder if it doesn't exist
if (-not (Test-Path $localFolder)) {
    New-Item -ItemType Directory -Path $localFolder -Force | Out-Null
}

# Read the keys from the input file
$keys = Get-Content $inputFile | Where-Object { $_ -and -not $_.StartsWith("#") }  # Ignore empty lines and comments

# Loop over keys and download files
foreach ($key in $keys) {
    $relativePath = $key -replace "^IncomingUsageFiles/", ""
    $destinationPath = Join-Path $localFolder $relativePath
    $destinationDir = Split-Path $destinationPath

    # Ensure directory exists
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    # Download the file
    Write-Host "Downloading $key..."
    aws s3 cp "s3://$bucket/$key" "$destinationPath" --profile $profile
}
