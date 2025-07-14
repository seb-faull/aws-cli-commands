# Settings
$bucket = "ppluk-usgrcptfs-v1-p1"
$prefix = "IncomingUsageFiles"
$downloadFolder = "C:\Users\FaullS\.aws\s3DownloadsParallel"
$profile = "uhub-prod"
$maxJobs = 10  # Max parallel jobs at once

# Ensure destination exists
if (-not (Test-Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}

# Get filtered list of files
$keys = aws s3api list-objects-v2 `
  --bucket $bucket `
  --prefix $prefix `
  --query "Contents[?LastModified>'2024-12-31T23:59:59Z' && !ends_with(Key, '.keep')].[Key]" `
  --output text `
  --profile $profile |
  ForEach-Object {
    $key = ($_ -split "`t")[0]
    if ($key -notmatch '^IncomingUsageFiles/[0-9]') { $key }
  } | Select-Object -First 1369

# Function to download a single file
function Start-DownloadJob {
    param($key)

    $scriptBlock = {
        param($key, $bucket, $downloadFolder, $prefix, $profile)

        $relativePath = $key -replace "^$prefix/", ""
        $destination = Join-Path $downloadFolder $relativePath
        $folder = Split-Path $destination

        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }

        aws s3 cp "s3://$bucket/$key" "$destination" --profile $profile
    }

    Start-Job -ScriptBlock $scriptBlock -ArgumentList $key, $bucket, $downloadFolder, $prefix, $profile
}

# Throttle jobs to avoid overload
$jobQueue = @()
foreach ($key in $keys) {
    while (@(Get-Job -State "Running").Count -ge $maxJobs) {
        Start-Sleep -Seconds 2
    }

    $job = Start-DownloadJob -key $key
    $jobQueue += $job
}

# Wait for all jobs to finish
Write-Host "Waiting for all downloads to complete..."
$jobQueue | ForEach-Object { $_ | Wait-Job }

Write-Host "All downloads finished."
