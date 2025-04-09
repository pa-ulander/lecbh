#!/bin/bash

# Start the container
docker-compose up -d

# Give systemd time to start
sleep 5

# Run tests with different parameters
echo "=== Testing with --dry-run flag ==="
docker-compose exec -T lecbh-test /app/lecbh.sh --dry-run --unattended

echo "=== Testing with verbose output ==="
docker-compose exec -T lecbh-test /app/lecbh.sh --dry-run --verbose --unattended

# Clean up
docker-compose down