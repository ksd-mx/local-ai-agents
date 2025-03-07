#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping services...${NC}"

# Stop n8n
echo -e "${YELLOW}Stopping n8n...${NC}"
docker compose down --remove-orphans

# Stop Supabase
echo -e "${YELLOW}Stopping Supabase...${NC}"
if [ -d "supabase-docker" ]; then
  (cd supabase-docker && docker compose down --remove-orphans)
else
  echo -e "${YELLOW}Supabase directory not found, skipping Supabase shutdown${NC}"
fi

echo -e "${GREEN}All services stopped.${NC}"