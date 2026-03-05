---
description: Expand a snippet by trigger keyword
argument-hint: [trigger|trigger1+trigger2] [--tag=tag]
allowed-tools: [Bash, Read, Glob]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Expand a snippet from `~/.claude/snippets/`.

**Step 1:** Read config:
!`cat ~/.claude/snippets/config.json 2>/dev/null || echo '{"snippets_dir":"~/.claude/snippets","separator":"\n\n---\n\n"}'`

**Step 2:** Parse the arguments:

- If no arguments: run `/snippet-list` instead (show all snippets for the user to choose)
- If argument contains `+`: split on `+` to get multiple triggers (chained composition)
- If argument starts with `--tag=`: extract tag name, find all snippets with that tag
- Otherwise: single trigger lookup

**Step 3:** For each trigger, find and read the snippet file:

!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && echo "---FILE:$f---" && cat "$f" && echo "---END---"; done 2>/dev/null`

Match the `trigger:` field in frontmatter to find the right file(s). If not found, suggest similar triggers or tell user to run `/snippet-list`.

**Step 4:** Resolve composition chain:

For each snippet, in order:
1. If it has a `compose: [a, b, c]` field, recursively expand each composed snippet first (prepend before body)
2. Scan the body for `{{snippet:trigger}}` references and recursively expand those inline
3. Track visited snippets to detect circular references. If circular, stop and report: "Circular snippet reference detected: a -> b -> a"

Concatenate composed parts with the separator from config.

**Step 5:** Resolve built-in placeholders in the expanded text:

| Placeholder | Resolution |
|-------------|------------|
| `{{date}}` | Run: `date +%Y-%m-%d` |
| `{{date:FORMAT}}` | Run: `date +FORMAT` (convert strftime format) |
| `{{time}}` | Run: `date +%H:%M` |
| `{{datetime}}` | Run: `date -u +%Y-%m-%dT%H:%M:%S` |
| `{{timestamp}}` | Run: `date +%s` |
| `{{clipboard}}` | Run: `pbpaste` |
| `{{cwd}}` | Run: `pwd` |
| `{{git_branch}}` | Run: `git branch --show-current 2>/dev/null \|\| echo "none"` |
| `{{user_name}}` | Run: `whoami` |
| `{{hostname}}` | Run: `hostname` |
| `{{random_uuid}}` | Run: `uuidgen \| tr '[:upper:]' '[:lower:]'` |
| `{{shell:CMD}}` | Execute CMD and use stdout |
| `{{file:PATH}}` | Read file at PATH |

Also check config `placeholders` object for custom overrides.

For `{{name:default}}` syntax: extract default value, use it if user doesn't provide a value.

**Step 6:** Identify remaining unresolved `{{placeholders}}`:

- Collect all `{{word}}` patterns not yet resolved
- These are custom placeholders that need user input
- Ask the user for each value, or infer from surrounding conversation context
- If a placeholder has a default (`:default` syntax), offer the default

**Step 7:** Output the fully expanded text.

Present the expanded snippet content. This becomes the working instruction for Claude to act on. Do NOT wrap it in code blocks or say "here is the expanded snippet" — treat it as the user's actual message and respond to it naturally.
