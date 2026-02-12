# QUBEai Setup Instructions

Welcome to QUBEai! Before running the installer, you'll need to set up a few accounts. This guide walks you through each step.

---

## Step 1: Create a Telegram Account (if you don't have one)

Telegram is how you'll communicate with your AI assistant.

1. Download Telegram on your phone:
   - **iPhone:** https://apps.apple.com/app/telegram-messenger/id686449807
   - **Android:** https://play.google.com/store/apps/details?id=org.telegram.messenger
2. You can also get the desktop app: https://desktop.telegram.org
3. Open Telegram and sign up with your phone number
4. Follow the verification steps (you'll receive an SMS code)
5. Set your username:
   - Go to **Settings** → **Username**
   - Choose a username (e.g., @jettbtc)
   - **Write this down — you'll need it during installation**

### Get Your Telegram User ID

Your numeric user ID is different from your @username. To find it:

1. In Telegram, search for the bot **@userinfobot**
2. Start a chat with it and send any message
3. It will reply with your **User ID** (a number like `123456789`)
4. **Write this number down — you'll need it during installation**

---

## Step 2: Create a Telegram Bot via BotFather

BotFather is Telegram's official tool for creating bots. Your AI assistant will live inside this bot.

1. In Telegram, search for **@BotFather** (look for the verified checkmark ✓)
2. Start a chat and send: `/start`
3. Send: `/newbot`
4. BotFather will ask: **"What name do you want for your bot?"**
   - This is the display name — choose something like `Jett's Assistant` or `QUBEai`
5. BotFather will ask: **"Choose a username for your bot"**
   - Must end in `bot` — e.g., `JettAssistantBot` or `JettQUBEaiBot`
   - This must be unique across all of Telegram
6. BotFather will reply with your **bot token** — it looks like:
   ```
   7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
7. **SAVE THIS TOKEN** — you'll need it during installation. Keep it secret!

### Optional: Set a Profile Photo for Your Bot

1. Send `/setuserpic` to @BotFather
2. Select your bot
3. Send a photo

### Optional: Set a Description

1. Send `/setdescription` to @BotFather
2. Select your bot
3. Type a short description (e.g., "My personal AI assistant powered by QUBEai")

---

## Step 3: Create an Anthropic Account (Claude AI)

Anthropic makes Claude, the AI model that powers your assistant.

1. Go to: **https://console.anthropic.com**
2. Click **"Sign up"**
3. Create an account with your email address
4. Verify your email
5. Once logged in, you'll need to add billing:
   - Go to **Settings** → **Billing** (or https://console.anthropic.com/settings/billing)
   - Click **"Add payment method"**
   - Add a credit card
   - We recommend starting with a **$20-50 credit** to get going
   - Typical usage runs about $5-15/day depending on how much you use it

### Get Your API Key

1. Go to: **https://console.anthropic.com/settings/keys**
2. Click **"Create Key"**
3. Name it something like `QUBEai` or `Mac Mini`
4. Copy the key — it starts with `sk-ant-...`
5. **SAVE THIS KEY** — you'll need it during installation. Keep it secret!

⚠️ **Important:** You can only see the full key once when you create it. If you lose it, you'll need to create a new one.

---

## Step 4: Run the QUBEai Installer

Now that you have everything ready, run the installer on your Mac:

1. Open **Terminal** (search for "Terminal" in Spotlight, or find it in Applications → Utilities)
2. Copy and paste this command:

```bash
curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/main/install-macos.sh -o install-macos.sh && chmod +x install-macos.sh && ./install-macos.sh
```

3. The installer will ask you for:
   - **Agent name** — Name your AI assistant anything you want!
   - **Anthropic API key** — The `sk-ant-...` key from Step 3
   - **Telegram bot token** — The token from Step 2
   - **Your Telegram @username** — From Step 1
   - **Your Telegram user ID** — The number from Step 1
   - **Timezone** — e.g., `America/Chicago`

4. The installer handles everything else automatically:
   - Installs all dependencies (Homebrew, Node.js, etc.)
   - Configures your AI assistant
   - Sets it to auto-start on boot
   - Connects to Telegram

5. When it's done, **open Telegram and send a message to your bot!** 🎉

---

## Step 5: Start Chatting!

1. In Telegram, find your bot (search for the username you chose in Step 2)
2. Press **Start** or send any message
3. Your AI assistant will respond!
4. Try asking it things like:
   - "What can you do?"
   - "What's the weather today?"
   - "Help me draft an email"
   - "Remind me to call John at 3pm"

---

## Quick Reference — What You'll Need

| Item | Where to Get It | Looks Like |
|------|----------------|------------|
| Telegram @username | Telegram Settings | @yourname |
| Telegram User ID | @userinfobot in Telegram | 123456789 |
| Bot Token | @BotFather in Telegram | 7123456789:AAHxxx... |
| Anthropic API Key | console.anthropic.com/settings/keys | sk-ant-api03-xxx... |

---

## Need Help?

- **Troubleshooting guide:** https://github.com/BlockchainTekLLC/QUBEai-Onboarding/blob/main/docs/TROUBLESHOOTING.md
- **Contact:** will@blockchaintek.com
- **Website:** https://qubeai.com

---

*Powered by QUBEai • BlockchainTek LLC*
