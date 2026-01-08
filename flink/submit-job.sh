#!/bin/bash

# Wait for Flink JobManager to be ready
echo "Waiting for Flink JobManager..."
while ! curl -s http://localhost:8081/overview > /dev/null 2>&1; do
    sleep 5
done
echo "Flink JobManager is ready!"

# Submit the SQL job using Flink SQL Client
echo "Submitting weather aggregation job..."

/opt/flink/bin/sql-client.sh -f /opt/flink/sql/weather-aggregation.sql

echo "Job submitted!"
