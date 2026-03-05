---
description: List all available snippets with filtering
argument-hint: [keyword] [--cat=category]
allowed-tools: [Bash, Read, Glob]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

List all snippet files in `~/.claude/snippets/`.

**Step 1:** Read config to get snippets directory:
!`cat ~/.claude/snippets/config.json 2>/dev/null || echo '{"snippets_dir":"~/.claude/snippets"}'`

**Step 2:** List all snippet .md files and parse their frontmatter:
!`for f in ~/.claude/snippets/*.md; do [ -f "$f" ] && head -20 "$f"; echo "---FILE_END---"; done 2>/dev/null || echo "NO_SNIPPETS"`

**Step 3:** Format the output

Parse each snippet's YAML frontmatter to extract: trigger, description, category, tags, compose.

Group by category and display as:

```
Snippets (N total):

[category]
  trigger      - description                    [tags] [compose: a,b]
  trigger2     - description2
```

**Filtering:**
- If user provided a keyword argument, filter snippets where trigger, description, or tags contain the keyword (case-insensitive)
- If user provided `--cat=X`, filter to only that category
- If no snippets found, tell user: "No snippets found. Create one with `/snippet-add`"
