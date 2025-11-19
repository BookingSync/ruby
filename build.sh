#!/bin/bash

set -euo pipefail

# Enter version/s to build
VERSIONS_TO_BUILD=("3.3")
TAG_TO_FIND="ENV RUBY_VERSION"

# Enter the ID of AWS ECR registry
# Main - 709657315391
# SLR - 820223782446
NAME="709657315391.dkr.ecr.eu-west-1.amazonaws.com/ruby-jemalloc"
# NAME="709657315391.dkr.ecr.eu-west-1.amazonaws.com/ruby-jemalloc"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for version in "${VERSIONS_TO_BUILD[@]}"; do
  dockerfiles=$(find "$SCRIPT_DIR/$version" -name Dockerfile)

  while IFS= read -r dockerfile; do
    [[ "$dockerfile" == *onbuild* || "$dockerfile" == *alpine* ]] && continue

    full_version=$(grep "$TAG_TO_FIND" "$dockerfile" | awk '{print $3}')
    base="${dockerfile#*$version/}"
    base="${base%/Dockerfile}"
    base="${base//\//-}"
    final_tag="${full_version}-${base}"
    image_name="${NAME}:${final_tag}"

    echo "Building $image_name"
    (
      cd "$(dirname "$dockerfile")"
      docker build --platform linux/amd64 -t "$image_name" .
      # Uncomment to push:
      # docker push "$image_name"
    )
  done <<< "$dockerfiles"
done
