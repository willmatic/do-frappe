ARG FRAPPE_BRANCH=version-15
FROM frappe/build:${FRAPPE_BRANCH} AS builder
ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG APPS_JSON_BASE64
USER root
# If you do not want to to install ERPNext, remove the object
#   but keep the file `app.json` as an empty list.
# i.e. `[]`
COPY ./apps.json /opt/frappe/apps.json
USER frappe
RUN export APP_INSTALL_ARGS="" && \
  if [ -f "/opt/frappe/apps.json" ]; then \
    export APP_INSTALL_ARGS="--apps_path=/opt/frappe/apps.json"; \
  fi && \
  bench init ${APP_INSTALL_ARGS}\
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json && \
  find apps -mindepth 1 -path "*/.git" | xargs rm -fr

FROM frappe/base:${FRAPPE_BRANCH} AS backend
USER frappe
COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench
WORKDIR /home/frappe/frappe-bench
VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/sites/assets", \
  "/home/frappe/frappe-bench/logs" \
]

USER root
COPY ./config/nginx-template.conf /templates/nginx/frappe.conf.template
COPY ./config/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh
COPY ./config/supervisor.conf /etc/supervisor/conf.d/frappe.conf
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    sudo \
    supervisor \
    jq

# Install Redli client for Redis TLS connections
RUN curl -L https://github.com/IBM-Cloud/redli/releases/download/v0.15.0/redli_0.15.0_linux_amd64.tar.gz -o redli.tar.gz && \
    tar xzf redli.tar.gz && \
    mv redli_linux_amd64 /usr/local/bin/redli && \
    chmod +x /usr/local/bin/redli && \
    rm redli.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Redis environment variables
ENV REDIS_CACHE="redis-cache:6379"
ENV REDIS_QUEUE="redis-queue:6379" 
ENV REDIS_SOCKETIO="redis-socketio:6379"

# Create a Redis configuration script using bench set-config (the proper Frappe way)
RUN cat > /home/frappe/configure-redis.sh << 'EOF'
#!/bin/bash
set -e

echo "Configuring Redis connections using bench set-config..."

cd /home/frappe/frappe-bench

# Configure Redis using the proper Frappe bench commands
bench set-config -g redis_cache "redis://${REDIS_CACHE}"
bench set-config -g redis_queue "redis://${REDIS_QUEUE}"
bench set-config -g redis_socketio "redis://${REDIS_SOCKETIO}"

echo "Redis configuration completed successfully!"
echo "Current Redis configuration:"
bench get-config redis_cache redis_queue redis_socketio
EOF

RUN chmod +x /home/frappe/configure-redis.sh && \
    chown frappe:frappe /home/frappe/configure-redis.sh

# Create a new entrypoint that configures Redis before starting services
RUN cat > /usr/local/bin/frappe-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting Frappe with Redis configuration..."

# Switch to frappe user and configure Redis
su - frappe -c "/home/frappe/configure-redis.sh"

# Then run the original nginx entrypoint
exec /usr/local/bin/nginx-entrypoint.sh "$@"
EOF

RUN chmod +x /usr/local/bin/frappe-entrypoint.sh

EXPOSE 8000 8080 8888 9000
ENTRYPOINT ["/usr/local/bin/frappe-entrypoint.sh"]
