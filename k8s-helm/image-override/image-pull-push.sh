#!/bin/bash

# Default source registry
SOURCE_REGISTRY="registry.devopsnow.io/public"

# Target registry from environment variable or command line argument
TARGET_REGISTRY="${CONTAINER_TARGET_REGISTRY:-$1}"

# Check if the target registry is provided
if [ -z "$TARGET_REGISTRY" ]; then
    echo "Error: Target cpntainer registry is not specified."
    echo "Usage: $0 <target-registry> or set CONTAINER_TARGET_REGISTRY environment variable."
    exit 1
fi

# Config file containing the list of Docker images
CONFIG_FILE="container_images_list.txt"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' does not exist."
    exit 1
fi

# Loop through each line in the config file
while IFS= read -r image; do
    # Pull the image from the source registry
    docker pull "$SOURCE_REGISTRY/$image"

    # Retag the image for the target registry
    docker tag "$SOURCE_REGISTRY/$image" "$TARGET_REGISTRY/$image"

    # Push the image to the target registry
    docker push "$TARGET_REGISTRY/$image"
done < "$CONFIG_FILE"
