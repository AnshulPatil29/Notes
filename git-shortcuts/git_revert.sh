cat > /c/Users/Dell/Documents/Notes/git-shortcuts/git_revert.sh <<'EOF'
#!/bin/bash
cd "/c/Users/Dell/Documents/Notes" || { echo "Repo not found: /c/Users/Dell/Documents/Notes"; exit 1; }
echo "=== REVERT: discard local uncommitted changes AND remove untracked files ==="
echo "This cannot be undone."
read -p "Type YES to confirm and proceed: " confirm
if [ "$confirm" = "YES" ]; then
  git reset --hard
  git clean -fd
  echo "Local changes discarded."
else
  echo "Cancelled."
fi
echo
read -p "Press Enter to close..."
EOF

