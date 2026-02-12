#!/bin/bash
# ============================================================
# QUBEai Installation Health Check
# Version: 2.0.0
# Validates all components are installed and functioning
# Generates a detailed report with one-click support submission
# ============================================================

set -o pipefail

# Script version
SCRIPT_VERSION="2.0.0"

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
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_ID=$(openssl rand -hex 4 2>/dev/null || echo "$(date +%s | md5 | head -c 8)")
REPORT_FILE="${REPORT_DIR}/qubeai-healthcheck-${REPORT_ID}-${TIMESTAMP}.txt"
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
    echo -e "${CYAN}║${NC}  Version ${SCRIPT_VERSION} | Report ID: ${REPORT_ID}     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

log_pass() {
    local test_name="$1"
    local detail="$2"
    echo -e "  ${GREEN}✅ PASS${NC}  ${test_name}"
    [ -n "$detail" ] && echo -e "         ${DIM}${detail}${NC}"
    RESULTS+=("PASS|${test_name}|${detail}|")
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
    RESULTS+=("WARN|${test_name}|${detail}|")
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
    BREW_INSTALLED=true
else
    log_fail "Homebrew" "Not installed" "Homebrew is required for installing dependencies. Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    BREW_INSTALLED=false
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

# Test: Python3
if command -v python3 &>/dev/null; then
    PYTHON_VER=$(python3 --version 2>/dev/null)
    log_pass "Python3" "${PYTHON_VER}"
else
    log_warn "Python3" "Not installed (needed for config parsing)"
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

# --- System Permissions & Configuration ---
section "System Permissions & Configuration"

# Test: User groups (admin/sudo rights)
USER_GROUPS=$(groups "$SYS_USER" 2>/dev/null)
if echo "$USER_GROUPS" | grep -q "admin"; then
    log_pass "Admin rights" "User has admin privileges"
else
    log_warn "Admin rights" "User is not in 'admin' group — may need elevated permissions for some operations"
fi

# Test: macOS System Integrity Protection
if command -v csrutil &>/dev/null; then
    CSR_STATUS=$(csrutil status 2>/dev/null || echo "Unknown")
    if echo "$CSR_STATUS" | grep -qi "enabled"; then
        log_pass "System Integrity Protection" "Enabled (secure)"
    elif echo "$CSR_STATUS" | grep -qi "disabled"; then
        log_warn "System Integrity Protection" "Disabled — system may be less secure"
    else
        log_warn "System Integrity Protection" "${CSR_STATUS}"
    fi
fi

# Test: Disk space
DISK_AVAIL=$(df -h / 2>/dev/null | awk 'NR==2{print $4}')
DISK_AVAIL_GB=$(df -g / 2>/dev/null | awk 'NR==2{print $4}')
if [ "$DISK_AVAIL_GB" -ge 10 ] 2>/dev/null; then
    log_pass "Disk space" "${DISK_AVAIL} available"
elif [ "$DISK_AVAIL_GB" -ge 5 ] 2>/dev/null; then
    log_warn "Disk space" "Only ${DISK_AVAIL} available — consider freeing up space"
else
    log_fail "Disk space" "Only ${DISK_AVAIL} available — may cause issues" "Free up disk space"
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
    if command -v python3 &>/dev/null && python3 -c "import json; json.load(open('${CONFIG_FILE}'))" 2>/dev/null; then
        log_pass "Config JSON valid" "Parsed successfully"
    else
        log_fail "Config JSON valid" "Invalid JSON in ${CONFIG_FILE}" "$(python3 -c "import json; json.load(open('${CONFIG_FILE}'))" 2>&1)"
    fi
else
    log_fail "OpenClaw config" "Not found at ${CONFIG_FILE}" "Run the installer again or create config manually."
fi

# Test: OpenClaw directories
for dir in "workspaces" "agents" "logs" "auth"; do
    if [ -d "${OPENCLAW_DIR}/${dir}" ]; then
        log_pass "Directory: ${dir}/" "Exists"
    else
        log_warn "Directory: ${dir}/" "Missing — will be created on first run"
    fi
done

# Test: Agent workspace
if [ -f "$CONFIG_FILE" ] && command -v python3 &>/dev/null; then
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

# --- Homebrew Diagnostics ---
section "Homebrew Diagnostics"

if [ "$BREW_INSTALLED" = true ]; then
    # Test: brew doctor
    echo -e "  ${DIM}Running brew doctor (this may take a moment)...${NC}"
    BREW_DOCTOR=$(brew doctor 2>&1)
    if echo "$BREW_DOCTOR" | grep -qi "ready to brew"; then
        log_pass "brew doctor" "No issues found"
    else
        log_warn "brew doctor" "Issues detected (see verbose section)" "${BREW_DOCTOR}"
    fi
    
    # Test: Homebrew packages
    BREW_LIST=$(brew list 2>/dev/null || echo "")
    if [ -n "$BREW_LIST" ]; then
        BREW_COUNT=$(echo "$BREW_LIST" | wc -l | tr -d ' ')
        log_pass "Homebrew packages" "${BREW_COUNT} packages installed"
    fi
fi

# --- npm Configuration ---
section "npm Configuration"

if command -v npm &>/dev/null; then
    # Test: npm config
    NPM_CONFIG=$(npm config list 2>&1)
    NPM_PREFIX=$(npm config get prefix 2>/dev/null)
    log_pass "npm global prefix" "${NPM_PREFIX}"
    
    # Test: npm global packages
    NPM_GLOBALS=$(npm list -g --depth=0 2>/dev/null || echo "")
    if [ -n "$NPM_GLOBALS" ]; then
        NPM_GLOBAL_COUNT=$(echo "$NPM_GLOBALS" | grep -c "├\|└" || echo "0")
        log_pass "npm global packages" "${NPM_GLOBAL_COUNT} packages installed"
    fi
    
    # Check if openclaw is in global packages
    if echo "$NPM_GLOBALS" | grep -q "openclaw@"; then
        log_pass "openclaw in npm globals" "Found"
    else
        log_warn "openclaw in npm globals" "Not found — may not be installed globally"
    fi
fi

# --- Telegram ---
section "Telegram"

if [ -f "$CONFIG_FILE" ] && command -v python3 &>/dev/null; then
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

# --- Network Diagnostics ---
section "Network Diagnostics"

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

# Test connectivity to key endpoints
for endpoint in "api.anthropic.com" "github.com" "registry.npmjs.org" "api.telegram.org"; do
    ENDPOINT_TEST=$(curl -s -o /dev/null -w "%{http_code}" "https://${endpoint}" --connect-timeout 5 2>/dev/null)
    if [ "$ENDPOINT_TEST" != "000" ]; then
        log_pass "Connectivity: ${endpoint}" "HTTP ${ENDPOINT_TEST}"
    else
        log_fail "Connectivity: ${endpoint}" "Connection failed" "Check network/firewall"
    fi
done

# Proxy settings
PROXY_ENV=$(env | grep -i proxy 2>/dev/null)
if [ -n "$PROXY_ENV" ]; then
    log_warn "Proxy settings" "Proxy detected in environment (may affect connectivity)" "${PROXY_ENV}"
else
    log_pass "Proxy settings" "No proxy configured"
fi

# VPN detection
VPN_COUNT=$(ifconfig 2>/dev/null | grep -c "utun" || echo "0")
if [ "$VPN_COUNT" -gt 0 ]; then
    log_warn "VPN detection" "${VPN_COUNT} VPN interface(s) detected — may affect connectivity"
else
    log_pass "VPN detection" "No VPN interfaces detected"
fi

# macOS firewall status
if [ -x "/usr/libexec/ApplicationFirewall/socketfilterfw" ]; then
    FIREWALL_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "Unknown")
    if echo "$FIREWALL_STATUS" | grep -qi "enabled"; then
        log_pass "macOS Firewall" "Enabled"
    elif echo "$FIREWALL_STATUS" | grep -qi "disabled"; then
        log_warn "macOS Firewall" "Disabled — consider enabling for security"
    else
        log_warn "macOS Firewall" "${FIREWALL_STATUS}"
    fi
fi

# --- Google Workspace (gog) ---
section "Google Workspace (gog)"

if command -v gog &>/dev/null; then
    GOG_VER=$(gog --version 2>/dev/null || echo "installed")
    log_pass "gog CLI" "${GOG_VER}"
    
    # Check auth
    GOG_AUTH=$(gog auth list 2>&1)
    if echo "$GOG_AUTH" | grep -q "@"; then
        GOG_ACCOUNT=$(echo "$GOG_AUTH" | grep "@" | head -1 | awk '{print $1}')
        log_pass "gog authenticated" "${GOG_ACCOUNT}"
        GOG_AUTHED=true
    else
        log_warn "gog authenticated" "No accounts configured — run: gog auth add your@gmail.com --services gmail,calendar,drive,contacts,docs,sheets"
        GOG_AUTHED=false
    fi
else
    log_fail "gog CLI" "Not installed" "Install: brew install steipete/tap/gogcli. If brew install failed, check: brew doctor"
    GOG_AUTHED=false
fi

# --- Chrome / Browser ---
section "Chrome Browser"

# Check Chrome installed
if [ -d "/Applications/Google Chrome.app" ]; then
    CHROME_VER=$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version 2>/dev/null || echo "installed")
    log_pass "Google Chrome" "${CHROME_VER}"
    CHROME_INSTALLED=true
else
    log_fail "Google Chrome" "Not found at /Applications/Google Chrome.app" "Download from: https://www.google.com/chrome/"
    CHROME_INSTALLED=false
fi

# Check Chrome processes
CHROME_PROCS=$(ps aux | grep -i "[c]hrome" | wc -l | tr -d ' ')
if [ "$CHROME_PROCS" -gt 0 ]; then
    log_pass "Chrome processes" "${CHROME_PROCS} Chrome processes running"
else
    log_warn "Chrome processes" "No Chrome processes detected — Chrome may not be running"
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

# --- Shell Configuration ---
section "Shell Configuration"

# Check .zshrc for relevant configurations
if [ -f "${HOME_DIR}/.zshrc" ]; then
    log_pass "Shell config (.zshrc)" "Exists"
    
    # Check for PATH configurations
    if grep -q "brew\|node\|npm\|openclaw" "${HOME_DIR}/.zshrc" 2>/dev/null; then
        log_pass "Shell PATH config" "Found brew/node/npm/openclaw references in .zshrc"
    else
        log_warn "Shell PATH config" "No brew/node/npm/openclaw found in .zshrc — may need to add to PATH"
    fi
else
    log_warn "Shell config (.zshrc)" "File not found"
fi

# Check .zprofile
if [ -f "${HOME_DIR}/.zprofile" ]; then
    if grep -q "brew\|node\|npm\|openclaw" "${HOME_DIR}/.zprofile" 2>/dev/null; then
        log_pass "Shell config (.zprofile)" "Found relevant PATH configurations"
    fi
fi

# ============================================================
# Results
# ============================================================
section "Results"

echo ""
echo -e "  ${GREEN}Passed: ${PASS_COUNT}${NC}  |  ${RED}Failed: ${FAIL_COUNT}${NC}  |  ${YELLOW}Warnings: ${WARN_COUNT}${NC}  |  Total: ${TOTAL_COUNT}"
echo ""

# Determine overall health status
if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    HEALTH_STATUS="PASS"
    echo -e "  ${GREEN}${BOLD}🎉 All checks passed! Your QUBEai installation is healthy.${NC}"
    echo ""
elif [ "$FAIL_COUNT" -eq 0 ]; then
    HEALTH_STATUS="PARTIAL"
    echo -e "  ${YELLOW}${BOLD}⚠️  Installation is functional but has ${WARN_COUNT} warning(s).${NC}"
    echo -e "  ${DIM}Warnings are non-critical but should be reviewed.${NC}"
    echo ""
else
    HEALTH_STATUS="FAIL"
    echo -e "  ${RED}${BOLD}❌ Installation has ${FAIL_COUNT} failure(s) that need attention.${NC}"
    echo ""
fi

# ============================================================
# Write detailed report file
# ============================================================
mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" <<REPORTEOF
================================================================================
  QUBEai Installation Health Check Report
  Report ID: ${REPORT_ID}
  Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
  Script Version: ${SCRIPT_VERSION}
================================================================================

HEALTH SUMMARY: ${HEALTH_STATUS} — ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${WARN_COUNT} warnings

================================================================================
SYSTEM INFORMATION
================================================================================
  Timestamp:     $(date '+%Y-%m-%d %H:%M:%S %Z')
  Hostname:      ${SYS_HOSTNAME}
  User:          ${SYS_USER}
  OS:            ${SYS_OS} ${SYS_VER}
  Architecture:  ${SYS_ARCH}
  Shell:         ${SYS_SHELL}
  Memory:        ${SYS_MEM}
  Disk:          ${SYS_DISK}
  Home:          ${HOME_DIR}
  OpenClaw Dir:  ${OPENCLAW_DIR}

================================================================================
TEST RESULTS SUMMARY
================================================================================
  Passed:   ${PASS_COUNT}
  Failed:   ${FAIL_COUNT}
  Warnings: ${WARN_COUNT}
  Total:    ${TOTAL_COUNT}
  
  Overall Status: ${HEALTH_STATUS}

================================================================================
DETAILED TEST RESULTS
================================================================================
REPORTEOF

# Write detailed results
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
    echo "" >> "$REPORT_FILE"
done

# ============================================================
# VERBOSE DIAGNOSTIC DATA
# ============================================================
cat >> "$REPORT_FILE" <<VERBOSEEOF

================================================================================
VERBOSE DIAGNOSTIC DATA
================================================================================

──────────────────────────────────────────────────────────────────────────────
ENVIRONMENT VARIABLES
──────────────────────────────────────────────────────────────────────────────
PATH: $PATH

NODE: $(which node 2>/dev/null || echo 'not found') — $(node --version 2>/dev/null || echo 'N/A')
NPM:  $(which npm 2>/dev/null || echo 'not found') — v$(npm --version 2>/dev/null || echo 'N/A')
PYTHON3: $(which python3 2>/dev/null || echo 'not found') — $(python3 --version 2>/dev/null || echo 'N/A')
BREW: $(which brew 2>/dev/null || echo 'not found')
GOG:  $(which gog 2>/dev/null || echo 'not found')
OPENCLAW: $(which openclaw 2>/dev/null || echo 'not found')

──────────────────────────────────────────────────────────────────────────────
HOMEBREW DIAGNOSTICS (brew doctor)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF

if [ "$BREW_INSTALLED" = true ]; then
    echo "$BREW_DOCTOR" >> "$REPORT_FILE" 2>/dev/null || echo "(brew doctor failed)" >> "$REPORT_FILE"
else
    echo "(Homebrew not installed)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF2

──────────────────────────────────────────────────────────────────────────────
HOMEBREW INSTALLED PACKAGES (brew list)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF2

if [ "$BREW_INSTALLED" = true ]; then
    brew list 2>/dev/null >> "$REPORT_FILE" || echo "(brew list failed)" >> "$REPORT_FILE"
else
    echo "(Homebrew not installed)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF3

──────────────────────────────────────────────────────────────────────────────
NPM CONFIGURATION (npm config list)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF3

if command -v npm &>/dev/null; then
    npm config list 2>&1 >> "$REPORT_FILE"
else
    echo "(npm not installed)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF4

──────────────────────────────────────────────────────────────────────────────
NPM GLOBAL PACKAGES (npm list -g --depth=0)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF4

if command -v npm &>/dev/null; then
    npm list -g --depth=0 2>&1 >> "$REPORT_FILE"
else
    echo "(npm not installed)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF5

──────────────────────────────────────────────────────────────────────────────
OPENCLAW DIRECTORY STRUCTURE (ls -la ~/.openclaw/)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF5

if [ -d "$OPENCLAW_DIR" ]; then
    ls -laR "$OPENCLAW_DIR" 2>&1 >> "$REPORT_FILE"
else
    echo "(OpenClaw directory not found)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF6

──────────────────────────────────────────────────────────────────────────────
OPENCLAW AUTH DIRECTORY PERMISSIONS (ls -la ~/.openclaw/auth/)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF6

if [ -d "${OPENCLAW_DIR}/auth" ]; then
    ls -la "${OPENCLAW_DIR}/auth" 2>&1 >> "$REPORT_FILE"
else
    echo "(Auth directory not found)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF7

──────────────────────────────────────────────────────────────────────────────
LAUNCHCTL SERVICE STATUS (launchctl list | grep openclaw)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF7

launchctl list 2>/dev/null | grep openclaw >> "$REPORT_FILE" || echo "(No openclaw services found)" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<VERBOSEEOF8

──────────────────────────────────────────────────────────────────────────────
CHROME PROCESSES (ps aux | grep -i chrome)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF8

if [ "$CHROME_INSTALLED" = true ]; then
    ps aux | grep -i "[c]hrome" >> "$REPORT_FILE" 2>&1 || echo "(No Chrome processes found)" >> "$REPORT_FILE"
else
    echo "(Chrome not installed)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF9

──────────────────────────────────────────────────────────────────────────────
DISK SPACE DETAIL (df -h)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF9

df -h >> "$REPORT_FILE" 2>&1

cat >> "$REPORT_FILE" <<VERBOSEEOF10

──────────────────────────────────────────────────────────────────────────────
SHELL PROFILE CONTENTS (redacted - .zshrc)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF10

if [ -f "${HOME_DIR}/.zshrc" ]; then
    echo "Lines containing PATH, brew, node, openclaw, npm:" >> "$REPORT_FILE"
    grep -E "PATH|brew|node|openclaw|npm" "${HOME_DIR}/.zshrc" 2>/dev/null >> "$REPORT_FILE" || echo "(no matches)" >> "$REPORT_FILE"
else
    echo "(.zshrc not found)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF11

──────────────────────────────────────────────────────────────────────────────
SHELL PROFILE CONTENTS (redacted - .zprofile)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF11

if [ -f "${HOME_DIR}/.zprofile" ]; then
    echo "Lines containing PATH, brew, node, openclaw, npm:" >> "$REPORT_FILE"
    grep -E "PATH|brew|node|openclaw|npm" "${HOME_DIR}/.zprofile" 2>/dev/null >> "$REPORT_FILE" || echo "(no matches)" >> "$REPORT_FILE"
else
    echo "(.zprofile not found)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF12

──────────────────────────────────────────────────────────────────────────────
SYSTEM LOGS - RECENT OPENCLAW/NODE ENTRIES (last 10 minutes)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF12

log show --predicate 'processImagePath contains "openclaw" OR processImagePath contains "node"' --last 10m 2>/dev/null >> "$REPORT_FILE" || echo "(Unable to retrieve system logs - may need admin privileges)" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<VERBOSEEOF13

──────────────────────────────────────────────────────────────────────────────
OPENCLAW GATEWAY LOG (FULL - gateway.err.log)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF13

if [ -f "${OPENCLAW_DIR}/logs/gateway.err.log" ]; then
    cat "${OPENCLAW_DIR}/logs/gateway.err.log" >> "$REPORT_FILE" 2>/dev/null
else
    echo "(gateway.err.log not found)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF14

──────────────────────────────────────────────────────────────────────────────
OPENCLAW GATEWAY LOG (FULL - gateway.out.log)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF14

if [ -f "${OPENCLAW_DIR}/logs/gateway.out.log" ]; then
    cat "${OPENCLAW_DIR}/logs/gateway.out.log" >> "$REPORT_FILE" 2>/dev/null
else
    echo "(gateway.out.log not found)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" <<VERBOSEEOF15

──────────────────────────────────────────────────────────────────────────────
OPENCLAW CONFIGURATION (REDACTED)
──────────────────────────────────────────────────────────────────────────────
VERBOSEEOF15

if [ -f "$CONFIG_FILE" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json, re
try:
    with open('${CONFIG_FILE}') as f:
        cfg = json.load(f)
    
    def redact(obj):
        if isinstance(obj, dict):
            return {k: ('***REDACTED***' if any(s in k.lower() for s in ['token','key','secret','password','apikey']) else redact(v)) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [redact(i) for i in obj]
        return obj
    
    print(json.dumps(redact(cfg), indent=2))
except Exception as e:
    print(f'Error reading config: {e}')
" >> "$REPORT_FILE" 2>&1
else
    echo "(Config file not found or Python3 not available)" >> "$REPORT_FILE"
fi

# ============================================================
# Footer
# ============================================================
cat >> "$REPORT_FILE" <<FOOTEREOF

================================================================================
  End of Report
  Report ID: ${REPORT_ID}
  Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
  Script Version: ${SCRIPT_VERSION}
================================================================================
  
  To send this report to QUBEai support:
  Email: support@blockchaintek.com
  Attach: ${REPORT_FILE}
  
================================================================================
FOOTEREOF

echo -e "  ${BOLD}📄 Full report saved to:${NC}"
echo -e "     ${CYAN}${REPORT_FILE}${NC}"
echo ""

# ============================================================
# One-Click Support Ticket Feature
# ============================================================
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${BOLD}📧 One-Click Support Ticket${NC}"
    echo ""
    read -p "  Would you like to send this report to QUBEai support? (y/N) " SEND_SUPPORT
    
    if [[ "$SEND_SUPPORT" =~ ^[yY]$ ]]; then
        SENT=false
        
        # Method 1: Try gog (if installed and authenticated)
        if [ "$GOG_AUTHED" = true ]; then
            echo ""
            echo -e "  ${CYAN}Attempting to send via gog (Gmail)...${NC}"
            
            GOG_SUBJECT="QUBEai Health Check Report - ${SYS_HOSTNAME} - ${TIMESTAMP}"
            GOG_BODY="Automated health check report attached. ${FAIL_COUNT} failures detected.\n\nReport ID: ${REPORT_ID}\nHostname: ${SYS_HOSTNAME}\nUser: ${SYS_USER}\nTimestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
            
            if gog gmail send --to support@blockchaintek.com --subject "${GOG_SUBJECT}" --attach "${REPORT_FILE}" --body "${GOG_BODY}" 2>/dev/null; then
                echo -e "  ${GREEN}✅ Report sent successfully via gog!${NC}"
                SENT=true
            else
                echo -e "  ${RED}❌ Failed to send via gog${NC}"
            fi
        fi
        
        # Method 2: Python3 SMTP fallback (if gog failed)
        if [ "$SENT" = false ] && command -v python3 &>/dev/null; then
            echo ""
            echo -e "  ${CYAN}Attempting to send via Python3 SMTP...${NC}"
            echo -e "  ${DIM}(You'll need your Gmail credentials and an app-specific password)${NC}"
            echo ""
            
            read -p "  Enter your Gmail address: " GMAIL_USER
            read -s -p "  Enter your Gmail app password: " GMAIL_PASS
            echo ""
            
            if [ -n "$GMAIL_USER" ] && [ -n "$GMAIL_PASS" ]; then
                python3 <<PYEOF
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import sys

try:
    msg = MIMEMultipart()
    msg['From'] = "${GMAIL_USER}"
    msg['To'] = "support@blockchaintek.com"
    msg['Subject'] = "QUBEai Health Check Report - ${SYS_HOSTNAME} - ${TIMESTAMP}"
    
    body = """Automated health check report attached. ${FAIL_COUNT} failures detected.

Report ID: ${REPORT_ID}
Hostname: ${SYS_HOSTNAME}
User: ${SYS_USER}
Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"""
    
    msg.attach(MIMEText(body, 'plain'))
    
    with open("${REPORT_FILE}", "rb") as f:
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(f.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', f"attachment; filename= {REPORT_FILE.split('/')[-1]}")
        msg.attach(part)
    
    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login("${GMAIL_USER}", "${GMAIL_PASS}")
    server.send_message(msg)
    server.quit()
    
    print("SUCCESS")
    sys.exit(0)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
PYEOF
                
                if [ $? -eq 0 ]; then
                    echo -e "  ${GREEN}✅ Report sent successfully via Python3 SMTP!${NC}"
                    SENT=true
                else
                    echo -e "  ${RED}❌ Failed to send via Python3 SMTP${NC}"
                fi
            else
                echo -e "  ${YELLOW}Skipped — credentials not provided${NC}"
            fi
        fi
        
        # Method 3: Last resort - open in Finder
        if [ "$SENT" = false ]; then
            echo ""
            echo -e "  ${YELLOW}Automated sending failed. Opening report for manual submission...${NC}"
            echo ""
            echo -e "  ${BOLD}Please manually email the report to:${NC}"
            echo -e "     ${CYAN}support@blockchaintek.com${NC}"
            echo ""
            echo -e "  ${BOLD}Report location:${NC}"
            echo -e "     ${CYAN}${REPORT_FILE}${NC}"
            echo ""
            
            read -p "  Open report in Finder? (Y/n) " OPEN_FINDER
            if [[ ! "$OPEN_FINDER" =~ ^[nN]$ ]]; then
                open -R "$REPORT_FILE" 2>/dev/null || open "$REPORT_DIR" 2>/dev/null
            fi
        fi
    fi
    
    # Offer to copy to clipboard
    echo ""
    read -p "  Copy report to clipboard? (y/N) " COPY_CLIP
    if [[ "$COPY_CLIP" =~ ^[yY]$ ]]; then
        if pbcopy < "$REPORT_FILE" 2>/dev/null; then
            echo -e "  ${GREEN}✅ Report copied to clipboard!${NC}"
        else
            echo -e "  ${RED}❌ Failed to copy to clipboard${NC}"
        fi
    fi
fi

echo ""

# Exit with appropriate code
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
    exit 2
else
    exit 0
fi
