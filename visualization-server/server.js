const express = require('express');
const { Pool } = require('pg');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'postgres-analytics',
  port: process.env.POSTGRES_PORT || 5432,
  database: process.env.POSTGRES_DB || 'analytics',
  user: process.env.POSTGRES_USER || 'analytics',
  password: process.env.POSTGRES_PASSWORD || 'analytics',
});

// Static list of cities (matching producer.py)
const CITIES = [
  'San Francisco',
  'New York',
  'Los Angeles',
  'Chicago',
  'Houston',
  'Phoenix',
  'Seattle',
  'Denver',
  'Miami',
  'Boston'
];

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// API endpoint to get weather data for all cities
app.get('/api/weather', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT city, avg_temperature, last_updated
      FROM weather
      WHERE city = ANY($1)
      ORDER BY city, last_updated ASC
    `, [CITIES]);
    
    // Group data by city
    const dataByCity = {};
    CITIES.forEach(city => {
      dataByCity[city] = [];
    });
    
    result.rows.forEach(row => {
      if (dataByCity[row.city]) {
        dataByCity[row.city].push({
          time: row.last_updated,
          temperature: parseFloat(row.avg_temperature)
        });
      }
    });
    
    res.json({
      cities: CITIES,
      data: dataByCity
    });
  } catch (error) {
    console.error('Error fetching weather data:', error);
    res.status(500).json({ error: 'Failed to fetch weather data' });
  }
});

// API endpoint to get latest data for real-time updates
app.get('/api/weather/latest', async (req, res) => {
  try {
    const since = req.query.since || new Date(0).toISOString();
    
    const result = await pool.query(`
      SELECT city, avg_temperature, last_updated
      FROM weather
      WHERE city = ANY($1) AND last_updated > $2
      ORDER BY city, last_updated ASC
    `, [CITIES, since]);
    
    // Group data by city
    const dataByCity = {};
    CITIES.forEach(city => {
      dataByCity[city] = [];
    });
    
    result.rows.forEach(row => {
      if (dataByCity[row.city]) {
        dataByCity[row.city].push({
          time: row.last_updated,
          temperature: parseFloat(row.avg_temperature)
        });
      }
    });
    
    res.json({
      cities: CITIES,
      data: dataByCity
    });
  } catch (error) {
    console.error('Error fetching latest weather data:', error);
    res.status(500).json({ error: 'Failed to fetch weather data' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Weather visualization server running on port ${PORT}`);
  console.log(`Tracking cities: ${CITIES.join(', ')}`);
});
