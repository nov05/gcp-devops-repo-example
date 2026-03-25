#!/bin/bash
set -e

echo "👉 Ensuring HTTP firewall rule exists..."
if ! gcloud compute firewall-rules describe allow-http >/dev/null 2>&1; then
  gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --target-tags=http-server \
    --description="Allow HTTP traffic" || echo "HTTP rule may already exist"
  echo "✅ HTTP firewall rule created."
else
  echo "✅ HTTP firewall rule already exists."
fi

echo "👉 Ensuring HTTPS firewall rule exists..."
if ! gcloud compute firewall-rules describe allow-https >/dev/null 2>&1; then
  gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --target-tags=https-server \
    --description="Allow HTTPS traffic" || echo "HTTPS rule may already exist"
  echo "✅ HTTPS firewall rule created."
else
  echo "✅ HTTPS firewall rule already exists."
fi
