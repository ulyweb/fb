#!/bin/bash

set -e

echo "🚀 Starting File Browser auto-setup..."

# 1. Install File Browser if not present
if ! command -v filebrowser &> /dev/null; then
  echo "📦 Installing File Browser..."
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
else
  echo "✅ File Browser already installed."
fi

# 2. Create config file if missing
if [ ! -f .filebrowser.json ]; then
  echo "🛠 Creating File Browser config..."
  filebrowser config init
fi

# 3. Create DB if missing
if [ ! -f filebrowser.db ]; then
  echo "🔐 Creating default admin user..."
  filebrowser users add admin admin --perm.admin
fi

# 4. Launch File Browser
echo "🌐 Launching File Browser at http://localhost:8080"
filebrowser -r . -p 8080
