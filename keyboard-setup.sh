#!/bin/bash
# Quick PC keyboard setup — Karabiner-Elements + config
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "\n${BOLD}🎹 PC Keyboard Setup for Mac${NC}\n"

# Homebrew
if ! command -v brew &>/dev/null; then
    echo -e "${BLUE}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Karabiner
if [ -d "/Applications/Karabiner-Elements.app" ]; then
    echo -e "${GREEN}✅ Karabiner-Elements already installed${NC}"
else
    echo -e "${BLUE}Installing Karabiner-Elements...${NC}"
    brew install --cask karabiner-elements
fi

# Config
mkdir -p ~/.config/karabiner
curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/assets/karabiner/karabiner.json -o ~/.config/karabiner/karabiner.json

echo -e "${GREEN}✅ Keyboard config applied!${NC}"
echo -e "${YELLOW}⚠️  Grant permissions when prompted:${NC}"
echo -e "   System Settings → Privacy & Security → Input Monitoring"
echo ""

open -a "Karabiner-Elements" 2>/dev/null || true
echo -e "${GREEN}✅ Keyboard done! Your Ctrl+C/V/Z/S shortcuts now work like a PC.${NC}"

# VS Code
echo ""
if [ -d "/Applications/Visual Studio Code.app" ]; then
    echo -e "${GREEN}✅ VS Code already installed${NC}"
else
    echo -e "${BLUE}Installing Visual Studio Code...${NC}"
    brew install --cask visual-studio-code 2>&1 | tail -5
    echo -e "${GREEN}✅ VS Code installed${NC}"
fi

echo -e "${GREEN}✅ All done! 🎉${NC}"
