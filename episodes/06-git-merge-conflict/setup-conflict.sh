#!/usr/bin/env bash
# Builds a tiny repo where `main` and `feature` edit the same line, so `git merge feature`
# produces a real conflict you can practice resolving. Safe: lives in /tmp.
set -e
DIR="${1:-/tmp/merge-conflict-demo}"
rm -rf "$DIR"
git init -q -b main "$DIR"
cd "$DIR"
git config user.name "you"; git config user.email "you@example.com"
printf 'Hello from main!\n' > greeting.txt
git add greeting.txt && git commit -q -m "Add greeting"
git checkout -q -b feature
printf 'Hello from the feature branch!\n' > greeting.txt
git commit -q -am "Update greeting on feature"
git checkout -q main
printf 'Hello from main, updated!\n' > greeting.txt
git commit -q -am "Update greeting on main"
echo "Demo ready in $DIR"
echo "Now run:  cd $DIR && git merge feature"
