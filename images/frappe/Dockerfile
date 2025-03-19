ARG FRAPPE_BRANCH=v15.54.4

FROM frappe/build:${FRAPPE_BRANCH} AS builder

ARG FRAPPE_BRANCH=v15.54.4
ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG APPS_JSON_BASE64

USER root

RUN if [ -n "${APPS_JSON_BASE64}" ]; then \
    mkdir /opt/frappe && echo "${APPS_JSON_BASE64}" | base64 -d > /opt/frappe/apps.json; \
  fi

USER frappe

RUN export APP_INSTALL_ARGS="" && \
  if [ -n "${APPS_JSON_BASE64}" ]; then \
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

EXPOSE 8000 8080 8888 9000

ENTRYPOINT ["nginx-entrypoint.sh"]
