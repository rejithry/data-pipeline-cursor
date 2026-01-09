-- Create Kafka source table
CREATE TABLE weather_source (
    city STRING,
    temperature STRING,
    ts STRING,
    event_time AS TO_TIMESTAMP(ts, 'yyyy-MM-dd HH:mm:ss'),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'weather',
    'properties.bootstrap.servers' = 'kafka:29092',
    'properties.group.id' = 'flink-weather-consumer',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true'
);

-- Create PostgreSQL sink table
CREATE TABLE weather_avg_sink (
    city STRING,
    avg_temperature DOUBLE,
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    record_count BIGINT,
    last_updated TIMESTAMP(3),
    PRIMARY KEY (city, window_start) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres-analytics:5432/analytics',
    'table-name' = 'weather',
    'username' = 'analytics',
    'password' = 'analytics',
    'driver' = 'org.postgresql.Driver'
);

-- Insert aggregated data: average temperature per city every 5 seconds
INSERT INTO weather_avg_sink
SELECT 
    city,
    AVG(CAST(temperature AS DOUBLE)) as avg_temperature,
    TUMBLE_START(event_time, INTERVAL '5' SECOND) as window_start,
    TUMBLE_END(event_time, INTERVAL '5' SECOND) as window_end,
    COUNT(*) as record_count,
    CURRENT_TIMESTAMP as last_updated
FROM weather_source
GROUP BY 
    city,
    TUMBLE(event_time, INTERVAL '5' SECOND);
