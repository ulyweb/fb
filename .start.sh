#!/bin/bash

# Optional: Create config if it doesn't exist
if [ ! -f .filebrowser.json ]; then
  echo "Initializing File Browser config..."
  filebrowser config init
fi

# Launch File Browser on port 8080 with root as the current directory
filebrowser -r . -p 8080
