#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export CI=1

echo "🚀 Starting TechVision Mail deployment (NO BUILD MODE)..."

# -------------------------------
# INIT BENCH
# -------------------------------
if [ ! -d "frappe-bench" ]; then
    bench init frappe-bench --frappe-branch version-17 --skip-redis-config-generation
fi

cd frappe-bench

# -------------------------------
# ENV CHECKS
# -------------------------------
: "${DB_ROOT_PASSWORD:?❌ DB_ROOT_PASSWORD is empty}"
: "${ADMIN_PASSWORD:?❌ ADMIN_PASSWORD is empty}"
: "${REDIS_CACHE:?❌ REDIS_CACHE is empty}"
: "${REDIS_QUEUE:?❌ REDIS_QUEUE is empty}"
: "${REDIS_SOCKETIO:?❌ REDIS_SOCKETIO is empty}"

# -------------------------------
# CONFIG (must exist)
# -------------------------------
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
# DB + REDIS
# -------------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host "$REDIS_CACHE"
bench set-redis-queue-host "$REDIS_QUEUE"
bench set-redis-socketio-host "$REDIS_SOCKETIO"

# -------------------------------
# CLEAN APP
# -------------------------------
rm -rf apps/mail

# -------------------------------
# GET APP (NO BUILD)
# -------------------------------
bench get-app https://github.com/frappe/mail --skip-assets

# 🚨 CRITICAL: DISABLE BUILD COMMANDS
echo "🚫 Disabling frontend build..."

cat > apps/mail/package.json <<EOF
{
  "name": "mail",
  "version": "1.0.0",
  "scripts": {}
}
EOF

# -------------------------------
# CREATE SITE
# -------------------------------
bench new-site mail.techvision.edu.et \
  --mariadb-root-password "$DB_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --force \
  --no-mariadb-socket

bench use mail.techvision.edu.et

# -------------------------------
# INSTALL APP (NO BUILD)
# -------------------------------
bench --site mail.techvision.edu.et install-app mail --skip-assets

# -------------------------------
# SKIP BUILD COMPLETELY
# -------------------------------
echo "⏭️ Skipping bench build..."

# -------------------------------
# FINALIZE
# -------------------------------
bench --site mail.techvision.edu.et set-config developer_mode 0
bench --site mail.techvision.edu.et clear-cache

echo "✅ Mail deployed WITHOUT frontend build!"