---
description: Save repeated prompts from conversation history as snippets
argument-hint: [count] [--search=keyword]
allowed-tools: [Bash, Read, Write, Glob, Grep]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Browse Claude Code conversation history and save repeated prompts as snippets.

**Step 1:** Read config for history settings:
!`cat ~/.claude/snippets/config.json 2>/dev/null || echo '{"history":{"max_days":30,"min_frequency":2}}'`

**Step 2:** Scan conversation history JSONL files for user messages:

!`find ~/.claude/projects/ -name "*.jsonl" -mtime -30 2>/dev/null | head -20`

For each file found, extract user messages:
!`find ~/.claude/projects/ -name "*.jsonl" -mtime -30 -exec grep -h '"type":"user"' {} \; 2>/dev/null | head -200`

Parse each line as JSON, extract the message content from the `message.content` field (handle both string and array content formats where array contains objects with `type: "text"`).

**Step 3:** If `--search=keyword` argument provided, filter messages containing that keyword.

**Step 4:** Group similar messages:
- Normalize whitespace and case
- Group messages that share 70%+ similar words
- Count frequency of each group
- Sort by frequency (descending), then recency

**Step 5:** Display the top N results (default 10, or user-specified count):

```
Recent repeated prompts (last 30 days):

  1. [x5] "Search the web for the latest docs on..."
  2. [x3] "Review this code for security issues..."
  3. [x3] "Can you create a PR with a good description"
  ...
```

**Step 6:** Ask user to select by number.

**Step 7:** Show the selected message and ask: "This prompt was sent N times. Would you like to refine it before saving? (yes/no)"

If yes:
- Analyze the raw prompt for its intent
- Identify variable parts (specific file names, topics, URLs, version numbers) and convert to `{{placeholders}}`
- Rewrite for clarity as a reusable template
- Preserve the user's voice and intent
- Show before/after for approval

If no: use the raw text as-is.

**Step 8:** Ask for snippet metadata (trigger, description, category, tags).

**Step 9:** Write the snippet to `~/.claude/snippets/<trigger>.md` with proper YAML frontmatter.

**Step 10:** Confirm: "Created snippet `<trigger>` from conversation history."
