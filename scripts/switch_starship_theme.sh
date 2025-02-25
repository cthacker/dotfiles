#!/usr/bin/env bash

# Colors for better readability
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
PRESETS_DIR="$DOTFILES_DIR/config/starship/presets"
DEFAULT_CONFIG="$DOTFILES_DIR/config/starship/starship.toml"

# Function to list available themes
list_themes() {
    echo -e "${BLUE}Available Starship themes:${RESET}"
    echo -e "${GREEN}default${RESET} - The default Starship configuration"
    for theme in "$PRESETS_DIR"/*.toml; do
        if [ -f "$theme" ]; then
            theme_name=$(basename "$theme" .toml)
            echo -e "${GREEN}$theme_name${RESET} - $(grep -m 1 "^# " "$theme" | sed 's/# //')"
        fi
    done
}

# Function to switch to a theme
switch_theme() {
    local theme=$1
    
    if [ "$theme" = "default" ]; then
        # Use the default configuration
        echo -e "${BLUE}Switching to default Starship configuration...${RESET}"
        if [ -f "$DEFAULT_CONFIG" ]; then
            cp "$DEFAULT_CONFIG" "$STARSHIP_CONFIG"
            echo -e "${GREEN}Successfully switched to default configuration!${RESET}"
        else
            echo -e "${RED}Default configuration not found at $DEFAULT_CONFIG${RESET}"
            exit 1
        fi
    elif [ -f "$PRESETS_DIR/$theme.toml" ]; then
        # Use the specified theme
        echo -e "${BLUE}Switching to $theme Starship theme...${RESET}"
        cp "$PRESETS_DIR/$theme.toml" "$STARSHIP_CONFIG"
        echo -e "${GREEN}Successfully switched to $theme theme!${RESET}"
    else
        echo -e "${RED}Theme '$theme' not found.${RESET}"
        list_themes
        exit 1
    fi
    
    echo -e "${YELLOW}Start a new terminal session or run 'source ~/.zshrc' to apply changes.${RESET}"
}

# Check arguments
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo -e "${BLUE}Starship Theme Switcher${RESET}"
    echo -e "${YELLOW}Usage:${RESET} $0 [theme]"
    echo -e "${YELLOW}       ${RESET} $0 --list"
    echo -e "\nOptions:"
    echo -e "  --list, -l    List available themes"
    echo -e "  --help, -h    Show this help message"
    echo -e "\nExamples:"
    echo -e "  $0 minimal    Switch to the minimal theme"
    echo -e "  $0 default    Switch to the default configuration"
    list_themes
    exit 0
elif [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
    list_themes
    exit 0
else
    switch_theme "$1"
fi 