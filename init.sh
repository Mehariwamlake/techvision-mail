#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export CI=1
export SKIP_ASSETS_BUILD=1

echo "🚀 Starting TechVision Mail deployment..."

if [ ! -d "frappe-bench" ]; then
    bench init frappe-bench --frappe-branch version-15 --skip-redis-config-generation
fi

cd frappe-bench

: "${DB_ROOT_PASSWORD:?❌ DB_ROOT_PASSWORD is empty}"
: "${ADMIN_PASSWORD:?❌ ADMIN_PASSWORD is empty}"
: "${REDIS_CACHE:?❌ REDIS_CACHE is empty}"
: "${REDIS_QUEUE:?❌ REDIS_QUEUE is empty}"
: "${REDIS_SOCKETIO:?❌ REDIS_SOCKETIO is empty}"

echo "🔧 Configuring services..."

bench set-mariadb-host mariadb
bench set-redis-cache-host "$REDIS_CACHE"
bench set-redis-queue-host "$REDIS_QUEUE"
bench set-redis-socketio-host "$REDIS_SOCKETIO"
# 🔥 REQUIRED FIX
bench set-config -g redis_socketio "$REDIS_SOCKETIO"
bench set-config -g redis_cache "$REDIS_CACHE"
bench set-config -g redis_queue "$REDIS_QUEUE"
bench set-config -g socketio_port 9000

echo "🧹 Cleaning old mail app..."
rm -rf apps/mail

echo "📥 Installing Mail app..."
bench get-app https://github.com/frappe/mail

echo "🏗️ Creating site..."

bench new-site mail.techvision.edu.et \
  --mariadb-root-password "$DB_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --force

bench --site mail.techvision.edu.et install-app mail

bench use mail.techvision.edu.et

bench --site mail.techvision.edu.et set-config developer_mode 0
bench --site mail.techvision.edu.et clear-cache

echo "✅ DONE"