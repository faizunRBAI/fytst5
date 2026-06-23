#!/bin/bash
set -euxo pipefail

# ── System update & Node.js 20 via NodeSource ─────────────────────────────────
dnf update -y
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs unzip aws-cli

# ── Verify Node.js version ────────────────────────────────────────────────────
node --version
npm --version

# ── Install PM2 globally ──────────────────────────────────────────────────────
npm install -g pm2

# ── Create app directory ──────────────────────────────────────────────────────
mkdir -p /opt/app

# ── Download app artifact from S3 ─────────────────────────────────────────────
aws s3 cp s3://${tf_state_bucket}/${project_name}/app.zip /tmp/app.zip --region ${aws_region}

# ── Extract app ───────────────────────────────────────────────────────────────
unzip -o /tmp/app.zip -d /opt/app
rm -f /tmp/app.zip

# ── Install Node dependencies ─────────────────────────────────────────────────
cd /opt/app
npm install --omit=dev

# ── Write .env file ───────────────────────────────────────────────────────────
cat > /opt/app/.env <<'ENVEOF'
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
PORT=3000
HOST=0.0.0.0
NODE_ENV=production
ENVEOF

chmod 600 /opt/app/.env

# ── Set ownership ─────────────────────────────────────────────────────────────
chown -R root:root /opt/app

# ── Start app with PM2 ────────────────────────────────────────────────────────
cd /opt/app
pm2 start /opt/app/server.js --name app --env production
pm2 save
pm2 startup systemd -u root --hp /root | tail -1 | bash || true

# ── Ensure PM2 restarts on reboot ─────────────────────────────────────────────
systemctl enable pm2-root || true