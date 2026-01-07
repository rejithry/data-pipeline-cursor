# Data Pipeline Project Plan

A Docker Compose-based data pipeline that generates fake weather data, streams it through Kafka, writes to Iceberg tables on MinIO, and enables querying via Trino.

## Architecture Diagram

```mermaid
flowchart TB
    subgraph producers [Data Generation Layer]
        Client[Client<br/>Python Producer]
    end
    
    subgraph kafka_layer [Message Broker Layer]
        Zookeeper[Zookeeper<br/>:2181]
        Kafka[Kafka<br/>:9092]
        KafkaConnect[Kafka Connect<br/>:8083]
    end
    
    subgraph storage [Storage Layer]
        MinIO[MinIO S3<br/>:9000/:9001]
        PostgreSQL[PostgreSQL<br/>:5432]
        HiveMetastore[Hive Metastore<br/>:9083]
    end
    
    subgraph query [Query Layer]
        Trino[Trino<br/>:8080]
    end
    
    Client -->|produces JSON to<br/>weather topic| Kafka
    Zookeeper -.->|coordinates| Kafka
    Kafka -->|consumes from<br/>weather topic| KafkaConnect
    KafkaConnect -->|writes Parquet<br/>files to warehouse bucket| MinIO
    KafkaConnect -->|registers table<br/>metadata| HiveMetastore
    PostgreSQL -.->|stores catalog<br/>metadata| HiveMetastore
    Trino -->|queries table<br/>metadata| HiveMetastore
    Trino -->|reads Parquet<br/>data files| MinIO
```

## Data Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant K as Kafka
    participant KC as Kafka Connect
    participant HMS as Hive Metastore
    participant M as MinIO
    participant T as Trino
    
    loop Every 5 seconds
        C->>C: Generate 10 weather records
        C->>K: Produce to 'weather' topic
    end
    
    KC->>K: Consume from 'weather' topic
    KC->>HMS: Create/update Iceberg table metadata
    KC->>M: Write Parquet files to s3a://warehouse/
    
    T->>HMS: Query table schema & partitions
    HMS-->>T: Return metadata
    T->>M: Read Parquet files
    M-->>T: Return data
    T-->>T: Execute SQL query
```

## Container Details

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| minio | minio/minio | 9000, 9001 | S3-compatible object storage for Iceberg data files |
| minio-init | minio/mc | - | Initializes the 'warehouse' bucket |
| postgres | postgres:15 | 5432 | Backend database for Hive Metastore |
| hive-metastore | Custom | 9083 | Iceberg table catalog (Thrift service) |
| zookeeper | confluentinc/cp-zookeeper:7.5.0 | 2181 | Kafka cluster coordination |
| kafka | confluentinc/cp-kafka:7.5.0 | 9092 | Message broker |
| kafka-connect | Custom | 8083 | Runs Iceberg sink connector |
| client | Custom | - | Python producer generating weather data |
| trino | trinodb/trino | 8080 | SQL query engine for Iceberg tables |

## Directory Structure

```
├── compose.yaml                 # Docker Compose configuration
├── run.sh                       # Build and startup script
├── PLAN.md                      # This file
├── client/
│   ├── Dockerfile               # Python 3.11 slim image
│   ├── producer.py              # Weather data generator
│   └── requirements.txt         # confluent-kafka, faker
├── hive-metastore/
│   ├── Dockerfile               # Eclipse Temurin JRE 11 + Hive 3.1.3
│   └── metastore-site.xml       # Metastore configuration
├── kafka-connect/
│   ├── Dockerfile               # Confluent Kafka Connect + Iceberg connector
│   └── register-connector.sh    # Connector registration script
└── trino/
    └── etc/
        ├── config.properties    # Trino server config
        ├── node.properties      # Trino node config
        ├── jvm.config           # JVM settings
        └── catalog/
            └── iceberg.properties  # Iceberg catalog config
```

## Data Schema

The weather data has the following JSON structure:

```json
{
  "city": "North Sharonstad",
  "temperature": "80.59",
  "ts": "21"
}
```

| Field | Type | Description |
|-------|------|-------------|
| city | string | Randomly generated fake city name |
| temperature | string | Random temperature (0-120°F) |
| ts | string | Current hour (0-23), used for partitioning |

## Iceberg Table

- **Database**: default
- **Table**: weather
- **Partition**: ts (hour of day)
- **Location**: s3a://warehouse/default/weather
- **File Format**: Parquet

## Configuration

### Credentials

| Service | Username | Password |
|---------|----------|----------|
| MinIO | admin | password |
| PostgreSQL | hive | hive |

### Network

All containers are connected via the `data-pipeline` bridge network.

## Usage

### Start the Pipeline

```bash
./run.sh
```

This will:
1. Build custom Docker images
2. Start all services
3. Wait for Kafka Connect to be ready
4. Register the Iceberg sink connector

### Query Data with Trino

```bash
docker exec -it trino trino
```

```sql
-- Show catalogs
SHOW CATALOGS;

-- Show tables
SHOW TABLES FROM iceberg.default;

-- Query weather data
SELECT * FROM iceberg.default.weather;

-- Query by partition
SELECT * FROM iceberg.default.weather WHERE ts = '14';

-- Aggregate queries
SELECT city, AVG(CAST(temperature AS DOUBLE)) as avg_temp 
FROM iceberg.default.weather 
GROUP BY city;
```

### View Logs

```bash
# Client logs (producer)
docker compose logs -f client

# Kafka Connect logs
docker compose logs -f kafka-connect

# All logs
docker compose logs -f
```

### Access Services

- **MinIO Console**: http://localhost:9001 (admin/password)
- **Kafka Connect REST API**: http://localhost:8083
- **Trino Web UI**: http://localhost:8080

### Stop the Pipeline

```bash
docker compose down
```

### Clean Up Everything

```bash
docker compose down -v  # Removes volumes too
```

## Troubleshooting

### Check Connector Status

```bash
curl http://localhost:8083/connectors/iceberg-sink/status | jq
```

### Restart a Failed Connector Task

```bash
curl -X POST http://localhost:8083/connectors/iceberg-sink/tasks/0/restart
```

### Check Kafka Topics

```bash
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Check MinIO Bucket Contents

```bash
docker exec -it minio mc ls myminio/warehouse --recursive
```
