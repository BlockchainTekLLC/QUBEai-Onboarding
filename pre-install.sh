#!/bin/bash
# ============================================================
# QUBEai Pre-Install: Keyboard + Claude Code Setup
# Run this FIRST if you have a PC keyboard and/or need a
# Claude API setup token before the main install.
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
step() { echo -e "\n${BOLD}${CYAN}▶ $1${NC}"; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}🐾 QUBEai Pre-Install Setup${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  Keyboard + Claude Code                   ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
info "This script gets your Mac ready for the full QUBEai install."
info "It handles two things: PC keyboard support & Claude Code setup."
echo ""

HOME_DIR="$HOME"

# ============================================================
# Step 1: Xcode Command Line Tools (needed for Homebrew)
# ============================================================
step "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools (this may take a few minutes)..."
    xcode-select --install
    echo ""
    echo -e "${YELLOW}A dialog should have appeared. Click 'Install' and wait for it to finish.${NC}"
    read -p "Press Enter when the installation is complete... "
else
    log "Xcode CLT already installed"
fi

# ============================================================
# Step 2: Homebrew (needed for Karabiner)
# ============================================================
step "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew (the macOS package manager)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for Apple Silicon
    if [ -f /opt/homebrew/bin/brew ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME_DIR}/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log "Homebrew installed"
else
    log "Homebrew already installed"
fi

# ============================================================
# Step 3: PC Keyboard Setup (Karabiner-Elements)
# ============================================================
echo ""
read -p "$(echo -e ${BOLD})Are you using a PC/Windows keyboard (not a Mac keyboard)? (y/N): $(echo -e ${NC})" PC_KEYBOARD
PC_KEYBOARD=${PC_KEYBOARD:-n}

if [[ "$PC_KEYBOARD" == [yY]* ]]; then
    step "Setting up PC keyboard support..."

    # Install Karabiner-Elements
    if [ -d "/Applications/Karabiner-Elements.app" ]; then
        log "Karabiner-Elements already installed"
    else
        info "Installing Karabiner-Elements (keyboard remapping tool)..."
        brew install --cask karabiner-elements 2>&1 | tail -5 || warn "Karabiner install had issues"
    fi

    # Apply PC keyboard config
    KARABINER_DIR="${HOME_DIR}/.config/karabiner"
    mkdir -p "${KARABINER_DIR}"
    KARABINER_URL="https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/assets/karabiner/karabiner.json"
    if curl -fsSL "${KARABINER_URL}" -o "${KARABINER_DIR}/karabiner.json" 2>/dev/null; then
        log "PC keyboard mappings installed!"
        echo ""
        info "Your PC keyboard shortcuts now work like you'd expect:"
        info "  Ctrl+C/V/X  →  Copy/Paste/Cut"
        info "  Ctrl+Z/Y    →  Undo/Redo"
        info "  Ctrl+S      →  Save"
        info "  Ctrl+T/W    →  New tab/Close tab"
        info "  Alt+Tab     →  Switch apps"
        info "  PrintScreen →  Screenshot"
        echo ""
        warn "IMPORTANT: You may need to grant Karabiner permissions:"
        info "  1. Open System Settings → Privacy & Security → Input Monitoring"
        info "  2. Enable 'karabiner_grabber' and 'karabiner_observer'"
        info "  3. You may also need to allow it in Accessibility"
        echo ""

        # Launch Karabiner so it can request permissions
        if [ -d "/Applications/Karabiner-Elements.app" ]; then
            info "Launching Karabiner-Elements (it will ask for permissions)..."
            open -a "Karabiner-Elements" 2>/dev/null || true
            echo ""
            read -p "Grant the permissions when prompted, then press Enter to continue... "
        fi
    else
        warn "Could not download keyboard config. You can set it up manually later."
    fi
else
    log "Skipping keyboard setup (Mac keyboard detected)"
fi

# ============================================================
# Step 4: Install Telegram & Create Bot
# ============================================================
step "Setting up Telegram..."

# Install Telegram Desktop
if [ -d "/Applications/Telegram.app" ]; then
    log "Telegram Desktop already installed"
else
    info "Installing Telegram Desktop..."
    brew install --cask telegram 2>&1 | tail -5 || warn "Telegram install had issues"
    if [ -d "/Applications/Telegram.app" ]; then
        log "Telegram Desktop installed"
    else
        warn "Telegram may need manual install from https://macos.telegram.org"
    fi
fi

# Guide through bot creation
echo ""
echo -e "${BOLD}${CYAN}━━━ Telegram Bot Setup ━━━${NC}"
echo ""
echo -e "  We need to create a Telegram bot for your AI assistant."
echo -e "  This takes about 60 seconds. Here's what to do:"
echo ""
echo -e "  ${BOLD}1.${NC} Open Telegram (we'll launch it for you)"
echo -e "  ${BOLD}2.${NC} We'll open a chat with @BotFather (Telegram's bot creator)"
echo -e "  ${BOLD}3.${NC} Send: ${CYAN}/newbot${NC}"
echo -e "  ${BOLD}4.${NC} Choose a ${BOLD}display name${NC} for your bot (e.g., 'My AI Assistant')"
echo -e "  ${BOLD}5.${NC} Choose a ${BOLD}username${NC} ending in 'bot' (e.g., 'jetts_ai_bot')"
echo -e "  ${BOLD}6.${NC} BotFather will give you a ${BOLD}token${NC} — copy it!"
echo ""

# Launch Telegram
if [ -d "/Applications/Telegram.app" ]; then
    read -p "$(echo -e ${BOLD})Press Enter to open Telegram and BotFather... $(echo -e ${NC})"
    open -a "Telegram" 2>/dev/null || true
    sleep 2
    open "https://t.me/BotFather" 2>/dev/null || true
fi

echo ""
echo -e "${YELLOW}After you create the bot, paste the token below.${NC}"
echo -e "${YELLOW}It looks like: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz${NC}"
echo ""
read -s -p "$(echo -e ${BOLD})Paste your bot token here: $(echo -e ${NC})" BOT_TOKEN
echo ""

if [ -n "$BOT_TOKEN" ]; then
    # Save token for the main install script to pick up
    mkdir -p "${HOME_DIR}/.qubeai"
    echo "$BOT_TOKEN" > "${HOME_DIR}/.qubeai/bot-token"
    chmod 600 "${HOME_DIR}/.qubeai/bot-token"
    log "Bot token saved securely"
else
    warn "No token entered — you'll need it during the main install"
fi

# Get Telegram user info
echo ""
echo -e "${BOLD}${CYAN}━━━ Your Telegram Info ━━━${NC}"
echo ""
echo -e "  We also need YOUR Telegram username and user ID."
echo -e "  To get your user ID:"
echo -e "    1. Open this link: ${CYAN}https://t.me/userinfobot${NC}"
echo -e "    2. Send ${CYAN}/start${NC}"
echo -e "    3. It will reply with your numeric ID"
echo ""
open "https://t.me/userinfobot" 2>/dev/null || true

read -p "$(echo -e ${BOLD})Your Telegram @username (e.g., @jett): $(echo -e ${NC})" TG_USERNAME
[[ -n "$TG_USERNAME" && "$TG_USERNAME" != @* ]] && TG_USERNAME="@$TG_USERNAME"

read -p "$(echo -e ${BOLD})Your Telegram numeric user ID: $(echo -e ${NC})" TG_USERID
if [[ -n "$TG_USERID" && ! "$TG_USERID" =~ ^[0-9]+$ ]]; then
    warn "That doesn't look like a numeric ID — double-check with @userinfobot"
fi

# Save for main install
if [ -n "$TG_USERNAME" ]; then
    echo "$TG_USERNAME" > "${HOME_DIR}/.qubeai/tg-username"
    echo "$TG_USERID" > "${HOME_DIR}/.qubeai/tg-userid"
    log "Telegram info saved"
fi

# ============================================================
# Step 5: Install Claude Code
# ============================================================
step "Installing Claude Code..."
if command -v claude &>/dev/null; then
    log "Claude Code already installed"
else
    info "Downloading and installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash

    # Ensure ~/.local/bin is in PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME_DIR}/.zshrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v claude &>/dev/null; then
        log "Claude Code installed"
    else
        warn "Claude Code installed but may need a terminal restart"
        info "Try closing and reopening Terminal, then run: claude"
        exit 0
    fi
fi

# ============================================================
# Step 5: Get Claude Setup Token
# ============================================================
step "Setting up Claude authentication..."
echo ""
info "Claude Code needs to authenticate with your Anthropic account."
info "When you run 'claude' it will open a browser window."
echo ""
echo -e "${BOLD}Instructions:${NC}"
echo -e "  1. A browser will open for authentication"
echo -e "  2. Log in to your Anthropic/Claude account"
echo -e "  3. Authorize the connection"
echo -e "  4. Copy the ${BOLD}API key${NC} from your Anthropic dashboard"
echo -e "     (https://console.anthropic.com/settings/keys)"
echo -e "  5. You'll need this key for the main QUBEai install"
echo ""
read -p "$(echo -e ${BOLD})Ready to authenticate Claude? (y/N): $(echo -e ${NC})" DO_AUTH

if [[ "$DO_AUTH" == [yY]* ]]; then
    info "Launching Claude Code... Follow the prompts in the terminal."
    echo ""
    claude
else
    info "You can run 'claude' anytime to set up authentication."
fi

# ============================================================
# Done!
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}🎉 Pre-Install Complete!${NC}                  ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Next step:${NC} Run the main QUBEai installer:"
echo ""
echo -e "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/install-macos.sh | bash${NC}"
echo ""
info "You'll need your Anthropic API key and Telegram bot token ready."
log "You're all set for the main install! 🚀"
