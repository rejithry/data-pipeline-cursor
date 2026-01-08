#!/usr/bin/env python3
"""
Weather data client that generates fake weather records
and sends them to the logging server via HTTP GET requests.
Sends 10 messages every 5 seconds using a static list of cities.
"""

import os
import random
import time
from datetime import datetime
import requests

# Static list of 10 cities (generated once, used consistently)
CITIES = [
    "San Francisco",
    "New York",
    "Los Angeles",
    "Chicago",
    "Houston",
    "Phoenix",
    "Seattle",
    "Denver",
    "Miami",
    "Boston"
]

# Logging server configuration
LOGGING_SERVER_URL = os.getenv("LOGGING_SERVER_URL", "http://logging-server:9998")
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "10"))
PRODUCE_INTERVAL = int(os.getenv("PRODUCE_INTERVAL", "5"))


def generate_weather_data(city):
    """Generate weather data with the given city and random temperature."""
    return {
        "city": city,
        "temperature": str(round(random.uniform(0, 120), 2)),
    }


def send_to_logging_server(city, temperature):
    """Send weather data to the logging server via HTTP GET."""
    try:
        url = f"{LOGGING_SERVER_URL}/log"
        params = {"city": city, "temperature": temperature}
        response = requests.get(url, params=params, timeout=10)
        
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, response.json()
    except requests.exceptions.RequestException as e:
        return False, {"error": str(e)}


def send_batch():
    """Send a batch of weather records for all cities to the logging server."""
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Sending {len(CITIES)} messages...")
    
    success_count = 0
    for i, city in enumerate(CITIES):
        # Generate weather data for this city
        data = generate_weather_data(city)
        temperature = data["temperature"]

        print(f"  [{i+1}/{len(CITIES)}] city={city}, temperature={temperature}")

        # Send to logging server
        success, response = send_to_logging_server(city, temperature)
        
        if success:
            success_count += 1
            print(f"    -> Logged successfully")
        else:
            print(f"    -> Failed: {response}")
    
    print(f"Batch complete. {success_count}/{len(CITIES)} messages sent successfully.")


def wait_for_logging_server():
    """Wait for the logging server to be ready."""
    print(f"Waiting for logging server at {LOGGING_SERVER_URL}...")
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            response = requests.get(f"{LOGGING_SERVER_URL}/health", timeout=5)
            if response.status_code == 200:
                print("Logging server is ready!")
                return True
        except requests.exceptions.RequestException:
            pass
        
        retry_count += 1
        print(f"  Waiting... ({retry_count}/{max_retries})")
        time.sleep(2)
    
    print("Logging server not available after max retries")
    return False


def main():
    """Main function to run the weather data client."""
    print(f"Starting weather client...")
    print(f"Logging Server URL: {LOGGING_SERVER_URL}")
    print(f"Cities: {CITIES}")
    print(f"Interval: {PRODUCE_INTERVAL} seconds")

    # Wait for logging server to be ready
    if not wait_for_logging_server():
        print("Exiting due to logging server unavailability")
        return

    try:
        while True:
            # Send a batch of messages for all cities
            send_batch()

            # Wait for the specified interval
            time.sleep(PRODUCE_INTERVAL)

    except KeyboardInterrupt:
        print("\nShutting down client...")
    
    print("Client shut down complete.")


if __name__ == "__main__":
    main()
