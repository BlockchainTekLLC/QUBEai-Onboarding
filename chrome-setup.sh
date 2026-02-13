#!/bin/bash
# Quick Google Chrome install + CDP setup for OpenClaw
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "\n${BOLD}🌐 Google Chrome + CDP Setup${NC}\n"

# Check brew
if ! command -v brew &>/dev/null; then
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi
if ! command -v brew &>/dev/null; then
    echo -e "${BLUE}Homebrew not found. Please install Homebrew first.${NC}"
    exit 1
fi

# Install Chrome
if [ -d "/Applications/Google Chrome.app" ]; then
    echo -e "${GREEN}✅ Google Chrome already installed${NC}"
else
    echo -e "${BLUE}Installing Google Chrome...${NC}"
    brew install --cask google-chrome 2>&1 | tail -5
    if [ -d "/Applications/Google Chrome.app" ]; then
        echo -e "${GREEN}✅ Google Chrome installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Chrome may need manual install from https://google.com/chrome${NC}"
    fi
fi

# CDP is configured in OpenClaw's config (port 9222)
# OpenClaw manages launching Chrome with --remote-debugging-port automatically
# No manual Chrome flags needed

echo ""
echo -e "${GREEN}✅ Chrome is ready for OpenClaw browser automation (CDP port 9222)${NC}"
echo -e "${BLUE}ℹ️  OpenClaw handles the CDP connection automatically — no manual config needed${NC}"
