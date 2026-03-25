#!/bin/bash
set -e
source ~/env_vars.sh
echo "👉 Running setup_vm.sh on $VM_NAME..." 

# Stop and remove existing container if exists
if sudo docker ps -a --format '{{.Names}}' | grep -q '^app$'; then
    echo "👉 Stopping and removing existing container..."
    sudo docker stop app || true
    sudo docker rm app || true
fi

# Install Docker, Nginx, OpenSSL (idempotent)
sudo apt-get update
sudo apt-get install -y docker.io nginx openssl
sudo systemctl start docker

# Add user to docker group (if needed)
sudo usermod -aG docker $USER || true

# Authenticate Docker with Artifact Registry
sudo gcloud auth configure-docker $ALLOWED_REGION-docker.pkg.dev --quiet

# Run Docker container on internal port 8080 (avoid conflicts)
echo "👉 Running Docker container on port 8080..."
sudo docker pull $IMAGE
sudo docker run -d -p 8080:80 --name app $IMAGE

# Generate self-signed SSL certificate
echo "👉 Creating self-signed SSL certificate..."
sudo mkdir -p /etc/ssl/certs /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/selfsigned.key \
    -out /etc/ssl/certs/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=DevOps/OU=IT/CN=$(curl -s ifconfig.me)"

# Configure Nginx reverse proxy (idempotent)
echo "👉 Configuring Nginx..."
sudo bash -c 'cat > /etc/nginx/sites-available/app <<EOF
server {
    listen 80;
    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/selfsigned.key;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'

# Enable site and reload Nginx
sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
sudo nginx -t
sudo systemctl restart nginx

echo "✅ setup_vm.sh completed successfully"
