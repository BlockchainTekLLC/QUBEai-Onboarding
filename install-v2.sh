#!/bin/bash
# ============================================================
# QUBEai Installer v2
# Uses OpenClaw's built-in wizard (non-interactive) + config overlay
# Download then run:
#   curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/install-v2.sh -o install.sh
#   chmod +x install.sh && ./install.sh
# ============================================================

set -e

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
step() { echo -e "\n${BOLD}${CYAN}▶ $1${NC}"; }

# Sanitize pasted input
sanitize() { echo "$1" | tr -d '\n\r\t ' ; }

# TTY check
if [ ! -t 0 ]; then
    echo "❌ This script needs interactive input."
    echo "   curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/install-v2.sh -o install.sh"
    echo "   chmod +x install.sh && ./install.sh"
    exit 1
fi

# macOS check
[[ "$(uname)" != "Darwin" ]] && err "This script is for macOS only."

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}🐾 QUBEai Installer v2${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  Powered by OpenClaw Wizard              ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

HOME_DIR="$HOME"
OPENCLAW_DIR="${HOME_DIR}/.openclaw"
REPO_URL="https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master"

# ============================================================
# Collect ALL user input upfront
# ============================================================
step "Let's configure your QUBEai assistant"
echo ""

read -p "$(echo -e ${BOLD})Agent name (e.g., jett, assistant): $(echo -e ${NC})" AGENT_NAME
AGENT_NAME="${AGENT_NAME:-assistant}"
AGENT_NAME=$(echo "$AGENT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Anthropic API Key
echo ""
info "You need an Anthropic API key from https://console.anthropic.com/settings/keys"
read -s -p "$(echo -e ${BOLD})Anthropic API key: $(echo -e ${NC})" ANTHROPIC_KEY
echo ""
ANTHROPIC_KEY=$(sanitize "$ANTHROPIC_KEY")
[ -z "$ANTHROPIC_KEY" ] && err "Anthropic API key is required"
if [[ "$ANTHROPIC_KEY" =~ ^sk-ant- ]]; then
    info "API key: sk-ant-****${ANTHROPIC_KEY: -4} ✓"
else
    warn "Key doesn't start with 'sk-ant-' — double-check it's correct"
fi

# Telegram Bot Token
echo ""
info "Create a bot via @BotFather on Telegram, then paste the token"
read -s -p "$(echo -e ${BOLD})Telegram bot token: $(echo -e ${NC})" TELEGRAM_TOKEN
echo ""
TELEGRAM_TOKEN=$(sanitize "$TELEGRAM_TOKEN")
[ -z "$TELEGRAM_TOKEN" ] && err "Telegram bot token is required"
if [[ "$TELEGRAM_TOKEN" =~ ^[0-9]+: ]]; then
    info "Bot token: ****${TELEGRAM_TOKEN: -4} ✓"
else
    warn "Token doesn't match expected format (123456789:ABC...)"
fi

# Telegram Username
read -p "$(echo -e ${BOLD})Your Telegram @username: $(echo -e ${NC})" TELEGRAM_USER
TELEGRAM_USER=$(echo "$TELEGRAM_USER" | tr -d '\n\r\t ')
[ -z "$TELEGRAM_USER" ] && err "Telegram username is required"
[[ "$TELEGRAM_USER" != @* ]] && TELEGRAM_USER="@$TELEGRAM_USER"

# Telegram User ID
info "Get your ID from @userinfobot on Telegram"
read -p "$(echo -e ${BOLD})Your Telegram numeric user ID: $(echo -e ${NC})" TELEGRAM_ID
TELEGRAM_ID=$(sanitize "$TELEGRAM_ID")
[ -z "$TELEGRAM_ID" ] && err "Telegram user ID is required"
[[ ! "$TELEGRAM_ID" =~ ^[0-9]+$ ]] && err "Must be numeric (got: $TELEGRAM_ID)"

# Timezone
read -p "$(echo -e ${BOLD})Timezone (default: America/Chicago): $(echo -e ${NC})" TIMEZONE
TIMEZONE="${TIMEZONE:-America/Chicago}"

# Model
read -p "$(echo -e ${BOLD})Model (default: anthropic/claude-opus-4-6): $(echo -e ${NC})" MODEL
MODEL="${MODEL:-anthropic/claude-opus-4-6}"

# OpenAI (optional)
echo ""
read -p "$(echo -e ${BOLD})Do you have an OpenAI/Codex subscription? (y/N): $(echo -e ${NC})" HAS_OPENAI
HAS_OPENAI=${HAS_OPENAI:-n}

# Brave Search (optional)
read -p "$(echo -e ${BOLD})Brave Search API key (optional, press Enter to skip): $(echo -e ${NC})" BRAVE_KEY
BRAVE_KEY=$(sanitize "$BRAVE_KEY")

# ElevenLabs TTS (optional)
read -p "$(echo -e ${BOLD})ElevenLabs API key for TTS (optional, press Enter to skip): $(echo -e ${NC})" ELEVENLABS_KEY
ELEVENLABS_KEY=$(sanitize "$ELEVENLABS_KEY")

# PC Keyboard
echo ""
read -p "$(echo -e ${BOLD})Using a PC/Windows keyboard? (y/N): $(echo -e ${NC})" PC_KEYBOARD
PC_KEYBOARD=${PC_KEYBOARD:-n}

# Confirm
echo ""
echo -e "${BOLD}━━━ Summary ━━━${NC}"
info "Agent: ${AGENT_NAME} | Model: ${MODEL} | TZ: ${TIMEZONE}"
info "Telegram: ${TELEGRAM_USER} (${TELEGRAM_ID})"
[[ "$PC_KEYBOARD" == [yY]* ]] && info "PC Keyboard: Yes (Karabiner)"
[[ -n "$BRAVE_KEY" ]] && info "Brave Search: configured"
[[ -n "$ELEVENLABS_KEY" ]] && info "ElevenLabs TTS: configured"
echo ""
read -p "Proceed? (y/N) " CONFIRM
[[ "$CONFIRM" != [yY]* ]] && { echo "Aborted."; exit 0; }

# ============================================================
# Step 1: Prerequisites
# ============================================================
step "Installing prerequisites..."

# Homebrew
if ! command -v brew &>/dev/null; then
    if [ -f /opt/homebrew/bin/brew ]; then
        info "Adding Homebrew to PATH..."
        echo >> "${HOME_DIR}/.zprofile"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "${HOME_DIR}/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    else
        info "Installing Homebrew (you may be asked for your password)..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -f /opt/homebrew/bin/brew ]; then
            echo >> "${HOME_DIR}/.zprofile"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "${HOME_DIR}/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv zsh)"
        fi
    fi
fi
command -v brew &>/dev/null && log "Homebrew ready" || err "Homebrew not found"

# Node.js
if ! command -v node &>/dev/null; then
    info "Installing Node.js..."
    brew install node
fi
log "Node.js $(node --version)"

# Karabiner (if PC keyboard)
if [[ "$PC_KEYBOARD" == [yY]* ]]; then
    if [ ! -d "/Applications/Karabiner-Elements.app" ]; then
        info "Installing Karabiner-Elements..."
        brew install --cask karabiner-elements 2>&1 | tail -3
    fi
    mkdir -p ~/.config/karabiner
    curl -fsSL "${REPO_URL}/assets/karabiner/karabiner.json" -o ~/.config/karabiner/karabiner.json 2>/dev/null
    log "PC keyboard configured"
    open -a "Karabiner-Elements" 2>/dev/null || true
fi

# Chrome
if [ ! -d "/Applications/Google Chrome.app" ]; then
    info "Installing Google Chrome..."
    brew install --cask google-chrome 2>&1 | tail -3
fi
log "Google Chrome ready"

# VS Code
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    info "Installing VS Code..."
    brew install --cask visual-studio-code 2>&1 | tail -3
fi
log "VS Code ready"

# ============================================================
# Step 2: Install OpenClaw
# ============================================================
step "Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash 2>&1 | tail -5
# Ensure in PATH
export PATH="/opt/homebrew/bin:${HOME}/.local/bin:${PATH}"
command -v openclaw &>/dev/null && log "OpenClaw $(openclaw --version 2>/dev/null)" || err "OpenClaw not found"

# ============================================================
# Step 3: Run OpenClaw Wizard (non-interactive)
# ============================================================
step "Running OpenClaw onboarding wizard..."

export ANTHROPIC_API_KEY="${ANTHROPIC_KEY}"

openclaw onboard --non-interactive \
    --mode local \
    --auth-choice apiKey \
    --anthropic-api-key "${ANTHROPIC_KEY}" \
    --gateway-port 18789 \
    --gateway-bind loopback \
    --install-daemon \
    --daemon-runtime node \
    --skip-skills

log "OpenClaw wizard complete"

# ============================================================
# Step 4: Apply QUBEai config overlay
# ============================================================
step "Applying QUBEai configuration..."

# Read the gateway token that the wizard generated
GATEWAY_TOKEN=$(python3 -c "
import json
with open('${OPENCLAW_DIR}/openclaw.json') as f:
    c = json.load(f)
print(c.get('gateway', {}).get('auth', {}).get('token', ''))
" 2>/dev/null)

# Build brave search config
BRAVE_CONFIG=""
if [ -n "$BRAVE_KEY" ]; then
    BRAVE_CONFIG="\"search\": { \"enabled\": true, \"provider\": \"brave\", \"apiKey\": \"${BRAVE_KEY}\" },"
else
    BRAVE_CONFIG="\"search\": { \"enabled\": false },"
fi

# Build TTS config
TTS_CONFIG=""
if [ -n "$ELEVENLABS_KEY" ]; then
    TTS_CONFIG="\"tts\": {
        \"auto\": \"always\",
        \"mode\": \"final\",
        \"provider\": \"elevenlabs\",
        \"elevenlabs\": {
            \"apiKey\": \"${ELEVENLABS_KEY}\",
            \"voiceId\": \"NHRgOEwqx5WZNClv5sat\",
            \"modelId\": \"eleven_turbo_v2_5\"
        }
    }"
fi

# Create workspace directories
mkdir -p "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}"
mkdir -p "${OPENCLAW_DIR}/agents/${AGENT_NAME}/agent"

# Apply the full QUBEai config
python3 -c "
import json, os

config_path = '${OPENCLAW_DIR}/openclaw.json'
with open(config_path) as f:
    c = json.load(f)

# Browser
c['browser'] = {
    'enabled': True,
    'executablePath': '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    'headless': False,
    'noSandbox': False,
    'defaultProfile': 'openclaw',
    'profiles': {
        'openclaw': { 'cdpPort': 9222, 'color': '#4A90D9' }
    }
}

# Agent defaults
c.setdefault('agents', {})
c['agents']['defaults'] = {
    'model': { 'primary': '${MODEL}', 'fallbacks': [] },
    'workspace': '${OPENCLAW_DIR}/workspaces',
    'compaction': { 'mode': 'safeguard' },
    'elevatedDefault': 'full',
    'maxConcurrent': 4,
    'subagents': { 'maxConcurrent': 4 },
    'sandbox': { 'mode': 'off' }
}

# Agent list
c['agents']['list'] = [
    { 'id': 'main' },
    {
        'id': '${AGENT_NAME}',
        'name': '${AGENT_NAME}',
        'workspace': '${OPENCLAW_DIR}/workspaces/${AGENT_NAME}',
        'agentDir': '${OPENCLAW_DIR}/agents/${AGENT_NAME}/agent',
        'model': '${MODEL}',
        'heartbeat': {
            'every': '30m',
            'activeHours': { 'timezone': '${TIMEZONE}' },
            'target': 'telegram',
            'to': '${TELEGRAM_ID}'
        },
        'subagents': { 'allowAgents': ['*'] },
        'sandbox': {
            'mode': 'off',
            'workspaceAccess': 'rw',
            'workspaceRoot': '${OPENCLAW_DIR}/workspaces/${AGENT_NAME}'
        },
        'tools': {
            'profile': 'full',
            'elevated': {
                'enabled': True,
                'allowFrom': { 'telegram': ['${TELEGRAM_USER}'] }
            }
        }
    }
]

# Tools
c['tools'] = {
    'profile': 'full',
    'web': {
        'search': { 'enabled': bool('${BRAVE_KEY}'), 'provider': 'brave', 'apiKey': '${BRAVE_KEY}' } if '${BRAVE_KEY}' else { 'search': { 'enabled': False } },
        'fetch': { 'enabled': True }
    },
    'elevated': {
        'enabled': True,
        'allowFrom': { 'telegram': ['${TELEGRAM_USER}'] }
    },
    'exec': {
        'host': 'sandbox',
        'security': 'full',
        'ask': 'off'
    }
}

# Bindings
c['bindings'] = [
    { 'agentId': '${AGENT_NAME}', 'match': { 'channel': 'telegram' } }
]

# Telegram channel
c['channels'] = {
    'telegram': {
        'enabled': True,
        'configWrites': True,
        'dmPolicy': 'pairing',
        'botToken': '${TELEGRAM_TOKEN}',
        'allowFrom': ['${TELEGRAM_USER}', ${TELEGRAM_ID}],
        'groupPolicy': 'allowlist',
        'chunkMode': 'length',
        'blockStreaming': False,
        'streamMode': 'partial'
    }
}

# Messages
msgs = c.setdefault('messages', {})
msgs['ackReactionScope'] = 'group-mentions'

# TTS
elevenlabs_key = '${ELEVENLABS_KEY}'
if elevenlabs_key:
    msgs['tts'] = {
        'auto': 'always',
        'mode': 'final',
        'provider': 'elevenlabs',
        'elevenlabs': {
            'apiKey': elevenlabs_key,
            'voiceId': 'NHRgOEwqx5WZNClv5sat',
            'modelId': 'eleven_turbo_v2_5'
        }
    }

# Commands
c['commands'] = { 'native': 'auto', 'nativeSkills': 'auto', 'bash': True }

# Cron
c['cron'] = { 'enabled': True }

# Plugins
c['plugins'] = { 'entries': { 'telegram': { 'enabled': True } } }

# Write
with open(config_path, 'w') as f:
    json.dump(c, f, indent=2)

print('Config patched successfully')
"

log "QUBEai config applied"

# ============================================================
# Step 5: Create workspace files
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
MEMEOF

cat > "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/IDENTITY.md" <<IDEOF
# Identity

Name: ${AGENT_NAME}
Role: Personal AI Assistant
IDEOF

cat > "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/USER.md" <<USREOF
# About Your Human

- **Telegram:** ${TELEGRAM_USER}
- **Timezone:** ${TIMEZONE}
USREOF

log "Workspace files created"

# ============================================================
# Step 6: OpenAI/Codex (optional)
# ============================================================
if [[ "$HAS_OPENAI" == [yY]* ]]; then
    step "Setting up OpenAI Codex..."
    info "Run this after install to authenticate:"
    echo -e "  ${CYAN}openclaw onboard --auth-choice openai-codex-oauth${NC}"
fi

# ============================================================
# Step 7: Restart Gateway
# ============================================================
step "Starting OpenClaw..."

openclaw gateway stop 2>/dev/null || true
sleep 2
openclaw gateway start &
sleep 5

if openclaw gateway status 2>/dev/null | grep -qi "running\|online\|ok"; then
    log "OpenClaw gateway is running! 🎉"
else
    warn "Gateway may need manual start: openclaw gateway start"
fi

# ============================================================
# Step 8: Verification
# ============================================================
step "Verifying installation..."

CHECKS=0; TOTAL=5
if command -v openclaw &>/dev/null; then log "OpenClaw binary: OK"; CHECKS=$((CHECKS+1)); else warn "OpenClaw: NOT FOUND"; fi
if command -v node &>/dev/null; then log "Node.js: OK ($(node --version))"; CHECKS=$((CHECKS+1)); else warn "Node.js: NOT FOUND"; fi
if [ -f "${OPENCLAW_DIR}/openclaw.json" ]; then log "Config: OK"; CHECKS=$((CHECKS+1)); else warn "Config: MISSING"; fi
if [ -d "${OPENCLAW_DIR}/workspaces/${AGENT_NAME}" ]; then log "Workspace: OK"; CHECKS=$((CHECKS+1)); else warn "Workspace: MISSING"; fi
if [ -d "/Applications/Google Chrome.app" ]; then log "Chrome: OK"; CHECKS=$((CHECKS+1)); else warn "Chrome: MISSING"; fi

echo ""
if [ "$CHECKS" -eq "$TOTAL" ]; then
    log "All ${TOTAL}/${TOTAL} checks passed! ✨"
else
    warn "${CHECKS}/${TOTAL} checks passed"
fi

# ============================================================
# Done!
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}🎉 QUBEai Installation Complete!${NC}         ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Agent:${NC}     ${AGENT_NAME}"
echo -e "  ${BOLD}Model:${NC}     ${MODEL}"
echo -e "  ${BOLD}Telegram:${NC}  ${TELEGRAM_USER}"
echo -e "  ${BOLD}Config:${NC}    ${OPENCLAW_DIR}/openclaw.json"
echo -e "  ${BOLD}Workspace:${NC} ${OPENCLAW_DIR}/workspaces/${AGENT_NAME}/"
echo ""
echo -e "  ${BOLD}Next:${NC} Message your Telegram bot to start chatting! 🐾"
echo ""
echo -e "  ${BOLD}Commands:${NC}"
echo -e "    ${CYAN}openclaw gateway status${NC}    — Check status"
echo -e "    ${CYAN}openclaw gateway restart${NC}   — Restart"
echo -e "    ${CYAN}openclaw dashboard${NC}         — Open Control UI"
echo ""
log "You're all set! 🚀"
