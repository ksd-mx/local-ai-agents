#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting n8n and Supabase services...${NC}"

# Start Supabase first
echo -e "${YELLOW}Starting Supabase...${NC}"
if [ -d "supabase-docker" ]; then
  (cd supabase-docker && docker compose up -d)
else
  echo -e "${RED}Supabase directory not found. Run setup.sh first.${NC}"
  exit 1
fi

# Start n8n
echo -e "${YELLOW}Starting n8n...${NC}"
docker compose up -d

# Dynamically get the Supabase DB container name
SUPABASE_DB_CONTAINER=$(docker ps --format '{{.Names}}' | grep db | grep supabase | head -n 1)

if [ -z "$SUPABASE_DB_CONTAINER" ]; then
  echo -e "${RED}Could not find Supabase DB container. Is Supabase running?${NC}"
  echo -e "${YELLOW}Will try the default name 'supabase-db' as fallback.${NC}"
  SUPABASE_DB_CONTAINER="supabase-db"
fi

echo -e "${YELLOW}Found Supabase DB container: ${SUPABASE_DB_CONTAINER}${NC}"

# Get the Docker network that Supabase DB is using
SUPABASE_NETWORK=$(docker inspect ${SUPABASE_DB_CONTAINER} -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}')
echo -e "${YELLOW}Supabase is using network: ${SUPABASE_NETWORK}${NC}"

# Wait for Supabase PostgreSQL to be ready
echo -e "${YELLOW}Waiting for Supabase PostgreSQL to be ready...${NC}"
max_retries=30
counter=0
while ! docker exec $SUPABASE_DB_CONTAINER pg_isready -h localhost -U postgres > /dev/null 2>&1; do
    counter=$((counter+1))
    if [ $counter -gt $max_retries ]; then
        echo -e "${RED}Timed out waiting for PostgreSQL to be ready.${NC}"
        break
    fi
    echo -e "${YELLOW}PostgreSQL is not ready yet. Waiting...${NC}"
    sleep 5
done

# Initialize vector extensions in Supabase
if docker exec $SUPABASE_DB_CONTAINER pg_isready -h localhost -U postgres > /dev/null 2>&1; then
    echo -e "${YELLOW}Initializing vector extensions in Supabase...${NC}"
    docker cp vector-db.sql $SUPABASE_DB_CONTAINER:/tmp/vector-db.sql
    docker exec $SUPABASE_DB_CONTAINER psql -U postgres -f /tmp/vector-db.sql
    
    # Check if the SQL execution was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Vector extensions initialized successfully!${NC}"
    else
        echo -e "${RED}Failed to initialize vector extensions. Check the SQL output above for errors.${NC}"
    fi
else
    echo -e "${RED}PostgreSQL is not ready. Could not initialize vector extensions.${NC}"
fi

# Read Supabase dashboard credentials from .env file
SUPABASE_USERNAME="supabase"
SUPABASE_PASSWORD="this_password_is_insecure_and_should_be_updated"
if [ -f "supabase-docker/.env" ]; then
    DASHBOARD_USERNAME=$(grep -E '^DASHBOARD_USERNAME=' supabase-docker/.env | cut -d '=' -f2)
    DASHBOARD_PASSWORD=$(grep -E '^DASHBOARD_PASSWORD=' supabase-docker/.env | cut -d '=' -f2)
    if [ ! -z "$DASHBOARD_USERNAME" ]; then
        SUPABASE_USERNAME=$DASHBOARD_USERNAME
    fi
    if [ ! -z "$DASHBOARD_PASSWORD" ]; then
        SUPABASE_PASSWORD=$DASHBOARD_PASSWORD
    fi
fi

echo -e "\n${GREEN}Services started!${NC}"
echo -e "Access n8n at: http://localhost:5678"
echo -e "Access Supabase at: http://localhost:8000"
echo -e "Access Supabase Studio directly at: http://localhost:3000"
echo -e "\n${YELLOW}Supabase Dashboard Login Credentials:${NC}"
echo -e "Username: ${GREEN}${SUPABASE_USERNAME}${NC}"
echo -e "Password: ${GREEN}${SUPABASE_PASSWORD}${NC}"

echo -e "\n${YELLOW}To connect n8n to Supabase:${NC}"
echo -e "1. Create a Postgres node in n8n with these credentials:"
echo -e "   Host: ${GREEN}${SUPABASE_DB_CONTAINER}${NC}"
echo -e "   Database: ${GREEN}postgres${NC}"
echo -e "   Port: ${GREEN}5432${NC}"
echo -e "   User: ${GREEN}postgres${NC}"
echo -e "   Password: ${GREEN}postgres${NC}"