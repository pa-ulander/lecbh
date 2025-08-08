# Testing Let's Encrypt Certbot Helper (lecbh) with Docker

This document explains how to set up a testing environment for the `lecbh` script using Docker, which allows you to safely test the script without affecting your production systems.

## Prerequisites

*   Docker installed on your system
*   Docker Compose installed on your system
*   Basic knowledge of Docker and bash scripting

## Testing Environment Setup

### Building the Docker container

The project includes a Dockerfile and docker-compose.yml file for testing. To build the testing environment:

```
# Build the Docker container
docker-compose build
```

This will create a container with Ubuntu 22.04, Apache, Nginx, and all necessary dependencies for testing the lecbh script.

Make the test script executable:

```
chmod +x test.sh
```

## Running the Tests

To run all tests, simply execute the test script:

```
./test.sh
```

This will:

1.  Start a Docker container with Ubuntu, Apache, and Nginx
2.  Run a series of tests with different configurations
3.  Report the results
4.  Clean up the container

The test script includes tests for:

*   Basic help command
*   Dry run with Apache and Nginx
*   Verbose output
*   Staging environment
*   Multiple domains
*   Both pip and snap installation methods

## Manual Testing

You can also manually test the script in the Docker container:

### 1\. Start the container

```
docker-compose up -d
```

### 2\. Access the container shell

```
docker-compose exec lecbh-test bash
```

### 3\. Run the script with different options

```
./lecbh.sh --help
./lecbh.sh --dry-run
./lecbh.sh --dry-run --verbose
./lecbh.sh --staging --unattended
./lecbh.sh --test-mode --pip
```

### 4\. Clean up when done

```
exit  # Exit the container shell
docker-compose down
```

## Testing with Different Ubuntu Versions

To test with different Ubuntu versions, modify the first line of the Dockerfile:

```
# For Ubuntu 20.04
FROM ubuntu:20.04

# For Ubuntu 22.04 (current default)
FROM ubuntu:22.04
```

Then rebuild the container:

```
docker-compose build
```

## Testing with GitHub Actions

The project includes a GitHub Actions workflow configuration in `.github/workflows/test.yml` that automatically tests the script when changes are pushed to the repository.

The workflow:

1.  Sets up an Ubuntu environment with Apache and Nginx
2.  Uses caching to speed up subsequent test runs
3.  Creates a test domain in the hosts file
4.  Modifies the script for testing with a special exit path for dry-run mode
5.  Tests with both Apache and Nginx servers

To see the test results, visit the Actions tab in the GitHub repository.

### Local testing of GitHub Actions

You can test similar configurations locally using:

```
# For Apache testing
sudo ./lecbh.sh --dry-run --unattended --verbose

# For Nginx testing
sudo ./lecbh.sh --dry-run --unattended --verbose --server=nginx
```

## Troubleshooting

### Common Issues

**Systemd not starting in container**:

*   Ensure you're using the `privileged: true` flag in docker-compose.yml or the `SYS_ADMIN` capability
*   The current configuration uses `service` commands instead of systemd for compatibility

**Port conflicts**:

*   If ports 80 or 443 are already in use on your host, modify the port mappings in docker-compose.yml
*   The Nginx configuration is modified to use port 8080 to avoid conflicts with Apache

**Snap not working in container**:

*   Snap has limitations in containers. The test script expects snap tests to fail in Docker.
*   Use `--test-mode` flag for container environments
*   Use `--pip` for a more reliable installation method in containers

**DNS resolution issues**:

*   The container may have different DNS settings than your host
*   For GitHub Actions testing, domains are added to the hosts file

### Debugging

For more detailed debugging, add the `--verbose` flag to your lecbh.sh commands and inspect the logs:

```
docker-compose logs
```

To run a specific test from the test script:

```
docker-compose exec -T lecbh-test /app/lecbh.sh --dry-run --unattended --test-mode
```

## Advanced Testing Scenarios

### Testing with Real Domains

To test with real domains, you'll need to:

1.  Ensure your domain's DNS points to the IP where you're running Docker
2.  Forward ports 80 and 443 to your Docker host
3.  Run the script without the `--dry-run` flag (be cautious with rate limits)

### Testing Certificate Renewal

To test certificate renewal without waiting for the actual renewal period:

```
docker-compose exec lecbh-test certbot renew --dry-run
```

### Testing with Custom Configurations

You can create different test configurations by modifying the environment variables:

```
docker-compose exec -e DEFAULT_EMAIL=custom@example.com -e DEFAULT_DOMAINS=custom.example.com lecbh-test /app/lecbh.sh --dry-run --unattended
```

### Running a Specific Set of Tests

You can modify the test script to run only specific tests by commenting out unwanted test sections, or call specific tests directly:

```
# Run only the pip installation test
docker-compose exec -T lecbh-test bash -c "/app/lecbh.sh --dry-run --unattended --pip"
```