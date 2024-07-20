#!/bin/bash
# Copyright (c) 2016-2024 Crave.io Inc. All rights reserved

REPONAME="https://github.com/Eifal/AOSP_releases"
EXTRAFILES=$1
ZIP_FILES=""

# Check if token.txt exists
if [ ! -f token.txt ]; then
    echo "token.txt doesn't exist!"
    exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "gh could not be found. Installing gh..."
    curl -sS https://webi.sh/gh | sh
    source ~/.config/envman/PATH.env
    echo "gh installed."
fi

# Set Upload Limit to 3.5GB
GH_UPLOAD_LIMIT=3758096384
echo "Upload Limit is set to $GH_UPLOAD_LIMIT"

# Authenticate against github.com by reading the token from a file
gh auth login --with-token < token.txt

# Now do the same for ZIP_FILES
for zip_file in out/target/product/*/*.zip; do
    if [[ -n $zip_file && $(stat -c%s "$zip_file") -le $GH_UPLOAD_LIMIT ]]; then
        ZIP_FILES+="$zip_file "
        echo "Selecting $zip_file for Upload"
    else
        echo "Skipping $zip_file"
    fi
done
echo "Zip Files to be uploaded: $ZIP_FILES"
echo "Extra Files to be uploaded: $EXTRAFILES"

# Extract the filename without extension for tag and release name
RELEASETAG=$(basename "$ZIP_FILES" .zip)
RELEASETITLE=$RELEASETAG

# Create release
if [ "${DCDEVSPACE}" == "1" ]; then
    crave push token.txt -d $(crave ssh -- pwd | grep -v Select | sed -s 's/\r//g')/
    crave ssh -- "export GH_UPLOAD_LIMIT="$GH_UPLOAD_LIMIT"; bash /opt/crave/github-actions/upload.sh "$RELEASETAG" "" "$REPONAME" "$RELEASETITLE""
else
    gh release create $RELEASETAG $EXTRAFILES --repo $REPONAME --title $RELEASETITLE --generate-notes
    gh release upload $RELEASETAG --repo $REPONAME $ZIP_FILES
fi
