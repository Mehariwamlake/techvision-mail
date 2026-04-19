#!/bin/bash
set -e

echo "🚀 Starting Frappe Bench Setup..."

BENCH_PATH="/home/frappe/frappe-bench"

# 1. Create bench if not exists
if [ ! -d "$BENCH_PATH" ]; then
    echo "📦 Initializing bench..."
    bench init $BENCH_PATH \
        --frappe-branch version-16 \
        --skip-redis-config-generation
fi

cd $BENCH_PATH

# 2. Force correct Redis config (IMPORTANT FIX)
echo "⚙️ Setting Redis configuration..."

mkdir -p sites

cat > sites/common_site_config.json <<EOF
{
  "redis_cache": "redis://redis-cache:6379",
  "redis_queue": "redis://redis-queue:6379",
  "redis_socketio": "redis://redis-socketio:6379"
}
EOF

# 3. Set MariaDB host
bench set-mariadb-host mariadb

# 4. Create site (only if not exists)
SITE_NAME=${SITE_NAME:-mail.techvision.edu.et}

if [ ! -d "sites/$SITE_NAME" ]; then
    echo "🌐 Creating site: $SITE_NAME"

    bench new-site $SITE_NAME \
        --mariadb-root-password ${DB_ROOT_PASSWORD:-frappepassword} \
        --admin-password ${ADMIN_PASSWORD:-admin} \
        --no-mariadb-socket
fi

# 5. Install app safely
echo "📦 Installing mail app..."

bench get-app mail || true
bench --site $SITE_NAME install-app mail || true

# 6. Set site as default
bench use $SITE_NAME

# 7. Final config
bench --site $SITE_NAME set-config developer_mode 0
bench --site $SITE_NAME clear-cache

echo "✅ Setup complete!"