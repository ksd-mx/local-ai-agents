#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting cleanup process...${NC}"

# Stop n8n containers if running and remove volumes
echo -e "${YELLOW}Stopping n8n containers and removing volumes...${NC}"
if docker ps -q --filter "name=n8n" | grep -q .; then
  docker compose down --volumes --remove-orphans
  echo -e "${GREEN}n8n containers stopped and volumes removed.${NC}"
else
  echo -e "${YELLOW}No running n8n containers found.${NC}"
fi

# Stop Supabase containers if running and remove volumes
echo -e "${YELLOW}Stopping Supabase containers and removing volumes...${NC}"
if [ -d "supabase-docker" ]; then
  (cd supabase-docker && docker compose down --volumes --remove-orphans)
  echo -e "${GREEN}Supabase containers stopped and volumes removed.${NC}"
else
  echo -e "${YELLOW}Supabase setup directory not found.${NC}"
fi

# Remove any leftover containers with names containing n8n or supabase
echo -e "${YELLOW}Removing any leftover containers...${NC}"
CONTAINERS=$(docker ps -a --filter "name=n8n" --filter "name=supabase" -q)
if [ ! -z "$CONTAINERS" ]; then
  docker rm -f $CONTAINERS 2>/dev/null
  echo -e "${GREEN}Leftover containers removed.${NC}"
else
  echo -e "${YELLOW}No leftover containers found.${NC}"
fi

# Remove any remaining Docker volumes (in case --volumes missed some)
echo -e "${YELLOW}Removing any remaining Docker volumes...${NC}"
# Volumes that might be named directly in the docker-compose files
NAMED_VOLUMES=$(docker volume ls -q --filter "name=db-config" --filter "name=supabase_db-config")
if [ ! -z "$NAMED_VOLUMES" ]; then
  docker volume rm $NAMED_VOLUMES 2>/dev/null
  echo -e "${GREEN}Named volumes removed.${NC}"
fi

# Explicitly remove the Kong data volume if it exists
KONG_VOLUME=$(docker volume ls -q --filter "name=supabase-kong")
if [ ! -z "$KONG_VOLUME" ]; then
  docker volume rm $KONG_VOLUME 2>/dev/null
  echo -e "${GREEN}Kong volume removed.${NC}"
fi

# Catch any other volumes that might have been created
echo -e "${YELLOW}Checking for other related volumes...${NC}"
OTHER_VOLUMES=$(docker volume ls -q --filter "name=n8n" --filter "name=supabase")
if [ ! -z "$OTHER_VOLUMES" ]; then
  docker volume rm $OTHER_VOLUMES 2>/dev/null
  echo -e "${GREEN}Other related volumes removed.${NC}"
fi

# Remove Docker networks
echo -e "${YELLOW}Removing Docker networks...${NC}"
NETWORKS=$(docker network ls -q --filter "name=n8n" --filter "name=supabase")
if [ ! -z "$NETWORKS" ]; then
  docker network rm $NETWORKS 2>/dev/null
  echo -e "${GREEN}Docker networks removed.${NC}"
else
  echo -e "${YELLOW}No Docker networks found.${NC}"
fi

# Remove local directories
echo -e "${YELLOW}Removing local directories...${NC}"
if [ -d "n8n-volumes" ]; then
  rm -rf n8n-volumes
  echo -e "${GREEN}n8n volumes directory removed.${NC}"
else
  echo -e "${YELLOW}n8n volumes directory not found.${NC}"
fi

if [ -d "supabase-docker" ]; then
  rm -rf supabase-docker
  echo -e "${GREEN}supabase-docker directory removed.${NC}"
else
  echo -e "${YELLOW}supabase-docker directory not found.${NC}"
fi

# If supabase-docker/volumes exists with Kong configurations, remove it
if [ -d "supabase-docker/volumes" ]; then
  rm -rf supabase-docker/volumes
  echo -e "${GREEN}supabase-docker/volumes directory removed.${NC}"
fi

# Ensure Kong will use fresh credentials on next startup
echo -e "${YELLOW}Ensuring Kong will use fresh credentials...${NC}"
if [ -f "supabase-docker/.env" ]; then
  # Back up the original .env file
  cp supabase-docker/.env supabase-docker/.env.bak
  
  # Generate new dashboard credentials
  NEW_USERNAME="supabase"
  NEW_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
  
  # Update the credentials in the .env file
  sed -i.tmp "s/^DASHBOARD_USERNAME=.*/DASHBOARD_USERNAME=$NEW_USERNAME/" supabase-docker/.env
  sed -i.tmp "s/^DASHBOARD_PASSWORD=.*/DASHBOARD_PASSWORD=$NEW_PASSWORD/" supabase-docker/.env
  
  # Remove temporary files
  rm -f supabase-docker/.env.tmp
  
  echo -e "${GREEN}Updated Kong credentials in .env file.${NC}"
  echo -e "${YELLOW}New dashboard username: ${GREEN}$NEW_USERNAME${NC}"
  echo -e "${YELLOW}New dashboard password: ${GREEN}$NEW_PASSWORD${NC}"
  echo -e "${YELLOW}Please make note of these credentials for your next login.${NC}"
else
  echo -e "${YELLOW}No .env file found. Kong credentials will use defaults.${NC}"
fi

# Note about images
echo -e "${GREEN}Cleanup complete!${NC}"
echo -e "${YELLOW}Note: Docker images have been preserved as requested.${NC}"
echo -e "If you want to remove the images later, you can use:"
echo -e "  docker rmi \$(docker images 'docker.n8n.io/n8nio/n8n' -q)"
echo -e "  docker rmi \$(docker images 'postgres' -q)"
echo -e "  docker rmi \$(docker images 'redis' -q)"
echo -e "  docker rmi \$(docker images '*supabase*' -q)"
echo -e "  docker rmi \$(docker images '*kong*' -q)"