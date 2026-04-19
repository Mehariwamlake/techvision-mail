FROM frappe/erpnext:version-15

USER root

# Install git (needed for app fetch)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

USER frappe

# Get Mail app at build time (NOT runtime)
RUN bench get-app https://github.com/frappe/mail

# Build assets (important)
RUN bench build