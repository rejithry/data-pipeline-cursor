#!/usr/bin/env python3
"""
Logging server that accepts weather data via HTTP GET and sends to Kafka.
"""

import json
import os
from datetime import datetime
from flask import Flask, request, jsonify
from confluent_kafka import Producer

app = Flask(__name__)

# Kafka configuration
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:29092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "weather")

# Create Kafka producer
producer = None


def get_producer():
    """Get or create Kafka producer instance."""
    global producer
    if producer is None:
        conf = {
            "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
            "client.id": "logging-server",
        }
        producer = Producer(conf)
    return producer


def delivery_callback(err, msg):
    """Callback for Kafka message delivery."""
    if err is not None:
        print(f"Message delivery failed: {err}")
    else:
        print(f"Message delivered to {msg.topic()} [{msg.partition()}] @ offset {msg.offset()}")


@app.route("/log", methods=["GET"])
def log_weather():
    """
    Log weather data endpoint.
    
    Query parameters:
        - city: City name (required)
        - temperature: Temperature value (required)
    
    Returns:
        JSON response with status
    """
    city = request.args.get("city")
    temperature = request.args.get("temperature")
    
    if not city or not temperature:
        return jsonify({
            "status": "error",
            "message": "Missing required parameters: city and temperature"
        }), 400
    
    # Create weather record with second-precision timestamp
    record = {
        "city": city,
        "temperature": str(temperature),
        "ts": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }
    
    message = json.dumps(record)
    print(f"Received: city={city}, temperature={temperature}, ts={record['ts']}")
    
    try:
        # Send to Kafka
        prod = get_producer()
        prod.produce(
            topic=KAFKA_TOPIC,
            value=message.encode("utf-8"),
            callback=delivery_callback,
        )
        prod.poll(0)
        
        return jsonify({
            "status": "success",
            "message": "Weather data logged",
            "data": record
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy"}), 200


if __name__ == "__main__":
    print(f"Starting logging server...")
    print(f"Kafka Bootstrap Servers: {KAFKA_BOOTSTRAP_SERVERS}")
    print(f"Kafka Topic: {KAFKA_TOPIC}")
    app.run(host="0.0.0.0", port=9998)
