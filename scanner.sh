#!/bin/bash

# Define Docker Hub organization name
ORG_NAME="dell"  # Replace with your Docker organization name
DOCKER_USERNAME="megamindxy"  # Replace with your Docker Hub username
DOCKER_PASSWORD="Strongpass@1"  # Replace with your Docker Hub password or token

# Authenticate and get a list of all repositories in the organization
REPOS=$(curl -s -u "$DOCKER_USERNAME:$DOCKER_PASSWORD" "https://hub.docker.com/v2/repositories/$ORG_NAME/?page_size=100" | jq -r '.results[].name')

# Check if any repositories were found
if [ -z "$REPOS" ]; then
    echo "No repositories found for organization $ORG_NAME."
    exit 1
fi

# Loop through each repository
for REPO in $REPOS; do
    FULL_REPO="$ORG_NAME/$REPO"
    echo "Scanning Docker repository: $FULL_REPO"

    # Pull the latest image from the repository
    docker pull "$FULL_REPO"

    # Save Docker image to tar
    IMAGE_TAR="image.tar"
    docker save -o "$IMAGE_TAR" "$FULL_REPO"

    # Run TruffleHog to scan the Docker image tar file
    docker run -v "$(pwd):/scan" trufflesecurity/trufflehog filesystem /scan/"$IMAGE_TAR" \
        --json > trufflehog_report.json

    # Check if the report contains findings
    if grep -q "AWS" trufflehog_report.json; then
        echo "Secrets detected in $FULL_REPO. Review trufflehog_report.json for details."
        # Optional: send an alert or notification
    else
        echo "No secrets found in $FULL_REPO."
    fi

    # Clean up the saved image tar file and report
    rm -f "$IMAGE_TAR" trufflehog_report.json
done
