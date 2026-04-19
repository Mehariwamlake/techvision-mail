#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export CI=1

if [ ! -d "frappe-bench" ]; then
    echo "Initializing bench..."
    bench init frappe-bench --frappe-branch version-16 --skip-redis-config-generation
fi

cd frappe-bench

# FAIL SAFE CHECKS
if [ -z "$DB_ROOT_PASSWORD" ]; then
  echo "❌ DB_ROOT_PASSWORD is empty"
  exit 1
fi

if [ -z "$REDIS_CACHE" ]; then
  echo "❌ REDIS_CACHE is empty"
  exit 1
fi

# Redis setup (must be redis://)
bench set-mariadb-host mariadb
bench set-redis-cache-host "$REDIS_CACHE"
bench set-redis-queue-host "$REDIS_QUEUE"
bench set-redis-socketio-host "$REDIS_SOCKETIO"

# FIX: prevent overwrite prompt
rm -rf apps/mail || true

bench get-app https://github.com/frappe/mail

bench new-site mail.techvision.edu.et \
  --mariadb-root-password "$DB_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --install-app mail \
  --force \
  --no-mariadb-socket

bench use mail.techvision.edu.et

bench --site mail.techvision.edu.et set-config developer_mode 0
bench --site mail.techvision.edu.et clear-cache