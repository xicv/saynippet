---
description: Delete a snippet file
argument-hint: [trigger]
allowed-tools: [Bash, Read, Glob]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Delete a snippet from `~/.claude/snippets/`.

**Step 1:** If no trigger argument, run `/snippet-list` and ask which to delete.

**Step 2:** Find the snippet file by matching trigger:
!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && echo "---FILE:$f---" && head -10 "$f" && echo "---END---"; done 2>/dev/null`

**Step 3:** Show the snippet content and ask for confirmation: "Delete snippet `<trigger>`? This cannot be undone. (yes/no)"

**Step 4:** If confirmed, check if other snippets reference this one (via compose or {{snippet:trigger}}):
!`grep -rl "TRIGGER_NAME" ~/.claude/snippets/*.md 2>/dev/null`

If referenced, warn: "This snippet is referenced by other snippets. Deleting it will break those compositions. Continue? (yes/no)"

**Step 5:** Delete the file:
!`rm ~/.claude/snippets/<trigger>.md`

**Step 6:** Confirm: "Deleted snippet `<trigger>`"
