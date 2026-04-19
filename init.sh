version: "3.9"

services:

  # -------------------------
  # DATABASE
  # -------------------------
  mariadb:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql

  # -------------------------
  # REDIS
  # -------------------------
  redis:
    image: redis:7-alpine

  # -------------------------
  # FRONTEND BUILDER (ONE-TIME)
  # -------------------------
  builder:
    image: node:20
    working_dir: /workspace
    volumes:
      - .:/workspace
      - mail_assets:/assets
    command: >
      bash -c "
        echo '📥 Cloning mail...' &&
        rm -rf mail &&
        git clone https://github.com/frappe/mail mail &&

        cd mail &&
        corepack enable &&
        yarn install &&
        yarn build &&

        echo '📦 Copying assets...' &&
        mkdir -p /assets/mail &&
        cp -r public/* /assets/mail/

        echo '✅ Build complete'
      "

  # -------------------------
  # BACKEND (NO BUILD)
  # -------------------------
  backend:
    image: frappe/erpnext:version-16
    depends_on:
      - mariadb
      - redis
    working_dir: /home/frappe
    volumes:
      - mail_assets:/home/frappe/frappe-bench/sites/assets/mail
      - .:/workspace
    env_file:
      - .env
    command: bash /workspace/init.sh
    ports:
      - "8000:8000"

  # -------------------------
  # SOCKETIO (OPTIONAL)
  # -------------------------
  socketio:
    image: frappe/erpnext:version-16
    command: node /home/frappe/frappe-bench/apps/frappe/socketio.js
    depends_on:
      - backend
      - redis
    env_file:
      - .env

volumes:
  mariadb_data:
  mail_assets: