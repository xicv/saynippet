---
name: compose
description: Interactively compose a new snippet from existing ones. Use when the user wants to combine, chain, or compose snippets together.
allowed-tools: Bash, Read, Write, Glob
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Create a new composed snippet by combining existing ones.

**Step 1:** List all available snippets grouped by category:
!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && echo "---FILE:$f---" && head -15 "$f" && echo "---END---"; done 2>/dev/null`

Display as:
```
Available snippets:
  [category] trigger1, trigger2, trigger3
  [category] trigger4, trigger5
```

**Step 2:** Ask user to select snippets to compose (comma-separated triggers).

**Step 3:** Read each selected snippet and show a preview of the composed expansion (concatenated with separator from config).

**Step 4:** Ask for the new composed snippet's metadata:
- **trigger** (required): new trigger keyword
- **description** (required): what this composition does
- **category** (optional)
- **tags** (optional)
- **Additional body text** (optional): text to append after the composed snippets

**Step 5:** Write the new snippet with `compose` field:

```
---
trigger: <new-trigger>
description: <description>
category: <category>
tags: [<tags>]
compose: [<selected-trigger-1>, <selected-trigger-2>]
---
<additional body text if provided>
```

Write to `~/.claude/snippets/<new-trigger>.md`

**Step 6:** Confirm: "Created composed snippet `<trigger>` from [list]. Preview with `/snip:preview <trigger>`"
