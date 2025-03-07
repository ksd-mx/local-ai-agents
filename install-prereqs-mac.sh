#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   macOS Prerequisites Installer          ${NC}"
echo -e "${BLUE}   for n8n + Supabase Environment         ${NC}"
echo -e "${BLUE}==========================================${NC}"

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    else
        return 0
    fi
}

# Check for Homebrew
echo -e "\n${YELLOW}Checking for Homebrew...${NC}"
if ! check_command brew; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the current session
    if [[ $(uname -m) == 'arm64' ]]; then
        echo -e "${YELLOW}Adding Homebrew to PATH for Apple Silicon...${NC}"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo -e "${YELLOW}Adding Homebrew to PATH for Intel Mac...${NC}"
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    if ! check_command brew; then
        echo -e "${RED}Failed to install Homebrew. Please install it manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Homebrew is already installed.${NC}"
fi

# Check for Git
echo -e "\n${YELLOW}Checking for Git...${NC}"
if ! check_command git; then
    echo -e "${YELLOW}Git not found. Installing Git...${NC}"
    brew install git
    if ! check_command git; then
        echo -e "${RED}Failed to install Git. Please install it manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Git is already installed.${NC}"
fi

# Check for Docker Desktop
echo -e "\n${YELLOW}Checking for Docker...${NC}"
if ! check_command docker; then
    echo -e "${YELLOW}Docker not found. Installing Docker Desktop...${NC}"
    
    # First, check if Homebrew Cask is installed
    if ! brew list --cask &>/dev/null; then
        echo -e "${YELLOW}Installing Homebrew Cask...${NC}"
        brew tap homebrew/cask
    fi
    
    brew install --cask docker
    
    echo -e "${YELLOW}Docker Desktop has been installed.${NC}"
    echo -e "${YELLOW}Please manually start Docker Desktop from your Applications folder.${NC}"
    echo -e "${YELLOW}After starting Docker Desktop, press Enter to continue...${NC}"
    read -p ""
    
    if ! check_command docker; then
        echo -e "${RED}Docker still not found in PATH. Please make sure Docker Desktop is running.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker is already installed.${NC}"
fi

# Check for Docker Compose (modern Docker Desktop includes it)
echo -e "\n${YELLOW}Checking for Docker Compose...${NC}"
if ! check_command "docker compose" && ! check_command docker-compose; then
    echo -e "${YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
    
    # Modern Docker installations should use the 'docker compose' plugin format
    if check_command docker; then
        # Install Docker Compose plugin
        mkdir -p ~/.docker/cli-plugins/
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
        curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
        chmod +x ~/.docker/cli-plugins/docker-compose
        
        if ! check_command "docker compose"; then
            echo -e "${RED}Failed to install Docker Compose. Please install it manually.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Docker must be installed before Docker Compose.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker Compose is already installed.${NC}"
fi

# Verify installations
echo -e "\n${YELLOW}Verifying installations...${NC}"
echo -e "${GREEN}✓ Git version: $(git --version)${NC}"
echo -e "${GREEN}✓ Docker version: $(docker --version)${NC}"

if check_command "docker compose"; then
    echo -e "${GREEN}✓ Docker Compose version: $(docker compose version)${NC}"
elif check_command docker-compose; then
    echo -e "${GREEN}✓ Docker Compose version: $(docker-compose --version)${NC}"
fi

# Start Docker if not running
echo -e "\n${YELLOW}Checking if Docker is running...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${YELLOW}Docker is not running. Attempting to start Docker...${NC}"
    
    echo -e "${YELLOW}On macOS, Docker Desktop needs to be started manually.${NC}"
    echo -e "${YELLOW}Please start Docker Desktop from your Applications folder.${NC}"
    echo -e "${YELLOW}After starting Docker Desktop, press Enter to continue...${NC}"
    read -p ""
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker is still not running. Please start Docker Desktop manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker is running.${NC}"
fi

echo -e "\n${GREEN}All prerequisites have been installed and verified!${NC}"
echo -e "${YELLOW}You can now run ./setup.sh to continue with the setup process.${NC}"