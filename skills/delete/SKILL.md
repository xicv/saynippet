---
name: delete
description: Delete a snippet file
argument-hint: "[trigger]"
allowed-tools: Bash, Read, Glob
disable-model-invocation: true
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Delete a snippet from `~/.claude/snippets/`.

**Step 1:** If no trigger argument, run `/snip:list` and ask which to delete.

**Step 2:** Find the snippet file by matching trigger:
!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && echo "---FILE:$f---" && head -10 "$f" && echo "---END---"; done 2>/dev/null`

**Step 3:** Show the snippet content and ask for confirmation: "Delete snippet `<trigger>`? This cannot be undone. (yes/no)"

**Step 4:** If confirmed, check if other snippets reference this one (via compose or `{{snippet:trigger}}`):

Run: `grep -rl "<trigger>" ~/.claude/snippets/*.md` to find any files that reference it in their `compose` field or as `{{snippet:<trigger>}}`.

If referenced, warn: "This snippet is referenced by other snippets. Deleting it will break those compositions. Continue? (yes/no)"

**Step 5:** If the user confirms, delete the file using Bash:

Run: `rm ~/.claude/snippets/<trigger>.md`

**Step 6:** Confirm: "Deleted snippet `<trigger>`"
