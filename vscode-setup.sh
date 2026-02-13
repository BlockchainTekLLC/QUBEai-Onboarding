#!/bin/bash
# Quick VS Code install
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "\n${BOLD}💻 Installing Visual Studio Code${NC}\n"

if [ -d "/Applications/Visual Studio Code.app" ]; then
    echo -e "${GREEN}✅ VS Code already installed${NC}"
    exit 0
fi

if ! command -v brew &>/dev/null; then
    # Try sourcing brew from default location first
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v brew &>/dev/null; then
    echo -e "${BLUE}Homebrew not found. Please install it first:${NC}"
    echo -e "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo -e "Then re-run this script."
    exit 1
fi

brew install --cask visual-studio-code
echo -e "${GREEN}✅ VS Code installed! 🎉${NC}"
