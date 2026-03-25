#!/bin/bash
set -e

# Install Docker, Nginx, OpenSSL
sudo apt-get update
sudo apt-get install -y docker.io nginx openssl
sudo systemctl start docker
sudo usermod -aG docker $USER

# Authenticate Docker with Artifact Registry
sudo gcloud auth configure-docker $ALLOWED_REGION-docker.pkg.dev --quiet

# Run Docker container
sudo docker pull $IMAGE
sudo docker run -d -p 8080:80 --name app $IMAGE

# Generate self-signed SSL certificate
sudo mkdir -p /etc/ssl/certs /etc/ssl/private
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/selfsigned.key \
    -out /etc/ssl/certs/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=DevOps/OU=IT/CN=$(curl -s ifconfig.me)"

# Configure Nginx reverse proxy
sudo bash -c <<'EOF' > /etc/nginx/sites-available/app
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
EOF

sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
sudo nginx -t
sudo systemctl restart nginx
