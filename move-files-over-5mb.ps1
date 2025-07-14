# Set main directory and threshold
$sourceFolder = "C:\Users\FaullS\.aws\s3Downloads"
$targetRoot = Join-Path $sourceFolder "FilesOver5MB"
$sizeThresholdMB = 4.9
$sizeThresholdBytes = $sizeThresholdMB * 1MB

# Create target root folder if it doesn't exist
if (-not (Test-Path $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
}

# Get all files under source folder recursively
$allFiles = Get-ChildItem -Path $sourceFolder -Recurse -File

foreach ($file in $allFiles) {
    # Skip already moved files inside FilesOver5MB
    if ($file.FullName -like "$targetRoot*") { continue }

    if ($file.Length -gt $sizeThresholdBytes) {
        # Compute relative path from source root
        $relativePath = $file.FullName.Substring($sourceFolder.Length + 1)

        # Build new target path preserving subfolders
        $targetPath = Join-Path $targetRoot $relativePath
        $targetDir = Split-Path $targetPath

        # Create target directory if needed
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        # Move the file
        Write-Host "Moving $($file.FullName) to $targetPath"
        Move-Item -Path $file.FullName -Destination $targetPath
    }
}