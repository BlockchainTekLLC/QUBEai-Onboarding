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

### 6. Brave Search API Key (Optional)

For web search capabilities.

**How to get it:**
1. Go to [brave.com/search/api](https://brave.com/search/api)
2. Sign up for an API key
3. Free tier: 2,000 queries/month
4. **Save the API key**

**Note:** Web search is optional. Skip this if you don't need it.

---

## Quick Checklist

Before running the installer, make sure you have:

- [ ] **Anthropic API key** (`sk-ant-...`)
- [ ] **Telegram bot token** (`1234567890:ABC...`)
- [ ] **Your Telegram @username** (e.g., `@johndoe`)
- [ ] **Your Telegram user ID** (e.g., `123456789`)
- [ ] **Google OAuth credentials** (optional, `client_secret.json`)
- [ ] **Brave Search API key** (optional)

---

## Ready to Install?

Once you have everything above, head back to the [README](../README.md) and run the installer!

---

**Questions?** Open an issue or check [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md).
