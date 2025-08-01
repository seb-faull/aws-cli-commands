# Input file
$inputFile = "unique_accounts.txt"

# DynamoDB table names
$sourceTable = "usgmstrds-v1-p1-account"
$destTable   = "usgmstrds-v1-t1-account"

# AWS CLI profiles
$prodProfile = "uhub-prod"
$testProfile = "uhub-test"

# Static partition key value
$partitionKeyValue = "SOURCE"

# Read and process each account ID
Get-Content $inputFile | ForEach-Object {
    $accountId = $_.Trim()
    if (-not $accountId) { return }

    Write-Host "Processing account ID: $accountId"

    $keyJson = '{\"Type\":{\"S\":\"' + $partitionKeyValue + '\"},\"Id\":{\"S\":\"' + $accountId + '\"}}'

    $getItemOutput = aws dynamodb get-item `
        --profile $prodProfile `
        --table-name $sourceTable `
        --key "$keyJson" `
        --output json

    $jsonObject = $getItemOutput | ConvertFrom-Json

    if (-not $jsonObject.Item) {
        Write-Warning "No item found for $accountId in prod table"
        return
    }

    # Serialize Item to JSON string
    $itemJson = $jsonObject.Item | ConvertTo-Json -Depth 15 -Compress

    # Write to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
	
	# Create UTF8 encoding instance without BOM
	$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)

	# Write JSON to file without BOM
	[System.IO.File]::WriteAllText($tempFile, $itemJson, $utf8NoBomEncoding)

    # Put item using file input
    aws dynamodb put-item `
        --profile $testProfile `
        --table-name $destTable `
        --item file://$tempFile

    # Remove temp file
    Remove-Item $tempFile

    Write-Host "Copied $accountId to test environment"
}


