#!/bin/bash
# ============================================================
# QUBEai Installation Health Check
# Validates all components are installed and functioning
# Generates a report for customer support if issues found
# ============================================================

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Report vars
REPORT_DIR="/tmp/qubeai-healthcheck"
REPORT_FILE="${REPORT_DIR}/report.txt"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
TOTAL_COUNT=0
RESULTS=()

MAC_USER=$(whoami)
HOME_DIR=$(eval echo ~$MAC_USER)
OPENCLAW_DIR="${HOME_DIR}/.openclaw"
CONFIG_FILE="${OPENCLAW_DIR}/openclaw.json"

# ============================================================
# Helpers
# ============================================================
print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}🔍 QUBEai Installation Health Check${NC}         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Validating all components...                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

log_pass() {
    local test_name="$1"
    local detail="$2"
    echo -e "  ${GREEN}✅ PASS${NC}  ${test_name}"
    [ -n "$detail" ] && echo -e "         ${DIM}${detail}${NC}"
    RESULTS+=("PASS|${test_name}|${detail}")
    ((PASS_COUNT++))
    ((TOTAL_COUNT++))
}

log_fail() {
    local test_name="$1"
    local detail="$2"
    local verbose="$3"
    echo -e "  ${RED}❌ FAIL${NC}  ${test_name}"
    [ -n "$detail" ] && echo -e "         ${RED}${detail}${NC}"
    RESULTS+=("FAIL|${test_name}|${detail}|${verbose}")
    ((FAIL_COUNT++))
    ((TOTAL_COUNT++))
}

log_warn() {
    local test_name="$1"
    local detail="$2"
    echo -e "  ${YELLOW}⚠️  WARN${NC}  ${test_name}"
    [ -n "$detail" ] && echo -e "         ${YELLOW}${detail}${NC}"
    RESULTS+=("WARN|${test_name}|${detail}")
    ((WARN_COUNT++))
    ((TOTAL_COUNT++))
}

section() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ $1 ━━━${NC}"
    echo ""
}

# ============================================================
# Collect system info
# ============================================================
collect_system_info() {
    SYS_OS=$(sw_vers -productName 2>/dev/null || echo "Unknown")
    SYS_VER=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    SYS_ARCH=$(uname -m 2>/dev/null || echo "Unknown")
    SYS_HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
    SYS_USER=$(whoami)
    SYS_SHELL=$(echo $SHELL)
    SYS_DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $4 " available of " $2}' || echo "Unknown")
    SYS_MEM=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f GB", $1/1073741824}' || echo "Unknown")
}

# ============================================================
# Tests
# ============================================================
print_banner
collect_system_info

echo -e "${DIM}System: ${SYS_OS} ${SYS_VER} (${SYS_ARCH}) | User: ${SYS_USER} | RAM: ${SYS_MEM} | Disk: ${SYS_DISK}${NC}"

# --- Core Dependencies ---
section "Core Dependencies"

# Test: Homebrew
if command -v brew &>/dev/null; then
    BREW_VER=$(brew --version 2>/dev/null | head -1)
    log_pass "Homebrew" "${BREW_VER}"
else
    log_fail "Homebrew" "Not installed" "Homebrew is required for installing dependencies. Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

# Test: Node.js
if command -v node &>/dev/null; then
    NODE_VER=$(node --version 2>/dev/null)
    NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 20 ] 2>/dev/null; then
        log_pass "Node.js" "${NODE_VER} (>= v20 required)"
    else
        log_fail "Node.js" "Version ${NODE_VER} is too old (v20+ required)" "Run: brew upgrade node"
    fi
else
    log_fail "Node.js" "Not installed" "Run: brew install node"
fi

# Test: npm
if command -v npm &>/dev/null; then
    NPM_VER=$(npm --version 2>/dev/null)
    log_pass "npm" "v${NPM_VER}"
else
    log_fail "npm" "Not installed" "npm should come with Node.js. Reinstall Node."
fi

# Test: Git
if command -v git &>/dev/null; then
    GIT_VER=$(git --version 2>/dev/null)
    log_pass "Git" "${GIT_VER}"
else
    log_warn "Git" "Not installed (optional but recommended)"
fi

# Test: curl
if command -v curl &>/dev/null; then
    log_pass "curl" "Available"
else
    log_fail "curl" "Not installed" "curl is required. Install via: brew install curl"
fi

# --- OpenClaw ---
section "OpenClaw"

# Test: OpenClaw binary
if command -v openclaw &>/dev/null; then
    OC_VER=$(openclaw --version 2>/dev/null || echo "installed")
    log_pass "OpenClaw CLI" "${OC_VER}"
    OC_BIN_PATH=$(which openclaw)
else
    log_fail "OpenClaw CLI" "Command not found" "Install: npm install -g openclaw. If installed, check PATH includes npm global bin directory."
    OC_BIN_PATH=""
fi

# Test: OpenClaw config
if [ -f "$CONFIG_FILE" ]; then
    log_pass "OpenClaw config" "${CONFIG_FILE}"
    
    # Validate JSON
    if python3 -c "import json; json.load(open('${CONFIG_FILE}'))" 2>/dev/null; then
        log_pass "Config JSON valid" "Parsed successfully"
    else
        log_fail "Config JSON valid" "Invalid JSON in ${CONFIG_FILE}" "$(python3 -c "import json; json.load(open('${CONFIG_FILE}'))" 2>&1)"
    fi
else
    log_fail "OpenClaw config" "Not found at ${CONFIG_FILE}" "Run the installer again or create config manually."
fi

# Test: OpenClaw directories
for dir in "workspaces" "agents" "logs"; do
    if [ -d "${OPENCLAW_DIR}/${dir}" ]; then
        log_pass "Directory: ${dir}/" "Exists"
    else
        log_warn "Directory: ${dir}/" "Missing — will be created on first run"
    fi
done

# Test: Agent workspace
if [ -f "$CONFIG_FILE" ]; then
    AGENT_ID=$(python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)
agents = cfg.get('agents',{}).get('list',[])
for a in agents:
    if a.get('id') not in ('main',):
        print(a['id'])
        break
" 2>/dev/null)
    
    if [ -n "$AGENT_ID" ]; then
        log_pass "Agent configured" "ID: ${AGENT_ID}"
        
        AGENT_WS="${OPENCLAW_DIR}/workspaces/${AGENT_ID}"
        if [ -d "$AGENT_WS" ]; then
            log_pass "Agent workspace" "${AGENT_WS}"
        else
            log_fail "Agent workspace" "Directory missing: ${AGENT_WS}" "Create it: mkdir -p ${AGENT_WS}"
        fi
    else
        log_fail "Agent configured" "No agent found in config" "Re-run installer to configure an agent."
    fi
fi

# Test: Gateway status
if [ -n "$OC_BIN_PATH" ]; then
    GW_STATUS=$(openclaw gateway status 2>&1)
    if echo "$GW_STATUS" | grep -qi "running\|online\|ok\|listening"; then
        log_pass "Gateway running" "$(echo "$GW_STATUS" | head -1)"
    else
        log_fail "Gateway running" "Not running" "Start with: openclaw gateway start. Output: ${GW_STATUS}"
    fi
fi

# Test: LaunchAgent (auto-start)
PLIST="${HOME_DIR}/Library/LaunchAgents/com.openclaw.gateway.plist"
if [ -f "$PLIST" ]; then
    log_pass "Auto-start (LaunchAgent)" "Configured"
    if launchctl list 2>/dev/null | grep -q "com.openclaw.gateway"; then
        log_pass "Auto-start loaded" "Active in launchctl"
    else
        log_warn "Auto-start loaded" "Plist exists but not loaded — run: launchctl load ${PLIST}"
    fi
else
    log_warn "Auto-start (LaunchAgent)" "Not configured — OpenClaw won't start on reboot"
fi

# --- Telegram ---
section "Telegram"

if [ -f "$CONFIG_FILE" ]; then
    TG_ENABLED=$(python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)
tg = cfg.get('channels',{}).get('telegram',{})
print('true' if tg.get('enabled') else 'false')
" 2>/dev/null)
    
    if [ "$TG_ENABLED" = "true" ]; then
        log_pass "Telegram channel" "Enabled in config"
        
        # Check bot token is present (not the actual value)
        TG_HAS_TOKEN=$(python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)
token = cfg.get('channels',{}).get('telegram',{}).get('botToken','')
print('true' if token and len(token) > 10 else 'false')
" 2>/dev/null)
        
        if [ "$TG_HAS_TOKEN" = "true" ]; then
            log_pass "Telegram bot token" "Present in config"
        else
            log_fail "Telegram bot token" "Missing or empty" "Add your bot token from @BotFather to the config."
        fi
        
        # Check allowFrom
        TG_ALLOW=$(python3 -c "
import json
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)
allow = cfg.get('channels',{}).get('telegram',{}).get('allowFrom',[])
print(','.join(allow) if allow else '')
" 2>/dev/null)
        
        if [ -n "$TG_ALLOW" ]; then
            log_pass "Telegram allowFrom" "${TG_ALLOW}"
        else
            log_warn "Telegram allowFrom" "No users configured — bot won't respond to anyone"
        fi
    else
        log_fail "Telegram channel" "Not enabled in config" "Set channels.telegram.enabled = true in config."
    fi
else
    log_fail "Telegram channel" "Cannot check — config file missing"
fi

# --- Anthropic API ---
section "Anthropic API"

# Check environment variable
if [ -n "$ANTHROPIC_API_KEY" ]; then
    KEY_PREFIX=$(echo "$ANTHROPIC_API_KEY" | cut -c1-10)
    log_pass "API key (env)" "Set (${KEY_PREFIX}...)"
else
    # Check .zshrc
    if grep -q "ANTHROPIC_API_KEY" "${HOME_DIR}/.zshrc" 2>/dev/null; then
        log_warn "API key (env)" "Defined in .zshrc but not in current shell — restart terminal or run: source ~/.zshrc"
    else
        log_fail "API key (env)" "ANTHROPIC_API_KEY not set" "Add to ~/.zshrc: export ANTHROPIC_API_KEY=\"sk-ant-...\""
    fi
fi

# Check auth file
AUTH_FILE="${OPENCLAW_DIR}/auth/anthropic_default.json"
if [ -f "$AUTH_FILE" ]; then
    log_pass "API key (auth file)" "${AUTH_FILE} exists"
    
    # Check permissions
    PERMS=$(stat -f '%Lp' "$AUTH_FILE" 2>/dev/null || stat -c '%a' "$AUTH_FILE" 2>/dev/null)
    if [ "$PERMS" = "600" ]; then
        log_pass "Auth file permissions" "600 (secure)"
    else
        log_warn "Auth file permissions" "${PERMS} — should be 600. Fix: chmod 600 ${AUTH_FILE}"
    fi
else
    log_warn "API key (auth file)" "Not found at ${AUTH_FILE}"
fi

# Test API connectivity
if [ -n "$ANTHROPIC_API_KEY" ]; then
    API_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        "https://api.anthropic.com/v1/messages" \
        -X POST -d '{"model":"claude-sonnet-4-20250514","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' \
        -H "content-type: application/json" \
        --connect-timeout 10 2>/dev/null)
    
    if [ "$API_TEST" = "200" ]; then
        log_pass "Anthropic API connectivity" "API responded 200 OK"
    elif [ "$API_TEST" = "401" ]; then
        log_fail "Anthropic API connectivity" "HTTP 401 — Invalid API key" "Check your ANTHROPIC_API_KEY is correct."
    elif [ "$API_TEST" = "429" ]; then
        log_warn "Anthropic API connectivity" "HTTP 429 — Rate limited (key is valid, just throttled)"
    elif [ "$API_TEST" = "000" ]; then
        log_fail "Anthropic API connectivity" "Connection failed — no internet or API is down" "Check your internet connection."
    else
        log_warn "Anthropic API connectivity" "HTTP ${API_TEST} — unexpected response"
    fi
else
    log_warn "Anthropic API connectivity" "Skipped — no API key in environment"
fi

# --- Google Workspace (gog) ---
section "Google Workspace (gog)"

if command -v gog &>/dev/null; then
    GOG_VER=$(gog --version 2>/dev/null || echo "installed")
    log_pass "gog CLI" "${GOG_VER}"
    
    # Check auth
    GOG_AUTH=$(gog auth list 2>&1)
    if echo "$GOG_AUTH" | grep -q "@"; then
        GOG_ACCOUNT=$(echo "$GOG_AUTH" | grep "@" | head -1)
        log_pass "gog authenticated" "${GOG_ACCOUNT}"
    else
        log_warn "gog authenticated" "No accounts configured — run: gog auth add your@gmail.com --services gmail,calendar,drive,contacts,docs,sheets"
    fi
else
    log_fail "gog CLI" "Not installed" "Install: brew install steipete/tap/gogcli. If brew install failed, check: brew doctor"
fi

# --- Chrome / Browser ---
section "Chrome Browser"

# Check Chrome installed
if [ -d "/Applications/Google Chrome.app" ]; then
    CHROME_VER=$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version 2>/dev/null || echo "installed")
    log_pass "Google Chrome" "${CHROME_VER}"
else
    log_fail "Google Chrome" "Not found at /Applications/Google Chrome.app" "Download from: https://www.google.com/chrome/"
fi

# Check Chrome debug port
CDP_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:9222/json" --connect-timeout 3 2>/dev/null)
if [ "$CDP_TEST" = "200" ]; then
    TAB_COUNT=$(curl -s "http://localhost:9222/json" --connect-timeout 3 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
    log_pass "Chrome CDP (port 9222)" "Active — ${TAB_COUNT} tab(s) open"
else
    log_warn "Chrome CDP (port 9222)" "Not reachable — Chrome may not be running with --remote-debugging-port=9222"
fi

# Check OpenClaw browser profile directory
BROWSER_DIR="${OPENCLAW_DIR}/browser/openclaw/user-data"
if [ -d "$BROWSER_DIR" ]; then
    log_pass "Browser profile directory" "Exists"
else
    log_warn "Browser profile directory" "Not yet created — will be created on first browser use"
fi

# --- Network ---
section "Network"

# Internet connectivity
INET_TEST=$(curl -s -o /dev/null -w "%{http_code}" "https://api.anthropic.com" --connect-timeout 5 2>/dev/null)
if [ "$INET_TEST" != "000" ]; then
    log_pass "Internet connectivity" "Online"
else
    log_fail "Internet connectivity" "No internet connection" "Check your network settings."
fi

# DNS resolution
if host api.anthropic.com &>/dev/null 2>&1; then
    log_pass "DNS resolution" "Working"
else
    log_warn "DNS resolution" "host command failed (may still work via curl)"
fi

# ============================================================
# Generate Report
# ============================================================
section "Results"

echo ""
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${NC}  |  ${RED}Failed: ${FAIL_COUNT}${NC}  |  ${YELLOW}Warnings: ${WARN_COUNT}${NC}  |  Total: ${TOTAL_COUNT}"
echo ""

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}🎉 All checks passed! Your QUBEai installation is healthy.${NC}"
    echo ""
    exit 0
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "  ${YELLOW}${BOLD}⚠️  Installation is functional but has ${WARN_COUNT} warning(s).${NC}"
    echo -e "  ${DIM}Warnings are non-critical but should be reviewed.${NC}"
    echo ""
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}${BOLD}❌ Installation has ${FAIL_COUNT} failure(s) that need attention.${NC}"
    echo ""
fi

# ============================================================
# Write detailed report file
# ============================================================
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/qubeai-healthcheck-${TIMESTAMP}.txt"

cat > "$REPORT_FILE" <<REPORTEOF
================================================================================
  QUBEai Installation Health Check Report
  Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
================================================================================

SYSTEM INFORMATION
──────────────────
  Hostname:      ${SYS_HOSTNAME}
  User:          ${SYS_USER}
  OS:            ${SYS_OS} ${SYS_VER}
  Architecture:  ${SYS_ARCH}
  Shell:         ${SYS_SHELL}
  Memory:        ${SYS_MEM}
  Disk:          ${SYS_DISK}
  Home:          ${HOME_DIR}
  OpenClaw Dir:  ${OPENCLAW_DIR}

SUMMARY
──────────────────
  Passed:   ${PASS_COUNT}
  Failed:   ${FAIL_COUNT}
  Warnings: ${WARN_COUNT}
  Total:    ${TOTAL_COUNT}

DETAILED RESULTS
──────────────────
REPORTEOF

for result in "${RESULTS[@]}"; do
    IFS='|' read -r status name detail verbose <<< "$result"
    
    case "$status" in
        PASS)
            echo "  ✅ PASS  ${name}" >> "$REPORT_FILE"
            [ -n "$detail" ] && echo "          ${detail}" >> "$REPORT_FILE"
            ;;
        FAIL)
            echo "  ❌ FAIL  ${name}" >> "$REPORT_FILE"
            [ -n "$detail" ] && echo "          ${detail}" >> "$REPORT_FILE"
            [ -n "$verbose" ] && echo "          [VERBOSE] ${verbose}" >> "$REPORT_FILE"
            ;;
        WARN)
            echo "  ⚠️  WARN  ${name}" >> "$REPORT_FILE"
            [ -n "$detail" ] && echo "          ${detail}" >> "$REPORT_FILE"
            ;;
    esac
done

# Append config (redacted)
echo "" >> "$REPORT_FILE"
echo "CONFIGURATION (REDACTED)" >> "$REPORT_FILE"
echo "──────────────────" >> "$REPORT_FILE"
if [ -f "$CONFIG_FILE" ]; then
    python3 -c "
import json, re
with open('${CONFIG_FILE}') as f:
    cfg = json.load(f)

def redact(obj):
    if isinstance(obj, dict):
        return {k: ('***REDACTED***' if any(s in k.lower() for s in ['token','key','secret','password','apikey']) else redact(v)) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [redact(i) for i in obj]
    return obj

print(json.dumps(redact(cfg), indent=2))
" >> "$REPORT_FILE" 2>/dev/null || echo "  (could not read config)" >> "$REPORT_FILE"
fi

# Append environment info
echo "" >> "$REPORT_FILE"
echo "ENVIRONMENT" >> "$REPORT_FILE"
echo "──────────────────" >> "$REPORT_FILE"
echo "  PATH: $PATH" >> "$REPORT_FILE"
echo "  NODE: $(which node 2>/dev/null || echo 'not found') — $(node --version 2>/dev/null || echo 'N/A')" >> "$REPORT_FILE"
echo "  NPM:  $(which npm 2>/dev/null || echo 'not found') — $(npm --version 2>/dev/null || echo 'N/A')" >> "$REPORT_FILE"
echo "  BREW: $(which brew 2>/dev/null || echo 'not found')" >> "$REPORT_FILE"
echo "  GOG:  $(which gog 2>/dev/null || echo 'not found')" >> "$REPORT_FILE"
echo "  OPENCLAW: $(which openclaw 2>/dev/null || echo 'not found')" >> "$REPORT_FILE"
echo "  CHROME: $(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version 2>/dev/null || echo 'not found')" >> "$REPORT_FILE"

# Append recent logs
echo "" >> "$REPORT_FILE"
echo "RECENT GATEWAY LOGS (last 50 lines)" >> "$REPORT_FILE"
echo "──────────────────" >> "$REPORT_FILE"
if [ -f "${OPENCLAW_DIR}/logs/gateway.err.log" ]; then
    tail -50 "${OPENCLAW_DIR}/logs/gateway.err.log" >> "$REPORT_FILE" 2>/dev/null
elif [ -f "${OPENCLAW_DIR}/logs/gateway.out.log" ]; then
    tail -50 "${OPENCLAW_DIR}/logs/gateway.out.log" >> "$REPORT_FILE" 2>/dev/null
else
    echo "  (no log files found)" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "================================================================================" >> "$REPORT_FILE"
echo "  End of Report" >> "$REPORT_FILE"
echo "  To send this report to QUBEai support:" >> "$REPORT_FILE"
echo "  Email: support@blockchaintek.com" >> "$REPORT_FILE"
echo "  Attach: ${REPORT_FILE}" >> "$REPORT_FILE"
echo "================================================================================" >> "$REPORT_FILE"

echo -e "  ${BOLD}📄 Full report saved to:${NC}"
echo -e "     ${CYAN}${REPORT_FILE}${NC}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${BOLD}📧 To send this report to QUBEai support:${NC}"
    echo -e "     Email: ${CYAN}support@blockchaintek.com${NC}"
    echo -e "     Attach: ${CYAN}${REPORT_FILE}${NC}"
    echo ""
    
    read -p "  Would you like to open this report now? (y/N) " OPEN_REPORT
    if [[ "$OPEN_REPORT" == [yY]* ]]; then
        open "$REPORT_FILE" 2>/dev/null || cat "$REPORT_FILE"
    fi
fi

echo ""
