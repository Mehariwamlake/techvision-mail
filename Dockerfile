FROM frappe/erpnext:version-16

USER root

# Install git (needed for app fetch)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN pip install pymysql

USER frappe

# Get Mail app at build time (NOT runtime)
RUN bench get-app https://github.com/frappe/mail

# Build assets (important)
RUN bench build