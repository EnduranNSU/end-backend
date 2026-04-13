#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Fixing MinIO Access ===${NC}"

# MinIO credentials (default for docker-compose)
ACCESS_KEY="root"
SECRET_KEY="password"
BUCKET="exercises"

# Function to make authenticated request to MinIO
minio_curl() {
    local method=$1
    local path=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X $method "http://localhost:9000${path}" \
            -u "${ACCESS_KEY}:${SECRET_KEY}" \
            -H "Content-Type: text/plain" \
            --data-binary "$data"
    else
        curl -s -X $method "http://localhost:9000${path}" \
            -u "${ACCESS_KEY}:${SECRET_KEY}"
    fi
}

# Check if bucket exists
echo -e "\n${YELLOW}1. Checking bucket...${NC}"
BUCKET_EXISTS=$(minio_curl "HEAD" "/${BUCKET}/" 2>/dev/null; echo $?)

if [ "$BUCKET_EXISTS" -ne 0 ]; then
    echo -e "${YELLOW}Creating bucket: ${BUCKET}${NC}"
    minio_curl "PUT" "/${BUCKET}/" > /dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Bucket created${NC}"
    else
        echo -e "${RED}✗ Failed to create bucket${NC}"
    fi
else
    echo -e "${GREEN}✓ Bucket already exists${NC}"
fi

# Upload descriptions for exercises
echo -e "\n${YELLOW}2. Uploading exercise descriptions...${NC}"

# Get exercise IDs from PostgreSQL
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "postgres" | head -1)

if [ -n "$POSTGRES_CONTAINER" ]; then
    EXERCISE_IDS=$(docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp -t -c "SELECT id FROM exercises ORDER BY id;" 2>/dev/null | tr -d ' ')
else
    # If can't get from DB, upload for IDs 1-12
    EXERCISE_IDS=$(seq 1 12)
fi

for id in $EXERCISE_IDS; do
    echo -n "  Uploading ex-${id}.txt... "
    
    # Create description content
    cat > /tmp/ex-${id}.txt << EOF
# Exercise ${id} Description

## Basic Information
This is a comprehensive description for exercise ${id}.

## Instructions
1. Start in proper position
2. Execute movement with control
3. Return to starting position
4. Repeat as needed

## Safety Tips
- Warm up properly
- Maintain proper form
- Listen to your body

## Progressions
- Beginner: Start slow
- Intermediate: Increase intensity
- Advanced: Add resistance
EOF

    # Upload using AWS signature v4
    UPLOAD_RESULT=$(minio_curl "PUT" "/${BUCKET}/ex-${id}.txt" "$(cat /tmp/ex-${id}.txt)" 2>&1)
    
    if [ -z "$UPLOAD_RESULT" ] || echo "$UPLOAD_RESULT" | grep -q "Error"; then
        echo -e "${RED}Failed${NC}"
        echo "  Error: $UPLOAD_RESULT"
    else
        echo -e "${GREEN}✓${NC}"
    fi
    
    rm -f /tmp/ex-${id}.txt
done

# Verify uploads
echo -e "\n${YELLOW}3. Verifying uploads...${NC}"
FILES=$(minio_curl "GET" "/${BUCKET}/" | grep -o "ex-[0-9]*\.txt" | sort -u)

if [ -n "$FILES" ]; then
    echo -e "${GREEN}Uploaded files:${NC}"
    echo "$FILES"
else
    echo -e "${RED}No files found in bucket${NC}"
fi

# Test download
echo -e "\n${YELLOW}4. Testing download...${NC}"
TEST_DOWNLOAD=$(minio_curl "GET" "/${BUCKET}/ex-1.txt" 2>/dev/null | head -1)
if [ -n "$TEST_DOWNLOAD" ]; then
    echo -e "${GREEN}✓ Download successful: ${TEST_DOWNLOAD}${NC}"
else
    echo -e "${RED}✗ Download failed${NC}"
fi

echo -e "\n${GREEN}✓ MinIO setup completed!${NC}"