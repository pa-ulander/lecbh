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
sleep 5 # Give systemd time to start

# Function to run a test
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    if docker-compose exec -T lecbh-test bash -c "$test_cmd"; then
        echo -e "${GREEN}✓ Test passed: ${test_name}${NC}"
        return 0
    else
        echo -e "${RED}✗ Test failed: ${test_name}${NC}"
        return 1
    fi
}

# Run tests
failed_tests=0

# Test 1: Basic help command
run_test "Help command" "/app/lecbh.sh --help" || ((failed_tests++))

# Test 2: Dry run with Apache
run_test "Dry run with Apache" "/app/lecbh.sh --dry-run --unattended" || ((failed_tests++))

# Test 3: Dry run with Nginx
run_test "Dry run with Nginx" "export DEFAULT_SERVER=nginx && /app/lecbh.sh --dry-run --unattended" || ((failed_tests++))

# Test 4: Verbose output
run_test "Verbose output" "/app/lecbh.sh --dry-run --verbose --unattended" || ((failed_tests++))

# Test 5: Staging environment
run_test "Staging environment" "/app/lecbh.sh --dry-run --staging --unattended" || ((failed_tests++))

# Test 6: Multiple domains
run_test "Multiple domains" "export DEFAULT_DOMAINS='example.com,www.example.com' && /app/lecbh.sh --dry-run --unattended" || ((failed_tests++))

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