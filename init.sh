#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export CI=1

echo "🚀 Starting TechVision Mail deployment..."

# -------------------------------
# INIT BENCH
# -------------------------------
if [ ! -d "frappe-bench" ]; then
    echo "📦 Initializing bench..."
    bench init frappe-bench --frappe-branch version-17 --skip-redis-config-generation
fi

cd frappe-bench

# -------------------------------
# FAIL SAFE ENV CHECKS
# -------------------------------
: "${DB_ROOT_PASSWORD:?❌ DB_ROOT_PASSWORD is empty}"
: "${ADMIN_PASSWORD:?❌ ADMIN_PASSWORD is empty}"
: "${REDIS_CACHE:?❌ REDIS_CACHE is empty}"
: "${REDIS_QUEUE:?❌ REDIS_QUEUE is empty}"
: "${REDIS_SOCKETIO:?❌ REDIS_SOCKETIO is empty}"

# -------------------------------
# CREATE CONFIG FIRST (CRITICAL FIX)
# -------------------------------
echo "⚙️ Creating common_site_config.json..."

mkdir -p sites

cat > sites/common_site_config.json <<EOF
{
  "redis_cache": "$REDIS_CACHE",
  "redis_queue": "$REDIS_QUEUE",
  "redis_socketio": "$REDIS_SOCKETIO",
  "socketio_port": 9000
}
EOF

# -------------------------------
# REDIS + DB CONFIG
# -------------------------------
echo "🔧 Configuring Redis & MariaDB..."

bench set-mariadb-host mariadb
bench set-redis-cache-host "$REDIS_CACHE"
bench set-redis-queue-host "$REDIS_QUEUE"
bench set-redis-socketio-host "$REDIS_SOCKETIO"

# -------------------------------
# CLEAN PREVIOUS APP
# -------------------------------
echo "🧹 Cleaning old mail app..."
rm -rf apps/mail

# -------------------------------
# GET APP (NO BUILD)
# -------------------------------
echo "📥 Getting Mail app..."
bench get-app https://github.com/frappe/mail --skip-assets

# -------------------------------
# CREATE SITE
# -------------------------------
echo "🏗️ Creating site..."

bench new-site mail.techvision.edu.et \
  --mariadb-root-password "$DB_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --force \
  --no-mariadb-socket

bench use mail.techvision.edu.et

# -------------------------------
# INSTALL APP (NO BUILD)
# -------------------------------
echo "📦 Installing Mail app (no assets)..."

bench --site mail.techvision.edu.et install-app mail --skip-assets

# -------------------------------
# FIX NODE ENV (ONCE ONLY)
# -------------------------------
echo "🔨 Preparing frontend build..."

corepack enable || true
corepack prepare yarn@stable --activate || true

cd apps/mail

rm -rf node_modules yarn.lock bun.lockb

yarn cache clean || true
yarn install

# Ensure tailwind exists
yarn add -D tailwindcss postcss autoprefixer

cd ../..

# -------------------------------
# BUILD (AFTER CONFIG EXISTS)
# -------------------------------
echo "🏗️ Building assets..."

bench build --app mail

# -------------------------------
# FINALIZE
# -------------------------------
bench --site mail.techvision.edu.et set-config developer_mode 0
bench --site mail.techvision.edu.et clear-cache

echo "✅ Deployment completed successfully!"