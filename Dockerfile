FROM frappe/erpnext:version-15

USER root

# Install git + dependencies (safe minimal layer)
RUN apt-get update && apt-get install -y \
    git \
    python3-dev \
    default-libmysqlclient-dev \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

USER frappe

WORKDIR /home/frappe/frappe-bench

# ⚠️ DO NOT install apps or build here
# Apps must be installed at container runtime OR via entrypoint script