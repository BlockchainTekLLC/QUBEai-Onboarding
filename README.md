<p align="center">
  <img src="assets/logo-blue.png" alt="BlockchainTek" width="400">
</p>

# QUBEai - AI Assistant Appliance

**Quick setup scripts for QUBEai installations**

---

## What is QUBEai?

QUBEai is a pre-configured AI assistant appliance by **BlockchainTek LLC** — a turnkey solution that brings powerful AI capabilities to your devices with minimal setup.

This repository contains onboarding and setup scripts for new QUBEai installations, making it easy to get up and running quickly.

---

## Platform Support

- ✅ **macOS** (Monterey 12.0+) — **Available now**
- 🚧 **Ubuntu 24 LTS** — **Coming soon**

---

## Quick Start

### macOS Installation

**Step 1 — Pre-install** (keyboard, Telegram, VS Code, Claude Code):
```bash
curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/pre-install.sh -o pre-install.sh
chmod +x pre-install.sh && ./pre-install.sh
```

**Step 2 — Main install** (OpenClaw + agent config):
```bash
curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/install-macos.sh | bash
```

**Quick standalone scripts** (if you just need one thing):
```bash
# PC keyboard fix (Karabiner + VS Code)
curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/keyboard-setup.sh | bash

# VS Code only
brew install --cask visual-studio-code
```

The installer will:
- Install required dependencies (Node.js, Homebrew, etc.)
- Set up OpenClaw AI framework
- Configure your AI agent with Google services support
- Create auto-start service for seamless operation
- Connect to your Telegram for instant communication

**Before you start:** Review [docs/PREREQUISITES.md](docs/PREREQUISITES.md) to gather the required API keys and credentials.

---

## What's Inside

- `install-macos.sh` — Full macOS installation script
- `install-ubuntu.sh` — Ubuntu setup (coming soon)
- `docs/PREREQUISITES.md` — What you need before installing
- `docs/TROUBLESHOOTING.md` — Common issues and solutions

---

## Features

- 🤖 **AI-powered assistant** using Claude (Anthropic)
- 💬 **Telegram integration** for instant communication
- 📧 **Google Workspace support** (Gmail, Calendar, Drive, Docs, Sheets)
- 🌐 **Web search** capabilities
- 🔧 **Full system access** with elevated permissions (when needed)
- ⚡ **Auto-start** on boot for always-on availability
- 🔒 **Secure** credential management

---

## Learn More

Visit **[qubeai.com](https://qubeai.com)** for more information about QUBEai.

---

## Support

Having issues? Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or open an issue.

---

## License

MIT License - Copyright © 2026 BlockchainTek LLC

---

**Built with ❤️ by BlockchainTek LLC**
