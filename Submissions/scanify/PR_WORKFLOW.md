# Open a PR: clone another repo, put this repo in a branch, then PR

Use this when the target is a **different** repo (e.g. Reactiv ClipKit Lab). You clone that repo, create a branch, copy **this** repo’s contents into it, push the branch, and open a PR against that repo.

---

## 1. Fork the target repo (if you don’t have push access)

If you’re submitting to **Reactiv ClipKit Lab**:

1. Go to **https://github.com/reactivapp/reactivapp-clipkit-lab**
2. Click **Fork** and create a fork under your account (e.g. `https://github.com/MarcDasilva/reactivapp-clipkit-lab`).

You’ll push to your fork and then open a PR from your fork to the original repo.

---

## Manual copy

Use these commands. **Important:** the destination is the clone path; you can run from any directory.

**1. Go to the clone and create the branch**

```bash
cd /Users/marc/reactivapp-clipkit-lab
git checkout -b submission/scanify
```

**2. Copy everything from scanify into the clone** (do **not** copy `.git` — the clone keeps its own).

Using **rsync** (recommended — one command, overwrites cleanly):

```bash
rsync -a /Users/marc/scanify/ /Users/marc/reactivapp-clipkit-lab/ \
  --exclude='.git' \
  --exclude='.DS_Store' \
  --exclude='*.xcuserstate' \
  --exclude='DerivedData'
```

Using **cp** only (run each line; destination is the full path to the clone):

```bash
CLONE=/Users/marc/reactivapp-clipkit-lab
SRC=/Users/marc/scanify

cp -R "$SRC/ReactivChallengeKit" "$CLONE/"
cp -R "$SRC/Submissions" "$CLONE/"
cp -R "$SRC/scripts" "$CLONE/"
cp -R "$SRC/docs" "$CLONE/"
cp -R "$SRC/assets" "$CLONE/"
cp -R "$SRC/.github" "$CLONE/"
cp "$SRC/README.md" "$SRC/CLAUDE.md" "$SRC/.gitignore" "$CLONE/"
```

**3. Commit and push**

```bash
cd /Users/marc/reactivapp-clipkit-lab
git add -A
git status
git commit -m "Add Scanify submission"
git push -u origin submission/scanify
```

Then open a PR from your fork’s `submission/scanify` to the upstream repo.

---

## 2. Open the Pull Request

- Go to the **original** repo (e.g. **https://github.com/reactivapp/reactivapp-clipkit-lab**).
- You should see a banner like “submission/scanify had recent pushes” with **Compare & pull request** (if you pushed from a fork, GitHub often shows this after the push).
- Or: **Pull requests** → **New pull request** → set **base** to the upstream default (e.g. `main`) and **compare** to your fork’s branch `submission/scanify`.
- Add title and description, then **Create pull request**.

Direct link pattern (replace `YOUR_FORK` with your GitHub username):

```
https://github.com/reactivapp/reactivapp-clipkit-lab/compare/main...YOUR_FORK:reactivapp-clipkit-lab:submission/scanify?expand=1
```

---

## Summary

| Step | Action                                                                                                                                                                                        |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | Fork `reactivapp/reactivapp-clipkit-lab` (if needed).                                                                                                                                         |
| 2    | Clone your fork, create branch `submission/scanify`, copy this repo in (rsync or cp), then `git add -A` → `git commit -m "Add Scanify submission"` → `git push -u origin submission/scanify`. |
| 3    | On GitHub, open a PR from your fork’s `submission/scanify` to upstream `main`.                                                                                                                |

---

## Options

- **Different clone path:** use that path instead of `/Users/marc/reactivapp-clipkit-lab` in the copy and `cd` commands.
- **Different branch name:** use it in `git checkout -b`, `git push -u origin`, and when opening the PR.
