# 06 — Fix a Git Merge Conflict

## 🎬 Watch

[![Watch on YouTube](https://img.youtube.com/vi/GrjrgR89FzY/maxresdefault.jpg)](https://youtu.be/GrjrgR89FzY)

▶️ **Watch: https://youtu.be/GrjrgR89FzY**


> A conflict isn't an error you broke — it's git asking which version wins. Here's the
> drill, with a script that reproduces a real conflict so you can practice.

📺 Video: _(soon)_

## Make a conflict to practice on
```bash
./setup-conflict.sh        # builds a tiny repo where main & feature edit the same line
cd /tmp/merge-conflict-demo 2>/dev/null || true
git merge feature          # -> CONFLICT (content): Merge conflict in greeting.txt
```

## Resolve it
1. Open the file. Git wrapped both versions in markers:
   ```
   <<<<<<< HEAD          your current branch (main)
   =======
   >>>>>>> feature       the incoming branch
   ```
2. Keep what you want (yours, theirs, or both) and **delete all three marker lines**.
   In VS Code: the *Accept Current / Incoming / Both* buttons do this for you.
3. Stage and commit:
   ```bash
   git add greeting.txt
   git commit --no-edit
   ```

## Escape hatch
```bash
git merge --abort     # rewinds to before the merge — nothing lost
```
