#!/bin/bash
cd "/c/Users/Dell/Documents/Notes" || { echo "Repo not found: /c/Users/Dell/Documents/Notes"; exit 1; }
echo "=== commit & push ==="
changes=$(git status --porcelain)
if [ -z "$changes" ]; then
  echo "No changes to commit."
else
  git status --short
  read -p "Enter commit message (leave empty for 'Quick commit'): " msg
  [ -z "$msg" ] && msg="Quick commit"
  git add .
  git commit -m "$msg"
  git push
fi
echo
read -p "Press Enter to close..."
