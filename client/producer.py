#!/usr/bin/env python3
"""
Weather data producer that generates fake weather records
and sends them to a Kafka topic. Sends 10 messages every 5 seconds.
"""

import json
import os
import random
import time
from datetime import datetime

from confluent_kafka import Producer
from faker import Faker

# Initialize Faker for generating fake city names
fake = Faker()

# Kafka configuration from environment variables
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:29092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "weather")
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "10"))  # Number of messages per batch
PRODUCE_INTERVAL = int(os.getenv("PRODUCE_INTERVAL", "5"))  # Seconds between batches


def create_producer():
    """Create and return a Kafka producer instance."""
    conf = {
        "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
        "client.id": "weather-producer",
    }
    return Producer(conf)


def delivery_callback(err, msg):
    """Callback function for message delivery reports."""
    if err is not None:
        print(f"Message delivery failed: {err}")
    else:
        print(f"Message delivered to {msg.topic()} [{msg.partition()}] @ offset {msg.offset()}")


def generate_weather_record():
    """Generate a fake weather record with random city and temperature."""
    return {
        "city": fake.city(),
        "temperature": str(round(random.uniform(0, 120), 2)),  # Temperature in Fahrenheit
        "ts": str(datetime.now().hour),  # Current hour (0-23)
    }


def send_batch(producer, batch_size):
    """Send a batch of weather records to Kafka."""
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Sending {batch_size} messages...")
    
    for i in range(batch_size):
        # Generate a unique weather record for each message
        record = generate_weather_record()
        message = json.dumps(record)

        print(f"  [{i+1}/{batch_size}] {message}")

        # Send message to Kafka
        producer.produce(
            topic=KAFKA_TOPIC,
            value=message.encode("utf-8"),
            callback=delivery_callback,
        )

        # Trigger delivery reports
        producer.poll(0)
    
    # Flush to ensure all messages are sent
    producer.flush()
    print(f"Batch complete.")


def main():
    """Main function to run the weather data producer."""
    print(f"Starting weather producer...")
    print(f"Kafka Bootstrap Servers: {KAFKA_BOOTSTRAP_SERVERS}")
    print(f"Kafka Topic: {KAFKA_TOPIC}")
    print(f"Batch Size: {BATCH_SIZE} messages")
    print(f"Interval: {PRODUCE_INTERVAL} seconds")

    producer = create_producer()

    try:
        while True:
            # Send a batch of messages
            send_batch(producer, BATCH_SIZE)

            # Wait for the specified interval
            time.sleep(PRODUCE_INTERVAL)

    except KeyboardInterrupt:
        print("\nShutting down producer...")
    finally:
        # Wait for any outstanding messages to be delivered
        producer.flush()
        print("Producer shut down complete.")


if __name__ == "__main__":
    main()
