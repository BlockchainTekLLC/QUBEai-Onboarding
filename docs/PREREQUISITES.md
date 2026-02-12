# Prerequisites

Before running the QUBEai installer, you'll need to gather a few API keys and credentials. Don't worry — this guide will walk you through getting each one.

---

## Required

### 1. Anthropic API Key

QUBEai uses Claude, Anthropic's AI model, as its brain.

**How to get it:**
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to **API Keys** in the dashboard
4. Click **Create Key**
5. Copy the key (starts with `sk-ant-...`)
6. **Save it somewhere safe** — you'll need it during installation

**Cost:** Pay-as-you-go. Claude Sonnet costs ~$3 per million input tokens. Typical usage: $5-20/month for moderate use.

---

### 2. Telegram Bot Token

Your AI assistant will communicate with you via Telegram.

**How to get it:**
1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot` to BotFather
3. Follow the prompts:
   - Give your bot a name (e.g., "My QUBEai Assistant")
   - Give it a username (must end in `bot`, e.g., `myqubeai_bot`)
4. BotFather will give you a **token** (looks like `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. **Save this token** — you'll need it during installation

---

### 3. Your Telegram Username

Your Telegram `@username` (e.g., `@johndoe`)

**How to find it:**
1. Open Telegram
2. Go to **Settings** → **Edit Profile**
3. Your username is listed there (starts with `@`)

**Don't have one?** Create one in Telegram settings — it's required for security.

---

### 4. Your Telegram User ID

This is your numeric Telegram ID (e.g., `123456789`)

**How to find it:**
1. Open Telegram and search for [@userinfobot](https://t.me/userinfobot)
2. Send `/start` to the bot
3. It will reply with your **User ID** (a number)
4. **Save this number**

---

## Optional (But Recommended)

### 5. Google Cloud OAuth Credentials

For Gmail, Calendar, Drive, Docs, and Sheets integration.

**How to get it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (or use an existing one)
3. Enable these APIs:
   - Gmail API
   - Google Calendar API
   - Google Drive API
   - Google Sheets API
   - Google Docs API
4. Go to **APIs & Services** → **Credentials**
5. Click **Create Credentials** → **OAuth client ID**
6. Choose **Desktop app** as the application type
7. Download the JSON file (e.g., `client_secret_xxxxx.json`)
8. **Save this file** — you'll need it after installation

After installation, run:
```bash
gog auth credentials /path/to/client_secret.json
gog auth add your@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
```

**Not sure how to set this up?** Follow [gogcli.sh/setup](https://gogcli.sh) for step-by-step instructions.

---

### 6. Google Chrome — Enable Remote Debugging

Your AI assistant uses Chrome for browser automation (web searches, reading pages, filling forms, etc.). This requires Chrome's remote debugging protocol (CDP) to be enabled.

**Install Chrome (if you don't have it):**
1. Download from [google.com/chrome](https://www.google.com/chrome/)
2. Install and open it once

**Enable Remote Debugging on macOS:**

You need to launch Chrome with a special flag. The easiest way is to create a shortcut:

1. Open **Terminal**
2. Run this command to create a launcher script:

```bash
cat > ~/start-chrome-debug.sh << 'EOF'
#!/bin/bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.openclaw/browser/openclaw/user-data" &
EOF
chmod +x ~/start-chrome-debug.sh
```

3. From now on, start Chrome for your assistant with:
```bash
~/start-chrome-debug.sh
```

**Verify it's working:**
1. Make sure Chrome is running with the debug flag (use the script above)
2. Open a new tab and go to: `http://localhost:9222/json`
3. You should see a JSON response listing your open tabs
4. If you see "connection refused," Chrome isn't running with debugging enabled

**Important notes:**
- This Chrome instance is separate from your normal Chrome (it uses its own profile directory)
- The assistant uses port **9222** by default
- You only need to start Chrome this way when you want the assistant to use the browser
- The installer configures OpenClaw to use this automatically

---

## Quick Checklist

Before running the installer, make sure you have:

- [ ] **Anthropic API key** (`sk-ant-...`)
- [ ] **Telegram bot token** (`1234567890:ABC...`)
- [ ] **Your Telegram @username** (e.g., `@johndoe`)
- [ ] **Your Telegram user ID** (e.g., `123456789`)
- [ ] **Google OAuth credentials** (optional, `client_secret.json`)
- [ ] **Google Chrome installed** (for browser automation)

---

## Ready to Install?

Once you have everything above, head back to the [README](../README.md) and run the installer!

---

**Questions?** Open an issue or check [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md).
