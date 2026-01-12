#!/bin/bash

# Start Trino in the background
echo "Starting Trino..."
/usr/lib/trino/bin/run-trino &

# Wait for Trino to be ready
echo "Waiting for Trino to be ready..."
TRINO_PID=$!
# Try multiple methods to check if Trino is ready (curl, wget, or Java)
for i in {1..60}; do
    # Try curl first, then wget, then Java-based check
    if command -v curl >/dev/null 2>&1; then
        if curl -s http://localhost:8080/v1/info > /dev/null 2>&1; then
            echo "Trino is ready!"
            break
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q -O /dev/null http://localhost:8080/v1/info 2>/dev/null; then
            echo "Trino is ready!"
            break
        fi
    elif command -v java >/dev/null 2>&1; then
        # Use Java to check if port is open (basic check)
        if java -cp /opt/trino/trino-cli.jar io.trino.cli.Trino --server http://localhost:8080 --execute "SELECT 1" 2>/dev/null | grep -q "1"; then
            echo "Trino is ready!"
            break
        fi
    else
        # Fallback: just wait and hope Trino starts
        if [ $i -gt 10 ]; then
            echo "Trino should be ready (no health check tool available)"
            break
        fi
    fi
    if [ $i -eq 60 ]; then
        echo "Trino failed to start within 60 seconds"
        exit 1
    fi
    sleep 2
done

# Give Trino a bit more time to fully initialize
sleep 5

# Execute SQL initialization file if it exists
if [ -f /opt/trino/sql/init-tables.sql ]; then
    echo "Executing SQL initialization..."
    # Use Java to execute SQL via Trino CLI JAR
    if command -v java > /dev/null 2>&1 && [ -f /opt/trino/trino-cli.jar ]; then
        java -jar /opt/trino/trino-cli.jar --server http://localhost:8080 --catalog iceberg --schema default -f /opt/trino/sql/init-tables.sql
        if [ $? -eq 0 ]; then
            echo "SQL initialization completed successfully"
        else
            echo "SQL initialization failed (exit code: $?)"
        fi
    else
        echo "Java or Trino CLI JAR not found, skipping SQL initialization"
        echo "Java available: $(command -v java || echo 'no')"
        echo "CLI JAR exists: $([ -f /opt/trino/trino-cli.jar ] && echo 'yes' || echo 'no')"
    fi
fi

# Keep container running
wait $TRINO_PID
