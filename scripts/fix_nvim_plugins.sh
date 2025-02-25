#!/usr/bin/env bash

# Colors for better readability
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BLUE}Fixing Neovim plugin issues...${RESET}"

# Check if Neovim is installed
if ! command -v nvim &> /dev/null; then
    echo -e "${RED}Neovim is not installed. Please install it first.${RESET}"
    exit 1
fi

# Fix for telescope-fzf-native
TELESCOPE_FZF_NATIVE_DIR="$HOME/.config/nvim/plugged/telescope-fzf-native.nvim"
if [ -d "$TELESCOPE_FZF_NATIVE_DIR" ]; then
    echo -e "${BLUE}Building telescope-fzf-native extension...${RESET}"
    cd "$TELESCOPE_FZF_NATIVE_DIR" || exit 1
    
    # Check if make is available
    if ! command -v make &> /dev/null; then
        echo -e "${RED}The 'make' command is not available. Please install build-essential or equivalent.${RESET}"
        exit 1
    fi
    
    # Build the extension
    if make clean && make; then
        echo -e "${GREEN}Successfully built telescope-fzf-native!${RESET}"
    else
        echo -e "${RED}Failed to build telescope-fzf-native. Check if you have the necessary build tools installed.${RESET}"
        echo -e "${YELLOW}Common dependencies: gcc, cmake, make${RESET}"
        exit 1
    fi
else
    echo -e "${YELLOW}telescope-fzf-native directory not found. Running PlugInstall...${RESET}"
    nvim --headless -c "PlugInstall" -c "qa"
    
    # Try again after installation
    if [ -d "$TELESCOPE_FZF_NATIVE_DIR" ]; then
        echo -e "${BLUE}Building telescope-fzf-native extension after installation...${RESET}"
        cd "$TELESCOPE_FZF_NATIVE_DIR" || exit 1
        if make clean && make; then
            echo -e "${GREEN}Successfully built telescope-fzf-native!${RESET}"
        else
            echo -e "${RED}Failed to build telescope-fzf-native.${RESET}"
            exit 1
        fi
    else
        echo -e "${RED}Failed to install telescope-fzf-native.${RESET}"
    fi
fi

# Fix for Airline hunks extension
echo -e "${BLUE}Installing vim-airline-themes and vim-gitgutter...${RESET}"
nvim --headless -c "PlugInstall vim-airline-themes vim-gitgutter" -c "qa"

echo -e "${GREEN}All fixes completed!${RESET}"
echo -e "${BLUE}Please restart Neovim for the changes to take effect.${RESET}" 