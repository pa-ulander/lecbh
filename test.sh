#!/bin/bash
# Test script for lecbh

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting lecbh test suite...${NC}"

# Start the container
echo -e "${YELLOW}Starting Docker container...${NC}"
docker-compose up -d
sleep 10 # Give container more time to start and initialize services

# Function to run a test
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_failure="$3"

    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    if docker-compose exec -T lecbh-test bash -c "$test_cmd"; then
        echo -e "${GREEN}✓ Test passed: ${test_name}${NC}"
        return 0
    else
        if [[ -n "$expected_failure" && "$expected_failure" == "true" ]]; then
            echo -e "${YELLOW}ℹ️ Expected failure: ${test_name}${NC}"
            return 0
        else
            echo -e "${RED}✗ Test failed: ${test_name}${NC}"
            return 1
        fi
    fi
}

# Function to check if services are running in the container
check_services() {
    echo -e "${YELLOW}Checking if services are running in container...${NC}"
    docker-compose exec -T lecbh-test bash -c "service apache2 status && service nginx status"

    # Try to start the services if they're not running
    docker-compose exec -T lecbh-test bash -c "service apache2 start || true"
    docker-compose exec -T lecbh-test bash -c "service nginx start || true"

    # Verify ports are accessible
    echo -e "${YELLOW}Checking if web server ports are accessible...${NC}"
    docker-compose exec -T lecbh-test bash -c "nc -z localhost 80 && echo 'Port 80 is accessible' || echo 'Port 80 is NOT accessible'"
    docker-compose exec -T lecbh-test bash -c "nc -z localhost 8080 && echo 'Port 8080 is accessible' || echo 'Port 8080 is NOT accessible'"
}

# Run tests
failed_tests=0

# Make sure services are running
check_services

echo -e "${YELLOW}==== Running tests in test mode (mock installation) ====${NC}"

# Test 1: Basic help command
run_test "Help command" "/app/lecbh.sh --help" || ((failed_tests++))

# Test 2: Dry run with Apache (test mode)
run_test "Dry run with Apache (test mode)" "/app/lecbh.sh --dry-run --unattended --test-mode" || ((failed_tests++))

# Test 3: Dry run with Nginx (test mode)
run_test "Dry run with Nginx (test mode)" "export DEFAULT_SERVER=nginx && /app/lecbh.sh --dry-run --unattended --test-mode" || ((failed_tests++))

# Test 4: Verbose output (test mode)
run_test "Verbose output (test mode)" "/app/lecbh.sh --dry-run --verbose --unattended --test-mode" || ((failed_tests++))

# Test 5: Staging environment (test mode)
run_test "Staging environment (test mode)" "/app/lecbh.sh --dry-run --staging --unattended --test-mode" || ((failed_tests++))

# Test 6: Multiple domains (test mode)
run_test "Multiple domains (test mode)" "export DEFAULT_DOMAINS='example.com,www.example.com' && /app/lecbh.sh --dry-run --unattended --test-mode" || ((failed_tests++))

echo -e "${YELLOW}==== Running tests with pip installation method ====${NC}"

# Install Python and pip in the container if they aren't already
run_test "Install pip dependencies" "apt-get update && apt-get install -y python3-pip" || ((failed_tests++))

# Test 7: Pip installation (dry run)
run_test "Pip installation (dry run)" "/app/lecbh.sh --dry-run --unattended --pip" || ((failed_tests++))

# Test 8: Pip installation with Nginx (dry run)
run_test "Pip with Nginx (dry run)" "export DEFAULT_SERVER=nginx && /app/lecbh.sh --dry-run --unattended --pip" || ((failed_tests++))

# Test 9: Pip installation with staging (dry run)
run_test "Pip with staging (dry run)" "/app/lecbh.sh --dry-run --staging --unattended --pip" || ((failed_tests++))

echo -e "${YELLOW}==== Running tests with snap installation method ====${NC}"
echo -e "${YELLOW}Note: Snap tests may fail in standard Docker containers${NC}"
echo -e "${YELLOW}The following tests are expected to pass in a real Ubuntu environment${NC}"

# Test 10: Attempt snap installation (expected to fail in Docker)
run_test "Snap installation attempt (dry run)" "/app/lecbh.sh --dry-run --unattended --snap" "true" || ((failed_tests++))
echo -e "${YELLOW}ℹ️ Snap installation test is expected to fail in standard Docker container.${NC}"
echo -e "${YELLOW}ℹ️ This would work in a real Ubuntu environment or Docker with systemd support.${NC}"

# Test with test mode and snap flag (should pass)
run_test "Snap with test mode (mock installation)" "/app/lecbh.sh --dry-run --unattended --snap --test-mode" || ((failed_tests++))

# Clean up
echo -e "${YELLOW}Cleaning up Docker container...${NC}"
docker-compose down

# Report results
echo -e "${YELLOW}Test summary:${NC}"
if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${failed_tests} test(s) failed.${NC}"
    exit 1
fi
