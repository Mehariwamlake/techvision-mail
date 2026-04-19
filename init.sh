#!/bin/bash
set -e

if [ ! -d "frappe-bench" ]; then
    echo "Initializing bench..."
    bench init frappe-bench --frappe-branch version-16 --skip-redis-config-generation
fi

cd frappe-bench

bench set-mariadb-host mariadb
bench set-redis-cache-host $REDIS_CACHE
bench set-redis-queue-host $REDIS_QUEUE
bench set-redis-socketio-host $REDIS_SOCKETIO

bench get-app https://github.com/frappe/mail

bench new-site mail.techvision.edu.et \
  --mariadb-root-password $DB_ROOT_PASSWORD \
  --admin-password $ADMIN_PASSWORD \
  --install-app mail
bench use mail.techvision.edu.et

bench --site mail.techvision.edu.et set-config developer_mode 0
bench --site mail.techvision.edu.et clear-cache