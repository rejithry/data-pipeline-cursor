# Multi-stage build: download CLI in a stage with tools, then copy to Trino image
FROM curlimages/curl:latest AS cli-downloader
WORKDIR /tmp
RUN curl -fsSL https://repo1.maven.org/maven2/io/trino/trino-cli/456/trino-cli-456-executable.jar -o trino-cli.jar

FROM trinodb/trino:latest

# Copy Trino CLI from downloader stage
USER root
COPY --from=cli-downloader /tmp/trino-cli.jar /usr/local/bin/trino
RUN chmod +x /usr/local/bin/trino

# Install curl for health checks (try multiple package managers)
RUN set -eux; \
    if command -v curl >/dev/null 2>&1; then \
        echo "curl already available"; \
    elif command -v microdnf >/dev/null 2>&1; then \
        microdnf install -y curl && microdnf clean all; \
    elif command -v dnf >/dev/null 2>&1; then \
        dnf install -y curl && dnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
        yum install -y curl && yum clean all; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
        apk add --no-cache curl; \
    else \
        echo "Warning: Could not install curl. Health checks may fail."; \
    fi

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create SQL directory and copy SQL initialization file
RUN mkdir -p /opt/trino/sql
COPY sql/init-tables.sql /opt/trino/sql/init-tables.sql

USER trino

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
