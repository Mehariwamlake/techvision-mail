#!/bin/bash
set -e

if [ ! -d "frappe-bench" ]; then
    echo "Initializing bench..."
    bench init frappe-bench --frappe-branch version-15 --skip-redis-config-generation
fi

cd frappe-bench

bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

bench get-app mail

bench new-site mail.localhost \
  --mariadb-root-password $DB_ROOT_PASSWORD \
  --admin-password $ADMIN_PASSWORD \
  --install-app mail

bench --site mail.localhost set-config developer_mode 0
bench --site mail.localhost clear-cache