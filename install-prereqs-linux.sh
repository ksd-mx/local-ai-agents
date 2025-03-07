#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   Linux Prerequisites Installer          ${NC}"
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

# Determine Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}Cannot determine Linux distribution.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Detected Linux distribution: ${DISTRO}${NC}"

# Check for Git
echo -e "\n${YELLOW}Checking for Git...${NC}"
if ! check_command git; then
    echo -e "${YELLOW}Git not found. Installing Git...${NC}"
    
    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            sudo apt-get update
            sudo apt-get install -y git
            ;;
        fedora|centos|rhel)
            sudo dnf install -y git
            ;;
        arch|manjaro)
            sudo pacman -Sy --noconfirm git
            ;;
        *)
            echo -e "${RED}Unsupported distribution for automatic Git installation.${NC}"
            echo -e "${RED}Please install Git manually for your distribution.${NC}"
            exit 1
            ;;
    esac
    
    if ! check_command git; then
        echo -e "${RED}Failed to install Git. Please install it manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Git is already installed.${NC}"
fi

# Install Docker
echo -e "\n${YELLOW}Checking for Docker...${NC}"
if ! check_command docker; then
    echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
    
    case $DISTRO in
        ubuntu|debian|linuxmint|pop)
            # Install prerequisites
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
                
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up the repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              
            # Install Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Add current user to docker group to avoid using sudo with docker
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}Added current user to the docker group. You may need to log out and log back in for this to take effect.${NC}"
            ;;
            
        fedora)
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}Added current user to the docker group. You may need to log out and log back in for this to take effect.${NC}"
            ;;
            
        centos|rhel)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}Added current user to the docker group. You may need to log out and log back in for this to take effect.${NC}"
            ;;
            
        arch|manjaro)
            sudo pacman -Sy --noconfirm docker docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo -e "${YELLOW}Added current user to the docker group. You may need to log out and log back in for this to take effect.${NC}"
            ;;
            
        *)
            echo -e "${RED}Unsupported distribution for automatic Docker installation.${NC}"
            echo -e "${RED}Please install Docker manually for your distribution.${NC}"
            echo -e "${RED}Visit https://docs.docker.com/engine/install/ for instructions.${NC}"
            exit 1
            ;;
    esac
    
    if ! check_command docker; then
        echo -e "${RED}Failed to install Docker. Please install it manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker is already installed.${NC}"
fi

# Check for Docker Compose
echo -e "\n${YELLOW}Checking for Docker Compose...${NC}"
if ! check_command "docker compose" && ! check_command docker-compose; then
    echo -e "${YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
    
    # First try to install the compose plugin if Docker is installed
    if check_command docker; then
        case $DISTRO in
            ubuntu|debian|linuxmint|pop|fedora|centos|rhel)
                # Docker Compose plugin should have been installed with docker-ce
                if ! check_command "docker compose"; then
                    # Fallback to standalone docker-compose
                    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
                    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                    sudo chmod +x /usr/local/bin/docker-compose
                    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
                fi
                ;;
                
            arch|manjaro)
                # Should have been installed with docker
                if ! check_command "docker compose"; then
                    sudo pacman -Sy --noconfirm docker-compose
                fi
                ;;
                
            *)
                echo -e "${RED}Unsupported distribution for automatic Docker Compose installation.${NC}"
                echo -e "${RED}Please install Docker Compose manually for your distribution.${NC}"
                echo -e "${RED}Visit https://docs.docker.com/compose/install/ for instructions.${NC}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}Docker must be installed before Docker Compose.${NC}"
        exit 1
    fi
    
    if ! check_command "docker compose" && ! check_command docker-compose; then
        echo -e "${RED}Failed to install Docker Compose. Please install it manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker Compose is already installed.${NC}"
fi

# Start Docker service if not running
echo -e "\n${YELLOW}Checking if Docker is running...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${YELLOW}Docker is not running. Starting Docker service...${NC}"
    sudo systemctl start docker
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Failed to start Docker service. Please start it manually:${NC}"
        echo -e "${RED}sudo systemctl start docker${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker is running.${NC}"
fi

# Enable Docker to start on boot
echo -e "\n${YELLOW}Enabling Docker to start on boot...${NC}"
sudo systemctl enable docker

# Verify installations
echo -e "\n${YELLOW}Verifying installations...${NC}"
echo -e "${GREEN}✓ Git version: $(git --version)${NC}"
echo -e "${GREEN}✓ Docker version: $(docker --version)${NC}"

if check_command "docker compose"; then
    echo -e "${GREEN}✓ Docker Compose version: $(docker compose version)${NC}"
elif check_command docker-compose; then
    echo -e "${GREEN}✓ Docker Compose version: $(docker-compose --version)${NC}"
fi

echo -e "\n${GREEN}All prerequisites have been installed and verified!${NC}"
echo -e "${YELLOW}You can now run ./setup.sh to continue with the setup process.${NC}"
echo -e "${YELLOW}NOTE: You may need to log out and log back in for docker permissions to take effect.${NC}"