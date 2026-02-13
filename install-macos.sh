#!/bin/bash
# ============================================================
# OpenClaw macOS Installer
# Single-agent setup with Google services, elevated permissions
# No sandbox — full access
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

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}🐾 OpenClaw macOS Installer${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Single Agent • Google Services • Full   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

log()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
step() { echo -e "\n${BOLD}${CYAN}▶ $1${NC}"; }

print_banner

# ============================================================
# Pre-flight checks
# ============================================================
step "Running pre-flight checks..."

# Must be macOS
[[ "$(uname)" != "Darwin" ]] && err "This script is for macOS only. Use install-ubuntu.sh for Linux."

# Must have internet
if ! curl -sf --max-time 5 https://registry.npmjs.org/ > /dev/null 2>&1; then
    err "No internet connection detected. Please check your network and try again."
fi
log "macOS detected, internet connection OK"

# Check disk space (need ~2GB)
AVAIL_GB=$(df -g "$HOME" | awk 'NR==2 {print $4}')
if [ "$AVAIL_GB" -lt 2 ] 2>/dev/null; then
    warn "Low disk space (${AVAIL_GB}GB free). At least 2GB recommended."
fi

# ============================================================
# Gather info upfront
# ============================================================
step "Let's configure your OpenClaw instance"

echo ""
read -p "$(echo -e ${BOLD})Agent name (e.g., jett, assistant): $(echo -e ${NC})" AGENT_NAME
AGENT_NAME="${AGENT_NAME:-assistant}"
AGENT_NAME=$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

read -s -p "$(echo -e ${BOLD})Anthropic API key: $(echo -e ${NC})" ANTHROPIC_KEY
echo ""
[ -z "$ANTHROPIC_KEY" ] && err "Anthropic API key is required"

# Check for saved values from pre-install
SAVED_TOKEN=""
SAVED_USERNAME=""
SAVED_USERID=""
[ -f "${HOME}/.qubeai/bot-token" ] && SAVED_TOKEN=$(cat "${HOME}/.qubeai/bot-token")
[ -f "${HOME}/.qubeai/tg-username" ] && SAVED_USERNAME=$(cat "${HOME}/.qubeai/tg-username")
[ -f "${HOME}/.qubeai/tg-userid" ] && SAVED_USERID=$(cat "${HOME}/.qubeai/tg-userid")

if [ -n "$SAVED_TOKEN" ]; then
    info "Found saved bot token from pre-install"
    TELEGRAM_TOKEN="$SAVED_TOKEN"
else
    read -s -p "$(echo -e ${BOLD})Telegram bot token (from @BotFather): $(echo -e ${NC})" TELEGRAM_TOKEN
    echo ""
fi
[ -z "$TELEGRAM_TOKEN" ] && err "Telegram bot token is required"

if [ -n "$SAVED_USERNAME" ]; then
    info "Found saved Telegram username: ${SAVED_USERNAME}"
    TELEGRAM_USER="$SAVED_USERNAME"
else
    read -p "$(echo -e ${BOLD})Your Telegram @username (e.g., @willmkultra): $(echo -e ${NC})" TELEGRAM_USER
fi
[ -z "$TELEGRAM_USER" ] && err "Telegram username is required"
# Ensure @ prefix
[[ "$TELEGRAM_USER" != @* ]] && TELEGRAM_USER="@$TELEGRAM_USER"

if [ -n "$SAVED_USERID" ]; then
    info "Found saved Telegram user ID: ${SAVED_USERID}"
    TELEGRAM_ID="$SAVED_USERID"
else
    read -p "$(echo -e ${BOLD})Your Telegram numeric user ID (send /start to @userinfobot to find it): $(echo -e ${NC})" TELEGRAM_ID
fi
[ -z "$TELEGRAM_ID" ] && err "Telegram user ID is required"
# Validate numeric
[[ ! "$TELEGRAM_ID" =~ ^[0-9]+$ ]] && err "Telegram user ID must be numeric (got: $TELEGRAM_ID)"

read -p "$(echo -e ${BOLD})Timezone (e.g., America/Chicago): $(echo -e ${NC})" TIMEZONE
TIMEZONE="${TIMEZONE:-America/Chicago}"

read -p "$(echo -e ${BOLD})Model (default: anthropic/claude-opus-4-6): $(echo -e ${NC})" MODEL
MODEL="${MODEL:-anthropic/claude-opus-4-6}"

echo ""
read -p "$(echo -e ${BOLD})Are you using a PC/Windows keyboard with this Mac? (y/N): $(echo -e ${NC})" PC_KEYBOARD
PC_KEYBOARD=${PC_KEYBOARD:-n}

echo ""
info "Agent: ${AGENT_NAME} | Model: ${MODEL} | TZ: ${TIMEZONE}"
info "Telegram: ${TELEGRAM_USER} (${TELEGRAM_ID})"
[[ "$PC_KEYBOARD" == [yY]* ]] && info "PC Keyboard: Will install Karabiner-Elements for key remapping"
echo ""
read -p "Proceed with installation? (y/N) " CONFIRM
[[ "$CONFIRM" != [yY]* ]] && { echo "Aborted."; exit 0; }

MAC_USER=$(whoami)
HOME_DIR=$(eval echo ~$MAC_USER)
OPENCLAW_DIR="${HOME_DIR}/.openclaw"

# ============================================================
# Step 1: Xcode Command Line Tools
# ============================================================
step "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press Enter after the installation completes..."
    read -r
else
    log "Xcode CLT already installed"
fi

# ============================================================
# Step 2: Homebrew
# ============================================================
step "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
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
# Step 3: Node.js
# ============================================================
step "Checking Node.js..."
if ! command -v node &>/dev/null; then
    info "Installing Node.js via Homebrew..."
    brew install node
    log "Node.js $(node --version) installed"
else
    NODE_VER=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_MAJOR" -lt 20 ]; then
        warn "Node.js $NODE_VER is too old (need v20+). Upgrading..."
        brew upgrade node
    fi
    log "Node.js $(node --version) ready"
fi

# ============================================================
# Step 4: Install Claude Code
# ============================================================
step "Installing Claude Code..."
if command -v claude &>/dev/null; then
    log "Claude Code already installed"
else
    curl -fsSL https://claude.ai/install.sh | bash
    # Ensure ~/.local/bin is in PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME_DIR}/.zshrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    if command -v claude &>/dev/null; then
        log "Claude Code installed"
    else
        warn "Claude Code installed but may need terminal restart to be in PATH"
    fi
fi

# ============================================================
# Step 5: Install OpenClaw
# ============================================================
step "Installing OpenClaw..."
npm install -g openclaw 2>&1 | tail -5
log "OpenClaw installed: $(openclaw --version 2>/dev/null || echo 'checking...')"

# ============================================================
# Step 6: Install gog (Google Workspace CLI)
# ============================================================
step "Installing gog (Google Workspace CLI)..."
brew install steipete/tap/gogcli 2>&1 | tail -3 || warn "gog install had issues — may already be installed"
if command -v gog &>/dev/null; then
    log "gog installed: $(gog --version 2>/dev/null || echo 'ready')"
else
    warn "gog not found in PATH — you may need to restart your terminal"
fi

# ============================================================
# Step 6b: Karabiner-Elements (PC Keyboard support)
# ============================================================
if [[ "$PC_KEYBOARD" == [yY]* ]]; then
    step "Setting up PC keyboard support (Karabiner-Elements)..."
    if [ -d "/Applications/Karabiner-Elements.app" ]; then
        log "Karabiner-Elements already installed"
    else
        info "Installing Karabiner-Elements..."
        brew install --cask karabiner-elements 2>&1 | tail -5 || warn "Karabiner install had issues"
        if [ -d "/Applications/Karabiner-Elements.app" ]; then
            log "Karabiner-Elements installed"
        else
            warn "Karabiner-Elements may need manual install from https://karabiner-elements.pqrs.org"
        fi
    fi

    # Apply PC keyboard config
    KARABINER_DIR="${HOME_DIR}/.config/karabiner"
    mkdir -p "${KARABINER_DIR}"
    KARABINER_URL="https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/assets/karabiner/karabiner.json"
    if curl -fsSL "${KARABINER_URL}" -o "${KARABINER_DIR}/karabiner.json" 2>/dev/null; then
        log "PC keyboard mappings applied (Ctrl→⌘ for copy/paste/save/etc.)"
        info "Mappings include: copy, cut, paste, undo, redo, save, tabs, screenshots, and more"
        info "You may need to grant Karabiner accessibility permissions in System Settings → Privacy & Security"
    else
        warn "Could not download keyboard config — you can manually copy from the QUBEai-Onboarding repo"
    fi
fi

# ============================================================
# Step 7: Create directory structure
# ============================================================
step "Setting up directory structure..."
mkdir -p "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}"
mkdir -p "${OPENCLAW_DIR}/agents/${AGENT_NAME}/agent"
log "Directories created"

# ============================================================
# Step 7: Configure Anthropic auth
# ============================================================
step "Configuring Anthropic authentication..."
mkdir -p "${OPENCLAW_DIR}/auth"

# Store the API key using openclaw's auth mechanism
cat > "${OPENCLAW_DIR}/auth/anthropic_default.json" <<AUTHEOF
{
  "provider": "anthropic",
  "mode": "token",
  "token": "${ANTHROPIC_KEY}"
}
AUTHEOF
chmod 600 "${OPENCLAW_DIR}/auth/anthropic_default.json"
log "Auth configured"

# ============================================================
# Step 8: Write OpenClaw config
# ============================================================
step "Writing OpenClaw configuration..."

cat > "${OPENCLAW_DIR}/openclaw.json" <<CFGEOF
{
  "env": {
    "shellEnv": { "enabled": true, "timeoutMs": 15000 }
  },
  "logging": {
    "level": "info",
    "consoleLevel": "info",
    "consoleStyle": "pretty",
    "redactSensitive": "tools"
  },
  "update": { "checkOnStart": true },
  "browser": {
    "enabled": true,
    "executablePath": "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "headless": false,
    "noSandbox": false,
    "defaultProfile": "openclaw",
    "profiles": {
      "openclaw": { "cdpPort": 9222 }
    }
  },
  "auth": {
    "profiles": {
      "anthropic:default": {
        "provider": "anthropic",
        "mode": "token"
      }
    }
  },
  "models": { "mode": "merge", "providers": {} },
  "agents": {
    "defaults": {
      "model": { "primary": "${MODEL}", "fallbacks": [] },
      "workspace": "${OPENCLAW_DIR}/workspaces",
      "compaction": { "mode": "safeguard" },
      "elevatedDefault": "full",
      "maxConcurrent": 4,
      "sandbox": { "mode": "off" }
    },
    "list": [
      { "id": "main" },
      {
        "id": "${AGENT_NAME}",
        "name": "${AGENT_NAME}",
        "workspace": "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}",
        "agentDir": "${OPENCLAW_DIR}/agents/${AGENT_NAME}/agent",
        "model": "${MODEL}",
        "heartbeat": {
          "every": "30m",
          "activeHours": { "timezone": "${TIMEZONE}" },
          "target": "telegram",
          "to": "${TELEGRAM_ID}"
        },
        "sandbox": {
          "mode": "off",
          "workspaceAccess": "rw",
          "workspaceRoot": "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}"
        },
        "tools": {
          "profile": "full",
          "elevated": {
            "enabled": true,
            "allowFrom": {
              "telegram": ["${TELEGRAM_USER}"]
            }
          }
        }
      }
    ]
  },
  "tools": {
    "profile": "full",
    "web": {
      "search": { "enabled": false },
      "fetch": { "enabled": true }
    },
    "elevated": {
      "enabled": true,
      "allowFrom": {
        "telegram": ["${TELEGRAM_USER}"]
      }
    },
    "exec": {
      "host": "sandbox",
      "security": "full",
      "ask": "off"
    }
  },
  "bindings": [
    {
      "agentId": "${AGENT_NAME}",
      "match": { "channel": "telegram" }
    }
  ],
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "bash": true
  },
  "cron": { "enabled": true },
  "channels": {
    "telegram": {
      "enabled": true,
      "configWrites": true,
      "dmPolicy": "pairing",
      "botToken": "${TELEGRAM_TOKEN}",
      "allowFrom": ["${TELEGRAM_USER}"],
      "groupPolicy": "allowlist",
      "chunkMode": "length",
      "blockStreaming": false,
      "streamMode": "partial"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "tailscale": { "mode": "off" },
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": true }
      }
    }
  },
  "plugins": {
    "entries": {
      "telegram": { "enabled": true }
    }
  }
}
CFGEOF

log "Config written to ${OPENCLAW_DIR}/openclaw.json"

# ============================================================
# Step 9: Create workspace files
# ============================================================
step "Creating workspace files..."

CREATED_DATE=$(date +%Y-%m-%d)
cat > "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/MEMORY.md" <<MEMEOF
# Memory

## Agent Identity
- **Name**: ${AGENT_NAME}
- **Created**: ${CREATED_DATE}

## Persistent Knowledge
(Will be populated as you interact)

## Key Preferences
(Add preferences as they're discovered)
MEMEOF

cat > "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/IDENTITY.md" <<IDEOF
# Identity

Name: ${AGENT_NAME}
Role: Personal Assistant

You are a helpful AI assistant running on OpenClaw.
IDEOF

cat > "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/USER.md" <<USREOF
# About Your Human

- **Telegram:** ${TELEGRAM_USER}
- **Timezone:** ${TIMEZONE}
USREOF

log "Workspace files created"

# ============================================================
# Step 10: Set up gog (Google Workspace)
# ============================================================
step "Google Workspace Setup (gog)"
echo ""
info "To connect Google services, you'll need a Google Cloud OAuth client."
info "Run these commands after installation:"
echo ""
echo -e "  ${CYAN}gog auth credentials /path/to/client_secret.json${NC}"
echo -e "  ${CYAN}gog auth add your@gmail.com --services gmail,calendar,drive,contacts,docs,sheets${NC}"
echo ""
info "See: https://gogcli.sh for setup guide"

# ============================================================
# Step 11: Create launchd service (auto-start)
# ============================================================
step "Setting up auto-start service..."

PLIST_PATH="${HOME_DIR}/Library/LaunchAgents/com.openclaw.gateway.plist"
OPENCLAW_BIN=$(which openclaw)

cat > "${PLIST_PATH}" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>${OPENCLAW_BIN}</string>
        <string>gateway</string>
        <string>start</string>
        <string>--foreground</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${OPENCLAW_DIR}/logs/gateway.out.log</string>
    <key>StandardErrorPath</key>
    <string>${OPENCLAW_DIR}/logs/gateway.err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>${HOME_DIR}</string>
    </dict>
</dict>
</plist>
PLISTEOF

mkdir -p "${OPENCLAW_DIR}/logs"
log "LaunchAgent created (auto-starts on login)"

# ============================================================
# Step 12: Store Anthropic key in environment
# ============================================================
step "Setting up API key..."

# Add to .zshrc if not already there
ZSHRC="${HOME_DIR}/.zshrc"
if ! grep -q "ANTHROPIC_API_KEY" "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo "# OpenClaw - Anthropic API Key" >> "$ZSHRC"
    echo "export ANTHROPIC_API_KEY=\"${ANTHROPIC_KEY}\"" >> "$ZSHRC"
    log "API key added to ~/.zshrc"
else
    warn "ANTHROPIC_API_KEY already in .zshrc — not overwriting"
fi

# Export for current session
export ANTHROPIC_API_KEY="${ANTHROPIC_KEY}"

# ============================================================
# Step 13: Start OpenClaw!
# ============================================================
step "Starting OpenClaw..."

# Load the service (bootstrap is the modern way, fall back to load)
launchctl bootstrap "gui/$(id -u)" "${PLIST_PATH}" 2>/dev/null || launchctl load "${PLIST_PATH}" 2>/dev/null || true
sleep 5

# Check if running
if openclaw gateway status 2>/dev/null | grep -qi "running\|online\|ok"; then
    log "OpenClaw gateway is running! 🎉"
else
    info "Trying direct start..."
    openclaw gateway start &
    sleep 5
    if openclaw gateway status 2>/dev/null | grep -qi "running\|online\|ok"; then
        log "OpenClaw gateway started!"
    else
        warn "Gateway may need manual start. Try: openclaw gateway start"
    fi
fi

# ============================================================
# Post-install verification
# ============================================================
step "Running post-install verification..."

CHECKS_PASSED=0
CHECKS_TOTAL=5

command -v openclaw &>/dev/null && { log "openclaw binary: OK"; ((CHECKS_PASSED++)); } || warn "openclaw binary: NOT FOUND"
command -v node &>/dev/null && { log "Node.js: OK ($(node --version))"; ((CHECKS_PASSED++)); } || warn "Node.js: NOT FOUND"
[ -f "${OPENCLAW_DIR}/openclaw.json" ] && { log "Config file: OK"; ((CHECKS_PASSED++)); } || warn "Config file: MISSING"
[ -f "${OPENCLAW_DIR}/auth/anthropic_default.json" ] && { log "Auth file: OK"; ((CHECKS_PASSED++)); } || warn "Auth file: MISSING"
[ -f "${PLIST_PATH}" ] && { log "LaunchAgent: OK"; ((CHECKS_PASSED++)); } || warn "LaunchAgent: MISSING"

echo ""
if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
    log "All ${CHECKS_TOTAL}/${CHECKS_TOTAL} checks passed! ✨"
else
    warn "${CHECKS_PASSED}/${CHECKS_TOTAL} checks passed — review warnings above"
fi

# ============================================================
# Done!
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}🎉 OpenClaw Installation Complete!${NC}       ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Agent:${NC}     ${AGENT_NAME}"
echo -e "  ${BOLD}Model:${NC}     ${MODEL}"
echo -e "  ${BOLD}Telegram:${NC}  ${TELEGRAM_USER}"
echo -e "  ${BOLD}Config:${NC}    ${OPENCLAW_DIR}/openclaw.json"
echo -e "  ${BOLD}Workspace:${NC} ${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/"
echo ""
echo -e "  ${BOLD}Commands:${NC}"
echo -e "    ${CYAN}openclaw gateway status${NC}   — Check status"
echo -e "    ${CYAN}openclaw gateway start${NC}    — Start gateway"
echo -e "    ${CYAN}openclaw gateway restart${NC}  — Restart gateway"
echo -e "    ${CYAN}openclaw gateway stop${NC}     — Stop gateway"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    1. Message your Telegram bot to start chatting!"
echo -e "    2. Set up Google services: ${CYAN}gog auth${NC}"
echo -e "    3. Config: ${CYAN}nano ${OPENCLAW_DIR}/openclaw.json${NC}"
echo ""
echo -e "  ${BOLD}Auto-start:${NC} OpenClaw will start automatically on login."
echo -e "  To disable: ${CYAN}launchctl bootout gui/\$(id -u) ~/Library/LaunchAgents/com.openclaw.gateway.plist${NC}"
echo ""
log "You're all set! Send a message to your bot on Telegram. 🐾"
