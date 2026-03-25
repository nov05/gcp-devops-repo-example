#!/bin/bash
# Exit immediately if any command in the script returns a non-zero status (i.e., fails).
set -e

# Load environment variables
source /workspace/env_vars.sh
VM_NAME="devops-vm"
echo "VM_NAME=$VM_NAME" >> /workspace/env_vars.sh
echo "👉 Deploying commit $COMMIT_SHA to VM $VM_NAME in zone $ALLOWED_ZONE..." | tee -a "$LOG_FILE"

# Check if VM exists
if gcloud compute instances describe "$VM_NAME" --zone="$ALLOWED_ZONE" >/dev/null 2>&1; then
    echo "👉 VM $VM_NAME exists → redeploying Docker container..."
    gcloud compute ssh "$VM_NAME" --zone="$ALLOWED_ZONE" --command "
        set -e
        sudo gcloud auth configure-docker $ALLOWED_REGION-docker.pkg.dev --quiet
        sudo docker pull $IMAGE
        sudo docker stop app || true
        sudo docker rm app || true
        sudo docker run -d -p 8080:80 --name app $IMAGE
    "
else
    echo "👉 VM $VM_NAME does not exist → creating VM..."
    gcloud compute instances create "$VM_NAME" \
        --zone="$ALLOWED_ZONE" \
        --machine-type=e2-medium \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --tags=http-server,https-server \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --labels=deployed-by=cloud-build,commit-sha="$COMMIT_SHA"

    echo "👉 Waiting for SSH to become available..."
    for i in {1..12}; do
        if gcloud compute ssh "$VM_NAME" --zone="$ALLOWED_ZONE" --command "echo ready" -q >/dev/null 2>&1; then
            break
        fi
        echo "SSH not ready yet... retrying in 10s"
        sleep 10
    done

    echo "👉 Installing Docker and Nginx on new VM..."
    # Copy env_vars.sh to VM
    gcloud compute scp /workspace/env_vars.sh "$VM_NAME":~/env_vars.sh --zone="$ALLOWED_ZONE"
    # Copy the setup script to the VM
    gcloud compute scp /workspace/scripts/setup_vm.sh "$VM_NAME":~/setup_vm.sh --zone="$ALLOWED_ZONE"
    # Run the script on the VM
    gcloud compute ssh "$VM_NAME" --zone="$ALLOWED_ZONE" --command "bash ~/setup_vm.sh"
fi

echo "✅ Deployment finished for $VM_NAME"
