#!/bin/bash

# Default source registry
SOURCE_REGISTRY="registry.devopsnow.io"

# Target registry from environment variable or command line argument
TARGET_REGISTRY="${CONTAINER_TARGET_REGISTRY:-$1}"
CONTAINER_REGION="${CONTAINER_REGION:-$1}"

# Check if the target registry and container region is provided
if [ -z "$TARGET_REGISTRY" ]; then
    echo "Error: Target container registry is not specified."
    echo "Usage: $0 <target-registry> or set CONTAINER_TARGET_REGISTRY environment variable."
    exit 1
fi
if [ -z "$CONTAINER_REGION" ]; then
    echo "Error: Target container region is not specified."
    exit 1
fi


CONFIG_FILES=("public_images.txt" "private_images.txt" "internal_images.txt")

for FILE in "${CONFIG_FILES[@]}"; 
do
    echo "FILE = '$FILE'"
    if [ ! -f "$FILE" ]; then
        echo "Error: Config file '$FILE' does not exist."
    else 
        IFS=_ read -r registryRepo temp <<< "$FILE"
        
        while IFS= read -r image; do

            IFS=: read -r imageRepo Tag <<< "$image"

            # Pull the image from the source registry
            docker pull "$SOURCE_REGISTRY/$registryRepo/$image"

            # Retag the image for the target registry
            docker tag "$SOURCE_REGISTRY/$registryRepo/$image" "$TARGET_REGISTRY/$image"

            # Check if the repository exists
            repository_info=$(aws ecr describe-repositories --repository-name "$imageRepo" --region "$CONTAINER_REGION" 2>/dev/null)
            if [ -z "$repository_info" ]; then
                # Repository does not exist, create it
                aws ecr create-repository --repository-name "$imageRepo" --region "$CONTAINER_REGION" --output text --image-scanning-configuration scanOnPush=true
                echo "Repository '$imageRepo' created."
            else
                echo "Repository '$imageRepo' already exists. Skipping creation."
            fi

            # Push the image to the target registry
            docker push "$TARGET_REGISTRY/$image"
        done < "$FILE"
    fi
done
