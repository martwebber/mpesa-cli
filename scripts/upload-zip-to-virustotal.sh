#!/bin/bash

# Script to upload Windows binaries to VirusTotal for security scanning
# Usage: ./upload-zip-to-virustotal.sh

set -e

if [[ -z "$VIRUSTOTAL_API_KEY" ]]; then
    echo "VIRUSTOTAL_API_KEY environment variable is not set"
    exit 1
fi

if [[ -z "$PERSONAL_ACCESS_TOKEN" ]]; then
    echo "PERSONAL_ACCESS_TOKEN environment variable is not set"
    exit 1
fi

# Get the latest release
LATEST_RELEASE=$(curl -s -H "Authorization: token $PERSONAL_ACCESS_TOKEN" \
    "https://api.github.com/repos/martwebber/mpesa-cli/releases/latest")

# Extract Windows zip URLs
WINDOWS_URLS=$(echo "$LATEST_RELEASE" | grep -o 'https://[^"]*windows[^"]*\.zip')

if [[ -z "$WINDOWS_URLS" ]]; then
    echo "No Windows zip files found in latest release"
    exit 1
fi

echo "Found Windows binaries to scan:"
echo "$WINDOWS_URLS"

# Upload each Windows binary to VirusTotal
echo "$WINDOWS_URLS" | while read -r url; do
    if [[ -n "$url" ]]; then
        echo "Downloading and scanning: $url"
        
        # Download the file
        filename=$(basename "$url")
        curl -L -o "/tmp/$filename" "$url"
        
        # Upload to VirusTotal
        response=$(curl -s -X POST \
            --form "apikey=$VIRUSTOTAL_API_KEY" \
            --form "file=@/tmp/$filename" \
            "https://www.virustotal.com/vtapi/v2/file/scan")
        
        # Extract scan_id from response
        scan_id=$(echo "$response" | grep -o '"scan_id":"[^"]*"' | cut -d'"' -f4)
        
        if [[ -n "$scan_id" ]]; then
            echo "✅ Uploaded $filename to VirusTotal. Scan ID: $scan_id"
            echo "🔍 View results at: https://www.virustotal.com/gui/file-analysis/$scan_id"
        else
            echo "❌ Failed to upload $filename to VirusTotal"
            echo "Response: $response"
        fi
        
        # Clean up
        rm -f "/tmp/$filename"
        
        # Rate limiting - VirusTotal allows 4 requests per minute for free accounts
        echo "Waiting 15 seconds for rate limiting..."
        sleep 15
    fi
done

echo "✅ Completed VirusTotal uploads"