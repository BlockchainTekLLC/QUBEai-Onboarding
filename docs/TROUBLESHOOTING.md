# Troubleshooting

Common issues and how to fix them.

---

## Installation Issues

### "command not found: openclaw"

**Cause:** Your `PATH` environment variable doesn't include the global npm bin directory.

**Fix:**
1. Restart your terminal (this loads the updated PATH)
2. If that doesn't work, add npm's global bin to your PATH manually:

```bash
# For macOS/Linux
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

3. Verify: `which openclaw` should show a path
4. If still not working, reinstall:
   ```bash
   npm install -g openclaw
   ```

---

### Node.js version too old

**Error:** `Node.js vXX is too old (need v20+)`

**Fix:**
```bash
brew upgrade node
```

Then restart your terminal and verify:
```bash
node --version  # Should be v20 or higher
```

---

### Homebrew not installed

**Error:** `command not found: brew`

**Fix:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, follow the on-screen instructions to add Homebrew to your PATH.

---

## Telegram Issues

### Bot not responding

**Possible causes:**
1. **Wrong bot token** — Double-check the token from @BotFather
2. **Gateway not running** — Check status:
   ```bash
   openclaw gateway status
   ```
   If not running, start it:
   ```bash
   openclaw gateway start
   ```
3. **Wrong username in config** — Make sure your `@username` matches exactly (case-sensitive)

**Debug steps:**
1. Check logs:
   ```bash
   tail -f ~/.openclaw/logs/gateway.err.log
   ```
2. Verify config:
   ```bash
   cat ~/.openclaw/openclaw.json | grep -A5 telegram
   ```
3. Make sure `allowFrom` includes your exact `@username`

---

### "You are not authorized to use this bot"

**Cause:** Your Telegram username is not in the `allowFrom` list.

**Fix:**
1. Edit the config:
   ```bash
   nano ~/.openclaw/openclaw.json
   ```
2. Find the `telegram` section and add your `@username` to `allowFrom`:
   ```json
   "allowFrom": ["@yourusername"]
   ```
3. Restart the gateway:
   ```bash
   openclaw gateway restart
   ```

---

## Google Services Issues

### "gog command not found"

**Fix:**
```bash
brew install steipete/tap/gogcli
```

Then restart your terminal.

---

### Google services not working

**Cause:** You haven't set up OAuth credentials yet.

**Fix:**
1. Get your `client_secret.json` from [Google Cloud Console](https://console.cloud.google.com) (see [PREREQUISITES.md](PREREQUISITES.md))
2. Run:
   ```bash
   gog auth credentials /path/to/client_secret.json
   gog auth add your@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
   ```
3. Follow the OAuth flow in your browser

---

## Gateway Issues

### Gateway won't start

**Error:** `Failed to start gateway`

**Debug steps:**
1. Check if another instance is running:
   ```bash
   ps aux | grep openclaw
   ```
   If found, kill it:
   ```bash
   pkill -f openclaw
   ```
2. Check port 18789 isn't in use:
   ```bash
   lsof -i :18789
   ```
3. Try starting manually with verbose logging:
   ```bash
   openclaw gateway start --foreground
   ```
4. Check error logs:
   ```bash
   tail -100 ~/.openclaw/logs/gateway.err.log
   ```

---

### Gateway crashes on startup

**Possible causes:**
1. **Corrupt config** — Validate your JSON:
   ```bash
   cat ~/.openclaw/openclaw.json | jq .
   ```
   If `jq` isn't installed: `brew install jq`

2. **Missing API key** — Make sure `~/.openclaw/auth/anthropic_default.json` exists and contains your API key

3. **Permissions issue** — Check ownership:
   ```bash
   ls -la ~/.openclaw/
   ```
   If owned by root, fix it:
   ```bash
   sudo chown -R $(whoami) ~/.openclaw/
   ```

---

## Auto-Start Issues

### OpenClaw doesn't start on login

**Fix:**
1. Check if the LaunchAgent is loaded:
   ```bash
   launchctl list | grep openclaw
   ```
2. If not listed, load it:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.openclaw.gateway.plist
   ```
3. If it fails, check for errors:
   ```bash
   launchctl error com.openclaw.gateway
   ```

---

## Configuration Issues

### How to reset everything

**Nuclear option:** Start from scratch

```bash
# Stop the gateway
openclaw gateway stop

# Unload the LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.openclaw.gateway.plist

# Backup your config (just in case)
cp -r ~/.openclaw ~/.openclaw.backup

# Remove OpenClaw
rm -rf ~/.openclaw

# Uninstall global package
npm uninstall -g openclaw

# Now run the installer again
```

---

## Still Having Issues?

1. **Check logs:**
   ```bash
   tail -100 ~/.openclaw/logs/gateway.err.log
   ```

2. **Verify versions:**
   ```bash
   node --version  # Should be v20+
   openclaw --version
   ```

3. **Open an issue:**
   - Go to [GitHub Issues](https://github.com/BlockchainTekLLC/QUBEai-Onboarding/issues)
   - Include:
     - macOS version (`sw_vers`)
     - Node.js version (`node --version`)
     - Error logs (sanitize any API keys!)
     - What you were trying to do

---

**Tip:** Most issues are solved by:
1. Restarting the terminal
2. Running `openclaw gateway restart`
3. Checking the logs

Good luck! 🐾
