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
    echo -e "${BLUE}Installing Homebrew first...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew install --cask visual-studio-code
echo -e "${GREEN}✅ VS Code installed! 🎉${NC}"
