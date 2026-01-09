#!/bin/bash

# Wait for Kafka Connect to be ready
echo "Waiting for Kafka Connect to be ready..."
while ! curl -s http://kafka-connect:8083/connectors > /dev/null 2>&1; do
    echo "Kafka Connect not ready yet, waiting..."
    sleep 5
done
echo "Kafka Connect is ready!"

# Delete existing connector if present
echo "Removing existing iceberg-sink connector (if any)..."
curl -X DELETE http://kafka-connect:8083/connectors/iceberg-sink 2>/dev/null || true
sleep 2

# Register the Iceberg sink connector
echo "Registering Iceberg sink connector..."

curl -X POST http://kafka-connect:8083/connectors \
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
echo "Connector registration complete!"

# Check connector status
sleep 5
echo "Checking connector status..."
curl -s http://kafka-connect:8083/connectors/iceberg-sink/status | python3 -m json.tool 2>/dev/null || curl -s http://kafka-connect:8083/connectors/iceberg-sink/status
