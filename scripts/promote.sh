#!/usr/bin/env bash
set -e

# Arguments passed to the script
NEW_TAG=$1
ENVIRONMENT=$2 # dev or prod

if [ -z "$NEW_TAG" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: ./promote.sh <tag> <environment>"
    exit 1
fi

echo "Promoting mini-api version $NEW_TAG to $ENVIRONMENT environment..."

# 1. Clone the mini-gitops repository temporarily
git clone git@github.com:Frankroz/mini-gitops.git temp-gitops
cd temp-gitops

# 2. Configure git identity for the automation runner
git config user.name "CI-CD Bot"
git config user.email "ci-bot@example.com"

# 3. Navigate to the correct environment overlay
TARGET_FILE="overlays/$ENVIRONMENT/kustomization.yaml"

if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: Target file $TARGET_FILE not found!"
    exit 1
fi

# 4. Update the image tag using sed (or yq)
# This looks for the newTag line under the mini-api image definition and updates it
sed -i "/- name:.*mini-api/,/newTag:/{s/newTag: .*/newTag: $NEW_TAG/}" "$TARGET_FILE"

# 5. Check if there are actual changes to commit
if git diff --quiet; then
    echo "No changes detected. Image tag is already up to date."
    cd ..
    rm -rf temp-gitops
    exit 0
fi

# 6. Commit and push back to mini-gitops repo
git add "$TARGET_FILE"
git commit -m "chore(flux): promote mini-api to $NEW_TAG in $ENVIRONMENT"
git push origin main

echo "Successfully promoted $NEW_TAG to $ENVIRONMENT and updated mini-gitops!"

# 7. Cleanup
cd ..
rm -rf temp-gitops