#!/bin/bash
# ============================================================
# QUBEai One-Click Setup
# Downloads and runs the full installer interactively
# Usage: curl -fsSL https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master/setup.sh | bash
# ============================================================

REPO="https://raw.githubusercontent.com/BlockchainTekLLC/QUBEai-Onboarding/master"
TMPDIR=$(mktemp -d)

echo "🐾 Downloading QUBEai installer..."
curl -fsSL "${REPO}/pre-install.sh" -o "${TMPDIR}/pre-install.sh"
curl -fsSL "${REPO}/install-macos.sh" -o "${TMPDIR}/install-macos.sh"
curl -fsSL "${REPO}/keyboard-setup.sh" -o "${TMPDIR}/keyboard-setup.sh"
curl -fsSL "${REPO}/chrome-setup.sh" -o "${TMPDIR}/chrome-setup.sh"
curl -fsSL "${REPO}/vscode-setup.sh" -o "${TMPDIR}/vscode-setup.sh"
chmod +x "${TMPDIR}"/*.sh

echo "🚀 Starting setup..."
echo ""

# Run pre-install then main install, both interactive
bash -i "${TMPDIR}/pre-install.sh" && bash -i "${TMPDIR}/install-macos.sh"

# Cleanup
rm -rf "${TMPDIR}"
