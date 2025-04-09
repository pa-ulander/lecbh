# Testing lecbh with Docker

This document explains how to set up a testing environment for the `lecbh` script using Docker, which allows you to safely test the script without affecting your production systems.

## Prerequisites

- Docker installed on your system
- Docker Compose installed on your system
- Basic knowledge of Docker and bash scripting

## Testing Environment Setup

### Building the Docker container

The project includes a Dockerfile and docker-compose.yml file for testing. To build the testing environment:

```bash
# Build the Docker container
docker-compose build
```

This will create a container with Ubuntu, Apache, and all necessary dependencies for testing the lecbh script.

Make the test script executable:

```bash
chmod +x test.sh
```

## Running the Tests

To run all tests, simply execute the test script:

```bash
./test.sh
```

This will:
1. Start a Docker container with Ubuntu, Apache, and Nginx
2. Run a series of tests with different configurations
3. Report the results
4. Clean up the container

## Manual Testing

You can also manually test the script in the Docker container:

### 1. Start the container

```bash
docker-compose up -d
```

### 2. Access the container shell

```bash
docker-compose exec lecbh-test bash
```

### 3. Run the script with different options

```bash
cd /app
./lecbh.sh --help
./lecbh.sh --dry-run
./lecbh.sh --dry-run --verbose
./lecbh.sh --staging --unattended
```

### 4. Clean up when done

```bash
exit  # Exit the container shell
docker-compose down
```

## Testing with Different Ubuntu Versions

To test with different Ubuntu versions, modify the first line of the Dockerfile:

```dockerfile
# For Ubuntu 20.04
FROM ubuntu:20.04

# For Ubuntu 22.04
FROM ubuntu:22.04

# For Ubuntu 23.04
FROM ubuntu:23.04
```

Then rebuild the container:

```bash
docker-compose build
```

## Testing with GitHub Actions

## Troubleshooting

### Common Issues

1. **Systemd not starting in container**:
   - Ensure you're using the `privileged: true` flag in docker-compose.yml
   - Make sure the `/sys/fs/cgroup` volume is mounted correctly

2. **Port conflicts**:
   - If ports 80 or 443 are already in use on your host, modify the port mappings in docker-compose.yml

3. **Snap not working in container**:
   - Snap has limitations in containers. The Dockerfile is set up to handle this, but you may need to adjust it for your specific environment.

4. **DNS resolution issues**:
   - The container may have different DNS settings than your host. You can add custom DNS servers in docker-compose.yml if needed.

### Debugging

For more detailed debugging, add the `--verbose` flag to your lecbh.sh commands and inspect the logs:

```bash
docker-compose logs
```

## Advanced Testing Scenarios

### Testing with Real Domains

To test with real domains, you'll need to:

1. Ensure your domain's DNS points to the IP where you're running Docker
2. Forward ports 80 and 443 to your Docker host
3. Run the script without the `--dry-run` flag (be cautious with rate limits)

### Testing Certificate Renewal

To test certificate renewal without waiting for the actual renewal period:

```bash
docker-compose exec lecbh-test certbot renew --dry-run
```

### Testing with Custom Configurations

You can create different test configurations by modifying the environment variables:

```bash
docker-compose exec -e DEFAULT_EMAIL=custom@example.com -e DEFAULT_DOMAINS=custom.example.com lecbh-test /app/lecbh.sh --dry-run --unattended
```
