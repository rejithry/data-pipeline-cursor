#!/bin/bash

# Start Trino in the background
echo "Starting Trino..."
/usr/lib/trino/bin/run-trino &

# Wait for Trino to be ready
echo "Waiting for Trino to be ready..."
TRINO_PID=$!
for i in {1..60}; do
    if curl -s http://localhost:8080/v1/info > /dev/null 2>&1; then
        echo "Trino is ready!"
        break
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
    # Use Trino CLI to execute SQL file
    if command -v trino > /dev/null 2>&1; then
        trino --server http://localhost:8080 --catalog iceberg --schema default -f /opt/trino/sql/init-tables.sql
        if [ $? -eq 0 ]; then
            echo "SQL initialization completed successfully"
        else
            echo "SQL initialization failed"
        fi
    else
        echo "Trino CLI not found, skipping SQL initialization"
    fi
fi

# Keep container running
wait $TRINO_PID
