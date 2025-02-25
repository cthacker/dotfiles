#!/usr/bin/env bash

# Colors
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BLUE}Cleaning up Prezto configuration...${RESET}"

# Backup function
backup_file() {
    local file=$1
    if [ -f "$file" ] || [ -d "$file" ] || [ -L "$file" ]; then
        local backup_dir="$HOME/.prezto_backup"
        
        # Create backup directory if it doesn't exist
        if [ ! -d "$backup_dir" ]; then
            echo -e "${BLUE}Creating backup directory at $backup_dir${RESET}"
            mkdir -p "$backup_dir"
        fi
        
        # Generate backup filename with timestamp
        local timestamp=$(date +"%Y%m%d%H%M%S")
        local basename=$(basename "$file")
        local backup_path="$backup_dir/${basename}_${timestamp}"
        
        echo -e "${YELLOW}Backing up $file to $backup_path${RESET}"
        cp -R "$file" "$backup_path"
        return 0
    else
        return 1
    fi
}

# List of Prezto files to remove
PREZTO_FILES=(
    "$HOME/.zprezto"
    "$HOME/.zpreztorc"
    "$HOME/.zprofile"
    "$HOME/.zshenv"
    "$HOME/.zlogin"
    "$HOME/.zlogout"
)

# Process each file
for file in "${PREZTO_FILES[@]}"; do
    if backup_file "$file"; then
        echo -e "${BLUE}Removing $file${RESET}"
        rm -rf "$file"
    else
        echo -e "${YELLOW}File not found: $file${RESET}"
    fi
done

# Check if there are any Prezto references in .zshrc
if [ -f "$HOME/.zshrc" ]; then
    if grep -q "prezto" "$HOME/.zshrc"; then
        echo -e "${YELLOW}Found Prezto references in .zshrc${RESET}"
        echo -e "${BLUE}Your .zshrc file may contain Prezto references.${RESET}"
        echo -e "${BLUE}Please verify that your new configuration works correctly.${RESET}"
    fi
fi

echo -e "${GREEN}Prezto cleanup completed!${RESET}"
echo -e "${BLUE}Prezto files have been backed up to ~/.prezto_backup before removal.${RESET}"
echo -e "${BLUE}Please restart your shell or run 'source ~/.zshrc' to apply changes.${RESET}" 