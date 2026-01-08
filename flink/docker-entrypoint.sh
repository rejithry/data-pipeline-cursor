#!/bin/bash

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
while ! nc -z kafka 29092; do
    sleep 2
done
echo "Kafka is ready!"

# Wait for PostgreSQL analytics to be ready
echo "Waiting for PostgreSQL analytics to be ready..."
while ! nc -z postgres-analytics 5432; do
    sleep 2
done
echo "PostgreSQL analytics is ready!"

# Give services a bit more time to fully initialize
sleep 10

# Start Flink cluster
echo "Starting Flink cluster..."
/docker-entrypoint.sh "$@"
