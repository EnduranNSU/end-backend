#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AUTH_URL="http://localhost:8082"
MEASUREMENTS_URL="http://localhost:8083"

TOKEN=""

echo -e "${YELLOW}Getting token...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST $AUTH_URL/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser@example.com","password":"testpass123"}')

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token')
if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✓ Token obtained${NC}"
else
    echo -e "${RED}✗ Login failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}=== MEASUREMENTS SERVICE TESTS ===${NC}"

# 1. Get all measurements
echo -e "\n${YELLOW}1. Get all measurements:${NC}"
curl -s -X GET $MEASUREMENTS_URL/api/v1/measurements \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 2. Create a single measurement (according to Swagger spec)
echo -e "\n${YELLOW}2. Create a single measurement:${NC}"
CREATE_RESPONSE=$(curl -s -X POST $MEASUREMENTS_URL/api/v1/measurements/create \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "weight",
    "value": 75,
    "date": "2026-04-14"
  }')
echo "$CREATE_RESPONSE" | jq '.'

# 3. Create another measurement
echo -e "\n${YELLOW}3. Create height measurement:${NC}"
CREATE_RESPONSE=$(curl -s -X POST $MEASUREMENTS_URL/api/v1/measurements/create \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "height",
    "value": 175,
    "date": "2026-04-14"
  }')
echo "$CREATE_RESPONSE" | jq '.'

# 4. Get measurements again to see created ones
echo -e "\n${YELLOW}4. Get all measurements after creation:${NC}"
curl -s -X GET $MEASUREMENTS_URL/api/v1/measurements \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 5. Update all measurements (send array)
echo -e "\n${YELLOW}5. Update all measurements (replace with new array):${NC}"
UPDATE_RESPONSE=$(curl -s -X POST $MEASUREMENTS_URL/api/v1/measurements/update \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "type": "weight",
      "value": 74,
      "date": "2026-04-14"
    },
    {
      "type": "height",
      "value": 176,
      "date": "2026-04-14"
    },
    {
      "type": "body_fat",
      "value": 15,
      "date": "2026-04-14"
    }
  ]')
echo "$UPDATE_RESPONSE" | jq '.'

# 6. Get final measurements
echo -e "\n${YELLOW}6. Final measurements after update:${NC}"
curl -s -X GET $MEASUREMENTS_URL/api/v1/measurements \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo -e "\n${GREEN}✓ Measurements service tests completed${NC}"