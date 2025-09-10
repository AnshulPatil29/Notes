#!/bin/bash
cd "/c/Users/Dell/Documents/Notes" || { echo "Repo not found: /c/Users/Dell/Documents/Notes"; exit 1; }
echo "=== git pull ==="
git pull
echo
read -p "Press Enter to close..."
