-- Create weather table for storing aggregated weather data
CREATE TABLE IF NOT EXISTS weather (
    city VARCHAR(255) NOT NULL,
    avg_temperature DOUBLE PRECISION,
    window_start TIMESTAMP,
    window_end TIMESTAMP,
    record_count BIGINT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (city, window_start)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_weather_city ON weather(city);
CREATE INDEX IF NOT EXISTS idx_weather_window ON weather(window_start, window_end);
