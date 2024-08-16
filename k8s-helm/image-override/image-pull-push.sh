#!/bin/bash

# Default source registry
SOURCE_REGISTRY="registry.devopsnow.io"

# Target registry from environment variable or command line argument
TARGET_REGISTRY="${CONTAINER_TARGET_REGISTRY:-$1}"
CONTAINER_REGION="${CONTAINER_REGION:-$1}"
REPOSITORY_PREFIX="${REPOSITORY_PREFIX:-$1}"

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
if [ -z "$REPOSITORY_PREFIX" ]; then
    echo "Error: REPOSITORY_PREFIX is not specified."
    exit 1
fi


CONFIG_FILES=("public_images.txt" "private_images.txt" "internal_images.txt")

PULL_IMAGE_FAILS=()
PUSH_IMAGE_FAILS=()

for FILE in "${CONFIG_FILES[@]}"; 
do
    echo "Pushing images from FILE = '$FILE'"
    if [ ! -f "$FILE" ]; then
        echo "Error: Config file '$FILE' does not exist."
    else 
        IFS=_ read -r registryRepo temp <<< "$FILE"
        
        while IFS= read -r image; do

            IFS=: read -r imageRepo Tag <<< "$image"

            # Pull the image from the source registry
            docker pull "$SOURCE_REGISTRY/$registryRepo/$image"
            # Check if pull was successful
            if [ $? -ne 0 ]; then
                PULL_IMAGE_FAILS+=("$SOURCE_REGISTRY/$registryRepo/$image")
                continue # Skip to the next image if the pull fails
            fi

            # Retag the image for the target registry
            docker tag "$SOURCE_REGISTRY/$registryRepo/$image" "$TARGET_REGISTRY/$REPOSITORY_PREFIX/$image"

            # Check if the repository exists
            repository_info=$(aws ecr describe-repositories --repository-name "$REPOSITORY_PREFIX/$imageRepo" --region "$CONTAINER_REGION" 2>/dev/null)
            if [ -z "$repository_info" ]; then
                # Repository does not exist, create it
                aws ecr create-repository --repository-name "$REPOSITORY_PREFIX/$imageRepo" --region "$CONTAINER_REGION" --output text --image-scanning-configuration scanOnPush=true
                echo "Repository '$REPOSITORY_PREFIX/$imageRepo' created."
            else
                echo "Repository '$REPOSITORY_PREFIX/$imageRepo' already exists. Skipping creation."
            fi

            # Push the image to the target registry
            docker push "$TARGET_REGISTRY/$REPOSITORY_PREFIX/$image"
            # Check if push was successful
            if [ $? -ne 0 ]; then
                PUSH_IMAGE_FAILS+=("$TARGET_REGISTRY/$REPOSITORY_PREFIX/$image")
            fi

            # Remove the image from the local environment
            docker rmi "$SOURCE_REGISTRY/$registryRepo/$image"
            docker rmi "$TARGET_REGISTRY/$REPOSITORY_PREFIX/$image"
        done < "$FILE"
    fi
done

# Echo the list of failed pulls
if [ ${#PULL_IMAGE_FAILS[@]} -ne 0 ]; then
    echo "The following images were failed to pull:"
    for failed_image in "${PULL_IMAGE_FAILS[@]}"; do
        echo "$failed_image"
    done
fi

# Echo the list of failed pushes
if [ ${#PUSH_IMAGE_FAILS[@]} -ne 0 ]; then
    echo "The following images were failed to push:"
    for failed_image in "${PUSH_IMAGE_FAILS[@]}"; do
        echo "$failed_image"
    done
fi