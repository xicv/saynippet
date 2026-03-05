---
name: saynippet
description: >-
  Snippet management and inline expansion for Claude Code. Use when the user mentions
  snippets, templates, text expansion, saving prompts, composing prompts, or when
  user messages contain inline snippet triggers (prefix + keyword patterns like
  #search, #think, #review). Also triggers when user says "save this as a snippet",
  "I keep typing this", "save from history", "combine snippets", "list my snippets",
  or "expand snippet".
---

# SayNippet - Snippet Management Skill

You manage reusable text snippets stored as Markdown files in `~/.claude/snippets/`.

## Available Commands

| Command | Alias | Purpose |
|---------|-------|---------|
| `/snippet <trigger>` | `/snip` | Expand a snippet |
| `/snippet-add <trigger>` | `/snip-add` | Create a new snippet |
| `/snippet-list [filter]` | `/snip-list` | List all snippets |
| `/snippet-edit <trigger>` | - | Edit a snippet |
| `/snippet-delete <trigger>` | - | Delete a snippet |
| `/snippet-save` | - | Save from conversation |
| `/snippet-compose` | `/snip-compose` | Interactive composition builder |
| `/snippet-preview <trigger>` | `/snip-preview` | Preview expansion |
| `/snippet-history` | `/snip-history` | Save from conversation history |

## Inline Trigger Detection

Read the config to determine the prefix character:

!`cat ~/.claude/snippets/config.json 2>/dev/null | grep '"prefix"' | sed 's/.*"prefix": *"//' | sed 's/".*//' || echo "#"`

When the user's message contains patterns matching `<prefix><word>` (e.g., `#search`, `#think`):

1. List known snippet triggers:
   !`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && grep "^trigger:" "$f" | sed 's/trigger: //'; done 2>/dev/null`

2. For each `<prefix><word>` in the user's message, check if `<word>` matches a known trigger

3. If matches found:
   - Read each matched snippet file
   - Resolve composition (compose field, {{snippet:...}} refs)
   - Resolve built-in placeholders
   - Replace the `<prefix><word>` in the user's message with the expanded snippet body
   - For custom placeholders, infer values from the surrounding message context
   - Treat the fully expanded message as the user's instruction and act on it

4. Escaped triggers (`\#word`) should be left as literal `#word` (strip the backslash)

5. If no matches: treat the message normally (the prefix character may just be a regular character)

## Auto-Detection Patterns

When the user says something matching these patterns, route to the appropriate command:

| User says... | Action |
|-------------|--------|
| "save this as a snippet" / "add to snippets" | `/snippet-save` |
| "list snippets" / "show my snippets" | `/snippet-list` |
| "edit snippet X" / "update snippet X" | `/snippet-edit X` |
| "delete snippet X" / "remove snippet X" | `/snippet-delete X` |
| "combine snippets" / "compose" / "chain" | `/snippet-compose` |
| "I keep typing this" / "save from history" | `/snippet-history` |
| "use my X snippet" / "expand X" | `/snippet X` |
| "preview snippet X" | `/snippet-preview X` |

## Snippet Format Reference

Each snippet is a Markdown file in `~/.claude/snippets/` with:

```yaml
---
trigger: keyword        # Required: unique trigger
description: text       # What this snippet does
category: group         # Grouping (default: general)
tags: [a, b]           # For search and tag-based composition
compose: [x, y]        # Prepend other snippets before body
---
Template body with {{placeholders}}
```

### Built-in Placeholders
`{{date}}`, `{{time}}`, `{{datetime}}`, `{{timestamp}}`, `{{clipboard}}`, `{{cwd}}`, `{{git_branch}}`, `{{user_name}}`, `{{hostname}}`, `{{random_uuid}}`, `{{shell:cmd}}`, `{{file:path}}`

### Composition Methods
1. `compose: [a, b]` in frontmatter (auto-prepend)
2. `{{snippet:trigger}}` in body (inline nesting)
3. `/snippet a+b+c` (ad-hoc chaining with +)
4. `/snippet --tag=X` (all snippets with tag X)
