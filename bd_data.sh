#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Preparing Test Data for End-Backend${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AUTH_URL="http://localhost:8082"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Creating test user via API${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Wait for auth service
echo -e "${YELLOW}Waiting for auth service...${NC}"
sleep 5

# Register user via API (this will create user with properly hashed password)
echo -e "\n${YELLOW}Registering test user...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST $AUTH_URL/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "name": "Test User",
    "password": "testpass123"
  }')

echo "$REGISTER_RESPONSE" | jq '.'

if echo "$REGISTER_RESPONSE" | grep -q "id"; then
    echo -e "${GREEN}✓ User created successfully via API${NC}"
else
    echo -e "${RED}✗ Failed to create user via API${NC}"
    
    # Try to delete existing user and retry
    echo -e "${YELLOW}User might already exist, trying to login instead...${NC}"
fi

# Test login
echo -e "\n${YELLOW}Testing login...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST $AUTH_URL/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser@example.com",
    "password": "testpass123"
  }')

echo "$LOGIN_RESPONSE" | jq '.'

if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    echo -e "${GREEN}✓ Login successful!${NC}"
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token')
    echo -e "Token: ${TOKEN:0:50}..."
else
    echo -e "${RED}✗ Login failed${NC}"
    
    # Check auth service logs
    echo -e "\n${YELLOW}Checking auth service logs...${NC}"
    docker-compose logs auth --tail=20
fi

echo -e "\n${GREEN}Done!${NC}"

# Find container names automatically
POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "postgres" | head -1)

if [ -z "$POSTGRES_CONTAINER" ]; then
    echo -e "${RED}Error: PostgreSQL container not found!${NC}"
    exit 1
fi

echo -e "${GREEN}Found PostgreSQL container: $POSTGRES_CONTAINER${NC}"
echo ""

# Wait for services to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
sleep 5

# ==================== 2. EXERCISES DATA ====================
echo -e "\n${YELLOW}📋 2. Adding exercises...${NC}"

docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Insert exercises if not exists
INSERT INTO exercises (title, tags, hrefs) VALUES 
('Push Up', ARRAY['chest', 'triceps', 'beginner'], ARRAY['https://youtu.be/pushup1', 'https://example.com/pushup']),
('Pull Up', ARRAY['back', 'biceps', 'intermediate'], ARRAY['https://youtu.be/pullup1', 'https://example.com/pullup']),
('Squat', ARRAY['legs', 'glutes', 'beginner'], ARRAY['https://youtu.be/squat1', 'https://example.com/squat']),
('Deadlift', ARRAY['back', 'hamstrings', 'advanced'], ARRAY['https://youtu.be/deadlift1', 'https://example.com/deadlift']),
('Bench Press', ARRAY['chest', 'triceps', 'intermediate'], ARRAY['https://youtu.be/bench1', 'https://example.com/bench']),
('Shoulder Press', ARRAY['shoulders', 'triceps', 'intermediate'], ARRAY['https://youtu.be/shoulder1', 'https://example.com/shoulder'])
ON CONFLICT (title) DO NOTHING;

SELECT '✓ Exercises: ' || COUNT(*) || ' rows' FROM exercises;
EOF

# ==================== 3. TRAININGS DATA ====================
echo -e "\n${YELLOW}📋 3. Adding trainings...${NC}"

docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Insert trainings if not exists
INSERT INTO trainings (title) VALUES 
('Full Body Workout'),
('Upper Body Day'),
('Lower Body Day'),
('Push Day'),
('Pull Day'),
('Leg Day')
ON CONFLICT DO NOTHING;

SELECT '✓ Trainings: ' || COUNT(*) || ' rows' FROM trainings;
EOF

# ==================== 4. GET CURRENT IDs ====================
echo -e "\n${YELLOW}📋 4. Getting current IDs...${NC}"

# Get the actual IDs from database
EXERCISE_IDS=$(docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp -t -c "SELECT id FROM exercises ORDER BY id LIMIT 4;")
TRAINING_IDS=$(docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp -t -c "SELECT id FROM trainings ORDER BY id LIMIT 3;")

echo "Exercise IDs: $EXERCISE_IDS"
echo "Training IDs: $TRAINING_IDS"

# Convert to arrays
EX_IDS=($EXERCISE_IDS)
TR_IDS=($TRAINING_IDS)

# ==================== 5. LINK EXERCISES TO TRAININGS ====================
echo -e "\n${YELLOW}📋 5. Linking exercises to trainings...${NC}"

if [ ${#EX_IDS[@]} -ge 3 ] && [ ${#TR_IDS[@]} -ge 1 ]; then
    docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Delete existing links
DELETE FROM perfomable_exercises;

-- Full Body Workout (training_id = ${TR_IDS[0]})
INSERT INTO perfomable_exercises (exercise_id, training_id) VALUES 
(${EX_IDS[0]}, ${TR_IDS[0]}),
(${EX_IDS[2]}, ${TR_IDS[0]});

-- Upper Body Day (training_id = ${TR_IDS[1]})
INSERT INTO perfomable_exercises (exercise_id, training_id) VALUES 
(${EX_IDS[0]}, ${TR_IDS[1]}),
(${EX_IDS[1]}, ${TR_IDS[1]});

-- Lower Body Day (training_id = ${TR_IDS[2]})
INSERT INTO perfomable_exercises (exercise_id, training_id) VALUES 
(${EX_IDS[2]}, ${TR_IDS[2]}),
(${EX_IDS[3]}, ${TR_IDS[2]});

SELECT '✓ Linked: ' || COUNT(*) || ' rows' FROM perfomable_exercises;
EOF
fi

# ==================== 6. ADD SETS ====================
echo -e "\n${YELLOW}📋 6. Adding sets...${NC}"

docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Delete existing sets
DELETE FROM sets;

-- Get perfomable_exercise IDs and add sets
INSERT INTO sets (weight, repetitions, rest_duration, perfomable_exercise_id)
SELECT 0, 12, 60, id FROM perfomable_exercises;

SELECT '✓ Sets: ' || COUNT(*) || ' rows' FROM sets;
EOF

# ==================== 7. PLANNED TRAININGS ====================
echo -e "\n${YELLOW}📋 7. Adding planned trainings...${NC}"

if [ ${#TR_IDS[@]} -ge 1 ]; then
    docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Delete existing planned trainings for user
DELETE FROM planned_trainings WHERE user_id = (SELECT id FROM users WHERE email = 'testuser@example.com');

-- Get user_id and add planned trainings
INSERT INTO planned_trainings (user_id, training_id, weekdays)
SELECT u.id, t.id, ARRAY['Monday', 'Thursday']
FROM users u, trainings t
WHERE u.email = 'testuser@example.com' 
  AND t.title = 'Full Body Workout';

SELECT '✓ Planned trainings: ' || COUNT(*) || ' rows' FROM planned_trainings;
EOF
fi

# ==================== 8. PERFORMED TRAININGS ====================
echo -e "\n${YELLOW}📋 8. Adding performed trainings...${NC}"

docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Delete existing performed trainings
DELETE FROM user_performed_trainings WHERE user_id = (SELECT id FROM users WHERE email = 'testuser@example.com');

-- Add performed training
INSERT INTO user_performed_trainings (user_id, training_id, date)
SELECT u.id, t.id, NOW()::text
FROM users u, trainings t
WHERE u.email = 'testuser@example.com' 
  AND t.title = 'Full Body Workout';

SELECT '✓ Performed trainings: ' || COUNT(*) || ' rows' FROM user_performed_trainings;
EOF

# ==================== 9. MEASUREMENTS ====================
echo -e "\n${YELLOW}📋 9. Adding measurements...${NC}"

docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
-- Delete existing measurements
DELETE FROM measurements WHERE user_id = (SELECT id FROM users WHERE email = 'testuser@example.com');

-- Add measurements for user
INSERT INTO measurements (user_id, type, value, date) VALUES
((SELECT id FROM users WHERE email = 'testuser@example.com'), 'weight', 75, '2026-04-01'),
((SELECT id FROM users WHERE email = 'testuser@example.com'), 'height', 175, '2026-04-01'),
((SELECT id FROM users WHERE email = 'testuser@example.com'), 'weight', 74, '2026-04-08'),
((SELECT id FROM users WHERE email = 'testuser@example.com'), 'weight', 73, '2026-04-15');

SELECT '✓ Measurements: ' || COUNT(*) || ' rows' FROM measurements;
EOF

# ==================== 10. VERIFICATION ====================
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Data Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

docker exec -i $POSTGRES_CONTAINER psql -U postgres -d myapp << EOF
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'exercises', COUNT(*) FROM exercises
UNION ALL
SELECT 'trainings', COUNT(*) FROM trainings
UNION ALL
SELECT 'perfomable_exercises', COUNT(*) FROM perfomable_exercises
UNION ALL
SELECT 'sets', COUNT(*) FROM sets
UNION ALL
SELECT 'planned_trainings', COUNT(*) FROM planned_trainings
UNION ALL
SELECT 'user_performed_trainings', COUNT(*) FROM user_performed_trainings
UNION ALL
SELECT 'measurements', COUNT(*) FROM measurements;
EOF

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Data preparation completed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "\n${YELLOW}You can now login with:${NC}"
echo -e "  Email: testuser@example.com"
echo -e "  Password: testpass123"