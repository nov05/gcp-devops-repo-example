#!/bin/bash
# Exit immediately if any command in the script returns a non-zero status (i.e., fails).
set -e

echo "👉 Detecting Project ID, allowed region, and allowed zone..."

PROJECT_ID=$(gcloud config get-value project)

yes | gcloud services enable orgpolicy.googleapis.com --project=$PROJECT_ID --quiet

# Detect allowed lab region
ALLOWED_REGION=$(gcloud org-policies describe constraints/gcp.resourceLocations \
  --project=$PROJECT_ID \
  --format="value(spec.rules[0].values.allowedValues)" \
  | grep -oP '(?<=in:)(us|europe)[a-z0-9-]+(?=-locations)' \
  | head -n 1)

# Pick first available zone alphabetically
ALLOWED_ZONE=$(gcloud compute zones list \
  --filter="region:($ALLOWED_REGION) AND status:UP" \
  --format="value(name)" \
  | sort \
  | head -n 1)

echo "PROJECT_ID=$PROJECT_ID" > /workspace/env_vars.sh
echo "ALLOWED_REGION=$ALLOWED_REGION" >> /workspace/env_vars.sh
echo "ALLOWED_ZONE=$ALLOWED_ZONE" >> /workspace/env_vars.sh

echo "✅ Project ID, allowed region, and allowed zone detected: $PROJECT_ID, $ALLOWED_REGION, $ALLOWED_ZONE"
