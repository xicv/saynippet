---
name: preview
description: Preview snippet expansion without executing
argument-hint: "[trigger|trigger1+trigger2]"
allowed-tools: Bash, Read, Glob
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Preview how a snippet expands without treating it as an instruction.

**Step 1:** Follow the same resolution process as `/snip:expand` (Steps 1-5: parse args, find files, resolve composition, resolve built-in placeholders).

Read config:
!`cat ~/.claude/snippets/config.json 2>/dev/null || echo '{"snippets_dir":"~/.claude/snippets","separator":"\n\n---\n\n"}'`

Find and read all snippets:
!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && echo "---FILE:$f---" && cat "$f" && echo "---END---"; done 2>/dev/null`

**Step 2:** For custom (unresolved) placeholders, do NOT prompt the user. Instead, display them as `[PLACEHOLDER_NAME]` markers.

**Step 3:** Display the result in a code block with a header:

```
Preview of snippet: <trigger>
Composed from: <list of all snippets in chain>
Custom placeholders needed: <list>

---
<expanded text with [PLACEHOLDER] markers>
---
```

Do NOT act on the expanded text. This is preview-only.
