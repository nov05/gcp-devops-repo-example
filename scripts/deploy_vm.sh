#!/bin/bash
# Exit immediately if any command in the script returns a non-zero status (i.e., fails).
set -e

# Load environment variables
source /workspace/env_vars.sh
VM_NAME="devops-vm"
LOG_FILE="/workspace/deployment.log"
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
    gcloud compute ssh "$VM_NAME" --zone="$ALLOWED_ZONE" --command "
        set -e
        sudo apt-get update
        sudo apt-get install -y docker.io nginx openssl
        sudo systemctl start docker
        sudo usermod -aG docker \$USER
        sudo gcloud auth configure-docker $ALLOWED_REGION-docker.pkg.dev --quiet

        # Run Docker container
        sudo docker pull $IMAGE
        sudo docker run -d -p 8080:80 --name app $IMAGE

        # Generate self-signed SSL cert
        sudo mkdir -p /etc/ssl/certs /etc/ssl/private
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/selfsigned.key \
            -out /etc/ssl/certs/selfsigned.crt \
            -subj \"/C=US/ST=State/L=City/O=DevOps/OU=IT/CN=\$(curl -s ifconfig.me)\"

        # Configure Nginx reverse proxy
        sudo bash -c 'cat > /etc/nginx/sites-available/app <<EOF
server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/selfsigned.key;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF'
        sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
        sudo nginx -t
        sudo systemctl restart nginx
    "
fi

echo "✅ Deployment finished for $VM_NAME"
