#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed.${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed.${NC}"
        return 0
    fi
}

# Function to check Docker version
check_docker_version() {
    local version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Could not determine Docker version. Is Docker running?${NC}"
        return 1
    fi
    
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    
    if [ "$major" -lt 19 ] || ([ "$major" -eq 19 ] && [ "$minor" -lt 3 ]); then
        echo -e "${RED}Error: Docker version should be at least 19.03. Current version: $version${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Docker version $version is sufficient.${NC}"
        return 0
    fi
}

# Check available RAM
check_ram() {
    local available_ram=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        available_ram=$(sysctl -n hw.memsize 2>/dev/null)
        available_ram=$((available_ram / 1024 / 1024))  # Convert to MB
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        available_ram=$(free -m | awk '/^Mem:/{print $2}')
    else
        echo -e "${YELLOW}Warning: Could not determine available RAM on this OS.${NC}"
        return 0
    fi
    
    if [ -n "$available_ram" ] && [ "$available_ram" -lt 4000 ]; then
        echo -e "${YELLOW}Warning: Less than 4GB RAM available ($available_ram MB). This might cause performance issues.${NC}"
    else
        echo -e "${GREEN}✓ Sufficient RAM available: $available_ram MB${NC}"
    fi
    
    return 0
}

# Check if Docker is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Docker is running.${NC}"
        return 0
    fi
}

# Title
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}     n8n + Supabase Setup Utility        ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"
prerequisites_met=true

if ! check_command docker; then
    prerequisites_met=false
    echo -e "${YELLOW}Please install Docker first. You can use our installation scripts:${NC}"
    echo -e "  For Mac: ./install-prereqs-mac.sh"
    echo -e "  For Linux: ./install-prereqs-linux.sh"
fi

if ! check_command docker-compose && ! check_command "docker compose"; then
    prerequisites_met=false
    echo -e "${YELLOW}Please install Docker Compose. You can use our installation scripts:${NC}"
    echo -e "  For Mac: ./install-prereqs-mac.sh"
    echo -e "  For Linux: ./install-prereqs-linux.sh"
fi

if ! check_command git; then
    prerequisites_met=false
    echo -e "${YELLOW}Please install Git. You can use our installation scripts:${NC}"
    echo -e "  For Mac: ./install-prereqs-mac.sh"
    echo -e "  For Linux: ./install-prereqs-linux.sh"
fi

if ! check_docker_running; then
    prerequisites_met=false
fi

if check_docker_version; then
    :  # Success, do nothing
else
    prerequisites_met=false
fi

check_ram

# Ask for confirmation if prerequisites are not met
if [ "$prerequisites_met" = false ]; then
    echo -e "\n${RED}Some prerequisites are not met.${NC}"
    read -p "Do you want to continue anyway? (y/N): " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setup aborted.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Continuing despite missing prerequisites...${NC}"
fi

echo -e "\n${GREEN}Setting up n8n and Supabase environments...${NC}"

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p supabase-docker
mkdir -p n8n-volumes/n8n n8n-volumes/postgres n8n-volumes/redis

# Check if vector-db.sql exists
if [ ! -f "vector-db.sql" ]; then
  echo -e "${RED}vector-db.sql file not found. Please create it before running this script.${NC}"
  exit 1
fi

# Clone only the docker directory from Supabase
echo -e "${YELLOW}Cloning Supabase docker directory...${NC}"
if ! git clone --depth 1 --filter=blob:none --sparse https://github.com/supabase/supabase.git temp-supabase; then
  echo -e "${RED}Failed to clone Supabase repository. Please check your internet connection and git installation.${NC}"
  exit 1
fi

cd temp-supabase
git sparse-checkout set docker
cd ..

# Copy only the docker directory
echo -e "${YELLOW}Copying Supabase docker files...${NC}"
mkdir -p supabase-docker && mv temp-supabase/docker/{*,.[!.]*,..?*} supabase-docker/ 2>/dev/null || true && rm -rf temp-supabase

# Rename .env.example to .env for Supabase
echo -e "${YELLOW}Setting up Supabase environment file...${NC}"
if [ -f "supabase-docker/.env.example" ]; then
  cp supabase-docker/.env.example supabase-docker/.env
  echo -e "${GREEN}Copied .env.example to .env for Supabase.${NC}"
else
  echo -e "${RED}Supabase .env.example not found. Please check the repository structure.${NC}"
fi

# Make scripts executable
chmod +x *.sh

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Review the n8n.env file and update values if needed"
echo -e "2. Run './start.sh' to start all services"