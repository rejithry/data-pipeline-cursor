FROM flink:1.18-java11

# Install Python, netcat, and curl for scripts and healthcheck
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    netcat-openbsd \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download required connectors (using correct versions for Flink 1.18)
RUN wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.1.0-1.18/flink-sql-connector-kafka-3.1.0-1.18.jar \
    && wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.2-1.18/flink-connector-jdbc-3.1.2-1.18.jar \
    && wget -P /opt/flink/lib/ https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.1/postgresql-42.7.1.jar

# Copy SQL scripts
COPY sql/ /opt/flink/sql/

# Copy entrypoint script
COPY docker-entrypoint.sh /opt/flink/
RUN chmod +x /opt/flink/docker-entrypoint.sh
