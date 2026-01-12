# Multi-stage build: download CLI in a stage with tools, then copy to Trino image
# Use the regular JAR (not executable) to avoid x86-64-v3 CPU requirement during build
FROM curlimages/curl:latest AS cli-downloader
WORKDIR /tmp
# Download the regular JAR (not executable) - version 456
RUN curl -fsSL https://repo1.maven.org/maven2/io/trino/trino-cli/456/trino-cli-456.jar -o trino-cli.jar

FROM trinodb/trino:latest

# Copy Trino CLI from downloader stage
USER root
# Store CLI as a regular JAR file (will be executed with java -jar at runtime)
COPY --from=cli-downloader /tmp/trino-cli.jar /opt/trino/trino-cli.jar

# Copy entrypoint script (make it executable)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Create SQL directory and copy SQL initialization file
# Use COPY to create directory structure (avoids RUN commands that trigger x86-64-v3 check)
COPY sql/init-tables.sql /opt/trino/sql/init-tables.sql

USER trino

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
