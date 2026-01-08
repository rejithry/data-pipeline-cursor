# Data Pipeline Project Plan

A Docker Compose-based data pipeline that generates fake weather data, sends it through a logging server to Kafka, writes to Iceberg tables on MinIO via Kafka Connect, performs real-time aggregation with Flink, and enables querying via Trino.

## Architecture Diagram

```mermaid
flowchart TB
    subgraph producers [Data Generation Layer]
        Client[Client<br/>Python HTTP Client]
        LoggingServer[Logging Server<br/>Flask :9998]
    end
    
    subgraph kafka_layer [Message Broker Layer]
        Zookeeper[Zookeeper<br/>:2181]
        Kafka[Kafka<br/>:9092]
        KafkaConnect[Kafka Connect<br/>:8083]
    end
    
    subgraph realtime [Real-time Processing Layer]
        FlinkJM[Flink JobManager<br/>:8081]
        FlinkTM[Flink TaskManager]
        FlinkSQL[Flink SQL Client]
    end
    
    subgraph storage [Storage Layer]
        MinIO[MinIO S3<br/>:9000/:9001]
        PostgreSQL[PostgreSQL Metastore<br/>:5432]
        PostgresAnalytics[PostgreSQL Analytics<br/>:7777]
        HiveMetastore[Hive Metastore<br/>:9083]
    end
    
    subgraph query [Query Layer]
        Trino[Trino<br/>:8080]
    end
    
    subgraph visualization [Visualization Layer]
        VizServer[Visualization Server<br/>Node.js :3000]
    end
    
    Client -->|HTTP GET /log| LoggingServer
    LoggingServer -->|produces JSON to<br/>weather topic| Kafka
    Zookeeper -.->|coordinates| Kafka
    Kafka -->|consumes from<br/>weather topic| KafkaConnect
    Kafka -->|consumes from<br/>weather topic| FlinkTM
    FlinkJM -.->|manages| FlinkTM
    FlinkSQL -.->|submits jobs| FlinkJM
    FlinkTM -->|writes avg temp<br/>per minute per city| PostgresAnalytics
    KafkaConnect -->|writes Parquet<br/>files to warehouse bucket| MinIO
    KafkaConnect -->|registers table<br/>metadata| HiveMetastore
    PostgreSQL -.->|stores catalog<br/>metadata| HiveMetastore
    Trino -->|queries table<br/>metadata| HiveMetastore
    Trino -->|reads Parquet<br/>data files| MinIO
    VizServer -->|queries aggregated<br/>weather data| PostgresAnalytics
```

## Data Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant LS as Logging Server
    participant K as Kafka
    participant KC as Kafka Connect
    participant F as Flink
    participant PA as PostgreSQL Analytics
    participant V as Visualization Server
    participant HMS as Hive Metastore
    participant M as MinIO
    participant T as Trino
    
    loop Every 5 seconds
        C->>C: Generate 10 weather records
        loop For each record
            C->>LS: GET /log?city=X&temperature=Y
            LS->>K: Produce to 'weather' topic
            LS-->>C: 200 OK
        end
    end
    
    par Batch Processing
        KC->>K: Consume from 'weather' topic
        KC->>HMS: Create/update Iceberg table metadata
        KC->>M: Write Parquet files to s3a://warehouse/
    and Real-time Processing
        F->>K: Consume from 'weather' topic
        F->>F: Aggregate avg temp per city per minute
        F->>PA: Write to weather table
    and Visualization
        V->>PA: Poll for new data (every 2s)
        PA-->>V: Return aggregated data
        V->>V: Update Google Charts
    end
    
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
| postgres-analytics | postgres:15 | 7777 | Stores real-time aggregated weather data from Flink |
| hive-metastore | Custom | 9083 | Iceberg table catalog (Thrift service) |
| zookeeper | confluentinc/cp-zookeeper:7.5.0 | 2181 | Kafka cluster coordination |
| kafka | confluentinc/cp-kafka:7.5.0 | 9092 | Message broker |
| kafka-connect | Custom | 8083 | Runs Iceberg sink connector |
| flink-jobmanager | Custom (Flink 1.18) | 8081 | Flink cluster manager |
| flink-taskmanager | Custom (Flink 1.18) | - | Flink task executor |
| flink-sql-client | Custom (Flink 1.18) | - | Submits Flink SQL jobs |
| logging-server | Custom | 9998 | Flask web server that receives weather data and sends to Kafka |
| client | Custom | - | Python HTTP client generating weather data |
| visualization-server | Custom (Node.js) | 3000 | Real-time dashboard with Google Charts |
| trino | trinodb/trino | 8080 | SQL query engine for Iceberg tables |

## Directory Structure

```
├── compose.yaml                 # Docker Compose configuration
├── run.sh                       # Build and startup script
├── PLAN.md                      # This file
├── client/
│   ├── Dockerfile               # Python 3.11 slim image
│   ├── producer.py              # HTTP client sending to logging server
│   └── requirements.txt         # requests, faker
├── logging-server/
│   ├── Dockerfile               # Python 3.11 slim + Flask
│   ├── server.py                # Flask server with /log endpoint
│   └── requirements.txt         # flask, confluent-kafka
├── visualization-server/
│   ├── Dockerfile               # Node.js 20 slim
│   ├── package.json             # express, pg dependencies
│   ├── server.js                # Express server with PostgreSQL connection
│   └── public/
│       └── index.html           # Dashboard with Google Charts
├── flink/
│   ├── Dockerfile               # Flink 1.18 with Kafka/JDBC connectors
│   ├── docker-entrypoint.sh     # Custom entrypoint script
│   ├── submit-job.sh            # Job submission script
│   ├── init-analytics-db.sql    # PostgreSQL analytics table schema
│   └── sql/
│       └── weather-aggregation.sql  # Flink SQL job definition
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

## Flink Real-time Processing

### Flink SQL Job

The Flink job performs the following:
1. Consumes JSON messages from Kafka `weather` topic
2. Parses the weather data (city, temperature, ts)
3. Aggregates average temperature per city per minute using tumbling windows
4. Writes results to PostgreSQL `analytics.weather` table

### PostgreSQL Analytics Schema

```sql
CREATE TABLE weather (
    city VARCHAR(255) NOT NULL,
    avg_temperature DOUBLE PRECISION,
    window_start TIMESTAMP,
    window_end TIMESTAMP,
    record_count BIGINT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (city, window_start)
);
```

### Query Analytics Data

```bash
# Connect to analytics PostgreSQL
docker exec -it postgres-analytics psql -U analytics -d analytics

# Query aggregated data
SELECT * FROM weather ORDER BY window_start DESC LIMIT 10;

# Average temperature by city
SELECT city, AVG(avg_temperature) as overall_avg 
FROM weather 
GROUP BY city 
ORDER BY overall_avg DESC;
```

## Logging Server API

### GET /log

Accepts weather data and sends it to Kafka.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| city | string | Yes | City name |
| temperature | string | Yes | Temperature value |

**Response:**
```json
{
  "status": "success",
  "message": "Weather data logged",
  "data": {
    "city": "New York",
    "temperature": "72.5",
    "ts": "2026-01-08-14"
  }
}
```

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "healthy"
}
```

## Visualization Server

The visualization server provides a real-time dashboard for monitoring weather data aggregations.

### Features

- **Real-time updates**: Polls PostgreSQL every 2 seconds for new data
- **10 line charts**: One chart per city tracking temperature over time
- **Stats bar**: Shows total cities, data points, average temperature, and last update time
- **Modern dark theme**: Gradient backgrounds, animations, and responsive design

### Cities Tracked

The dashboard displays data for the following 10 cities (matching the client):
- San Francisco, New York, Los Angeles, Chicago, Houston
- Phoenix, Seattle, Denver, Miami, Boston

### API Endpoints

#### GET /api/weather
Returns all historical weather data grouped by city.

**Response:**
```json
{
  "cities": ["San Francisco", "New York", ...],
  "data": {
    "San Francisco": [
      {"time": "2026-01-08T14:30:00.000Z", "temperature": 72.5},
      ...
    ],
    ...
  }
}
```

#### GET /api/weather/latest?since=<timestamp>
Returns weather data since the specified timestamp (for incremental updates).

#### GET /health
Health check endpoint.

### Access the Dashboard

Open http://localhost:3000 in your browser to view the real-time weather analytics dashboard.

## Data Schema

The weather data has the following JSON structure:

```json
{
  "city": "North Sharonstad",
  "temperature": "80.59",
  "ts": "2026-01-08-14"
}
```

| Field | Type | Description |
|-------|------|-------------|
| city | string | Randomly generated fake city name |
| temperature | string | Random temperature (0-120°F) |
| ts | string | Timestamp in YYYY-MM-DD-HH format, used for partitioning |

## Iceberg Table

- **Database**: default
- **Table**: weather
- **Partition**: ts (timestamp)
- **Location**: s3a://warehouse/default/weather
- **File Format**: Parquet

## Configuration

### Credentials

| Service | Username | Password | Port |
|---------|----------|----------|------|
| MinIO | admin | password | 9000/9001 |
| PostgreSQL (Metastore) | hive | hive | 5432 |
| PostgreSQL (Analytics) | analytics | analytics | 7777 |

### Network

All containers are connected via the `datapipeline` bridge network.

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

### Test the Logging Server

```bash
# Send a test weather record
curl "http://localhost:9998/log?city=TestCity&temperature=75.5"

# Check health
curl http://localhost:9998/health
```

### Query Batch Data with Trino

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
SELECT * FROM iceberg.default.weather WHERE ts = '2026-01-08-14';

-- Aggregate queries
SELECT city, AVG(CAST(temperature AS DOUBLE)) as avg_temp 
FROM iceberg.default.weather 
GROUP BY city;
```

### Query Real-time Aggregated Data

```bash
# Connect to PostgreSQL analytics
docker exec -it postgres-analytics psql -U analytics -d analytics

# View latest aggregations
SELECT * FROM weather ORDER BY window_start DESC LIMIT 10;

# View average temperature by city
SELECT city, AVG(avg_temperature) as overall_avg, SUM(record_count) as total_records
FROM weather 
GROUP BY city 
ORDER BY overall_avg DESC;
```

### View Flink Dashboard

Open http://localhost:8081 to view the Flink web UI and monitor running jobs.

### View Logs

```bash
# Client logs
docker compose logs -f client

# Logging server logs
docker compose logs -f logging-server

# Visualization server logs
docker compose logs -f visualization-server

# Kafka Connect logs
docker compose logs -f kafka-connect

# Flink logs
docker compose logs -f flink-jobmanager
docker compose logs -f flink-taskmanager
docker compose logs -f flink-sql-client

# All logs
docker compose logs -f
```

### Access Services

- **Weather Dashboard**: http://localhost:3000 (real-time visualization)
- **Logging Server**: http://localhost:9998
- **MinIO Console**: http://localhost:9001 (admin/password)
- **Kafka Connect REST API**: http://localhost:8083
- **Flink Dashboard**: http://localhost:8081
- **Trino Web UI**: http://localhost:8080
- **PostgreSQL Analytics**: localhost:7777 (analytics/analytics)

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

### Check Flink Jobs

```bash
curl http://localhost:8081/jobs/overview | jq
```

### Check Kafka Topics

```bash
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Check MinIO Bucket Contents

```bash
docker exec -it minio mc ls myminio/warehouse --recursive
```

### Restart Flink SQL Job

```bash
docker compose restart flink-sql-client
```
