---
name: edit
description: Edit an existing snippet
argument-hint: "[trigger]"
allowed-tools: Bash, Read, Edit, Glob
disable-model-invocation: true
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Edit an existing snippet in `~/.claude/snippets/`.

**Step 1:** If no trigger argument provided, run `/snip:list` and ask user which snippet to edit.

**Step 2:** Find the snippet file:
!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && echo "---FILE:$f---" && head -10 "$f" && echo "---END---"; done 2>/dev/null`

Match the `trigger:` field to find the file path.

**Step 3:** Read the full snippet file and display it to the user.

**Step 4:** Ask the user what they want to change:
- Trigger keyword
- Description
- Category / Tags
- Compose dependencies
- Body content

**Step 5:** Use the Edit tool to make the changes to the file.

**Step 6:** Confirm: "Updated snippet `<trigger>` at `<path>`"
