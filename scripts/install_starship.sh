#!/usr/bin/env bash

# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BLUE}Installing Starship prompt...${RESET}"

# Check if Starship is already installed
if command -v starship &> /dev/null; then
    echo -e "${GREEN}Starship is already installed.${RESET}"
else
    echo -e "${BLUE}Starship not found. Installing...${RESET}"
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${BLUE}Installing via Homebrew...${RESET}"
            brew install starship
        else
            echo -e "${BLUE}Homebrew not found. Installing via the install script...${RESET}"
            curl -sS https://starship.rs/install.sh | sh
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            echo -e "${BLUE}Detected Debian/Ubuntu. Installing dependencies...${RESET}"
            sudo apt-get update
            sudo apt-get install -y curl
        elif command -v dnf &> /dev/null; then
            echo -e "${BLUE}Detected Fedora/RHEL. Installing dependencies...${RESET}"
            sudo dnf install -y curl
        elif command -v pacman &> /dev/null; then
            echo -e "${BLUE}Detected Arch Linux. Installing dependencies...${RESET}"
            sudo pacman -Sy curl
        fi
        
        echo -e "${BLUE}Installing Starship via the install script...${RESET}"
        curl -sS https://starship.rs/install.sh | sh
    else
        echo -e "${RED}Unsupported operating system. Please install Starship manually:${RESET}"
        echo -e "${BLUE}https://starship.rs/guide/#🚀-installation${RESET}"
        exit 1
    fi
fi

# Create symlink for the Starship configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STARSHIP_CONFIG="$DOTFILES_DIR/config/starship/starship.toml"
TARGET_CONFIG="$HOME/.config/starship.toml"

if [ -f "$STARSHIP_CONFIG" ]; then
    echo -e "${BLUE}Creating symlink for Starship configuration...${RESET}"
    mkdir -p "$HOME/.config"
    ln -sf "$STARSHIP_CONFIG" "$TARGET_CONFIG"
    echo -e "${GREEN}Starship configuration linked to $TARGET_CONFIG${RESET}"
else
    echo -e "${RED}Starship configuration not found at $STARSHIP_CONFIG${RESET}"
    echo -e "${RED}Please set up your configuration file first.${RESET}"
fi

# Final message
echo -e "${GREEN}Starship installation completed!${RESET}"
echo -e "${BLUE}Make sure your shell configuration loads Starship. For Zsh, add:${RESET}"
echo -e "${BLUE}eval \"\$(starship init zsh)\"${RESET}"
echo -e "${BLUE}For Bash, add:${RESET}"
echo -e "${BLUE}eval \"\$(starship init bash)\"${RESET}"
echo -e "\n${GREEN}Enjoy your new prompt!${RESET}" 