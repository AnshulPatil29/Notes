#!/bin/bash
cd "/c/Users/Dell/Documents/Notes" || { echo "Repo not found"; exit 1; }
while true; do
  clear
  echo "1) Pull"
  echo "2) Commit & Push"
  echo "3) Revert (dangerous)"
  echo "4) Exit"
  read -p "Choose an action [1-4]: " choice
  case "$choice" in
    1) git pull; read -p "Done. Press Enter to continue..." ;;
    2)
      changes=$(git status --porcelain)
      if [ -z "$changes" ]; then echo "No changes to commit."; read -p "Press Enter to continue..."; else
        git status --short
        read -p "Commit message (leave empty for 'Quick commit'): " msg
        [ -z "$msg" ] && msg="Quick commit"
        git add .
        git commit -m "$msg"
        git push
        read -p "Done. Press Enter to continue..."
      fi
      ;;
    3)
      read -p "Type YES to discard uncommitted changes: " c
      if [ "$c" = "YES" ]; then git reset --hard; git clean -fd; echo "Discarded."; else echo "Cancelled."; fi
      read -p "Press Enter to continue..."
      ;;
    4) break ;;
    *) echo "Invalid choice."; sleep 1 ;;
  esac
done

