#!/bin/bash

set -e

echo "🚀 Starting File Browser auto-setup..."

# STEP 1: Install File Browser if missing
if ! command -v filebrowser &> /dev/null; then
  echo "📦 File Browser not found. Installing..."
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
else
  echo "✅ File Browser is already installed."
fi

# STEP 2: Ensure config and DB exist
if [ ! -f .filebrowser.json ]; then
  echo "🛠 Initializing File Browser config..."
  filebrowser config init
fi

if [ ! -f filebrowser.db ]; then
  echo "🗂 Creating File Browser DB..."
  filebrowser users add admin admin --perm.admin
fi

# STEP 3: Run File Browser
echo "🌐 Launching File Browser on port 8080..."
filebrowser -r . -p 8080
