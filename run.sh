#!/bin/bash

set -e

echo "=========================================="
echo "Data Pipeline Docker Compose Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to script directory
cd "$(dirname "$0")"

# Step 1: Build custom Docker images
print_status "Building custom Docker images..."

print_status "Building Hive Metastore image..."
docker build -t hive-metastore:latest ./hive-metastore

print_status "Building Kafka Connect image..."
docker build -t kafka-connect-iceberg:latest ./kafka-connect

print_status "Building Logging Server image..."
docker build -t logging-server:latest ./logging-server

print_status "Building Client (HTTP client) image..."
docker build -t weather-client:latest ./client

print_status "Building Flink image..."
docker build -t flink-weather:latest ./flink

print_status "All images built successfully!"

# Step 2: Start Docker Compose
print_status "Starting Docker Compose services..."
docker compose up -d

# Step 3: Restart logging-server to ensure fresh container
print_status "Restarting logging-server container..."
docker compose stop logging-server 2>/dev/null || true
docker compose rm -f logging-server 2>/dev/null || true
docker compose up -d logging-server
sleep 5

# Step 5: Wait for services to be healthy
print_status "Waiting for services to become healthy..."

# Wait for Kafka Connect to be ready
print_status "Waiting for Kafka Connect to be ready..."
MAX_RETRIES=60
RETRY_COUNT=0
while ! curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        print_error "Kafka Connect failed to start within expected time"
        exit 1
    fi
    echo -n "."
    sleep 5
done
echo ""
print_status "Kafka Connect is ready!"

# Step 6: Remove existing connector and register the Iceberg sink connector
print_status "Removing existing iceberg-sink connector (if any)..."
curl -X DELETE http://localhost:8083/connectors/iceberg-sink 2>/dev/null || true
sleep 2

print_status "Registering Iceberg sink connector..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "iceberg-sink",
    "config": {
        "connector.class": "io.tabular.iceberg.connect.IcebergSinkConnector",
        "tasks.max": "1",
        "topics": "weather",
        "iceberg.tables": "default.weather",
        "iceberg.tables.auto-create-enabled": "true",
        "iceberg.tables.evolve-schema-enabled": "true",
        "iceberg.control.commit.interval-ms": "10000",
        "iceberg.catalog.type": "hive",
        "iceberg.catalog.uri": "thrift://hive-metastore:9083",
        "iceberg.catalog.warehouse": "s3a://warehouse/",
        "iceberg.catalog.io-impl": "org.apache.iceberg.aws.s3.S3FileIO",
        "iceberg.catalog.s3.endpoint": "http://minio:9000",
        "iceberg.catalog.s3.access-key-id": "admin",
        "iceberg.catalog.s3.secret-access-key": "password",
        "iceberg.catalog.s3.path-style-access": "true",
        "iceberg.catalog.client.region": "us-east-1",
        "iceberg.table.weather.partition_by": "hours(ts)",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter.schemas.enable": "false"
    }
}'

echo ""
print_status "Connector registered!"

# Step 7: Wait a moment and check connector status
sleep 5
print_status "Checking connector status..."
curl -s http://localhost:8083/connectors/iceberg-sink/status | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8083/connectors/iceberg-sink/status

echo ""
echo "=========================================="
print_status "Data Pipeline is now running!"
echo "=========================================="
echo ""
echo "Services:"
echo "  - Logging Server:      http://localhost:9998"
echo "  - MinIO Console:       http://localhost:9001 (admin/password)"
echo "  - Kafka Connect:       http://localhost:8083"
echo "  - Flink Dashboard:     http://localhost:8081"
echo "  - Trino:               http://localhost:8080"
echo "  - PostgreSQL Analytics: localhost:7777 (analytics/analytics)"
echo ""
echo "Test the logging server:"
echo "  curl 'http://localhost:9998/log?city=TestCity&temperature=75.5'"
echo ""
echo "To query the Iceberg table in Trino:"
echo "  docker exec -it trino trino"
echo "  trino> SELECT * FROM iceberg.default.weather;"
echo ""
echo "To view logs:"
echo "  docker compose logs -f client"
echo "  docker compose logs -f logging-server"
echo "  docker compose logs -f kafka-connect"
echo ""
echo "To stop the pipeline:"
echo "  docker compose down"
echo ""
