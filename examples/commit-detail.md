---
trigger: commit-detail
description: Create a detailed conventional commit message
tags: [git, workflow]
category: code
---
Analyze all staged changes with `git diff --cached`.

Write a conventional commit message:
- Type: feat|fix|refactor|docs|test|chore|perf|ci
- Scope: the component or area affected
- Subject: imperative mood, under 72 chars
- Body: explain WHY the change was made, not just WHAT
- Footer: reference any issues (Fixes #N, Closes #N)
