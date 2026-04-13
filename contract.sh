#!/bin/bash

echo "=== Checking API Documentation ==="

# Check Training API Swagger
echo -e "\nTraining API endpoints:"
curl -s http://localhost:8080/swagger/doc.json | jq '.paths | keys' | grep training

# Check expected request bodies
echo -e "\nTraining API expected request bodies:"
curl -s http://localhost:8080/swagger/doc.json | jq '.components.schemas | keys'

# Check Measurements API
echo -e "\nMeasurements API endpoints:"
curl -s http://localhost:8083/swagger/doc.json | jq '.paths | keys'

echo -e "\nMeasurements API schemas:"
curl -s http://localhost:8083/swagger/doc.json | jq '.components.schemas | keys'