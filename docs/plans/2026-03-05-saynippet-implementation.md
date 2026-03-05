# SayNippet Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code plugin for managing reusable text snippets stored as Markdown files, with composition, inline triggers, and history-based creation.

**Architecture:** Plugin with commands in `~/.claude/plugins/saynippet/commands/`, a SKILL.md for auto-detection, shell scripts for snippet resolution, and snippet storage in `~/.claude/snippets/`. Each snippet is a Markdown file with YAML frontmatter. Placeholders use `{{variable}}` syntax resolved by Claude at expansion time.

**Tech Stack:** Claude Code plugin system (Markdown commands with YAML frontmatter), Bash scripts, YAML/Markdown parsing

---

### Task 1: Plugin scaffold and config

**Files:**
- Create: `plugin.json`
- Create: `README.md`
- Create: `LICENSE`

**Step 1: Create plugin.json**

```json
{
  "name": "saynippet",
  "version": "0.1.0",
  "description": "Snippet management for Claude Code. Create, compose, and expand reusable prompt templates stored as Markdown files.",
  "author": {
    "name": "Xi Cao"
  },
  "repository": "https://github.com/xicao/saynippet",
  "license": "MIT",
  "keywords": [
    "snippets",
    "templates",
    "text-expander",
    "prompt-management",
    "composition"
  ]
}
```

Write to: `/Users/xicao/Projects/saynippet/plugin.json`

**Step 2: Create LICENSE (MIT)**

Write MIT license to `/Users/xicao/Projects/saynippet/LICENSE`

**Step 3: Create README.md**

Write a brief README with installation instructions and feature overview to `/Users/xicao/Projects/saynippet/README.md`

**Step 4: Create snippets directory with default config**

```bash
mkdir -p ~/.claude/snippets
```

Write default config to `~/.claude/snippets/config.json`:
```json
{
  "prefix": "#",
  "snippets_dir": "~/.claude/snippets",
  "default_category": "general",
  "separator": "\n\n---\n\n",
  "history": {
    "max_days": 30,
    "min_frequency": 2
  },
  "placeholders": {}
}
```

**Step 5: Commit**

```bash
git add plugin.json LICENSE README.md
git commit -m "feat: scaffold plugin with manifest and config"
```

---

### Task 2: /snippet-list command

The simplest command — list all snippets. Build this first to validate the command system works.

**Files:**
- Create: `commands/snippet-list.md`
- Create: `commands/snip-list.md` (alias)

**Step 1: Create snippet-list command**

Write to `commands/snippet-list.md`:

```markdown
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
```

**Step 2: Create alias**

Write to `commands/snip-list.md`:

```markdown
---
description: List all available snippets (alias for /snippet-list)
argument-hint: [keyword] [--cat=category]
allowed-tools: [Bash, Read, Glob]
---

Run the /snippet-list command with these arguments: $ARGUMENTS
```

**Step 3: Commit**

```bash
git add commands/snippet-list.md commands/snip-list.md
git commit -m "feat: add /snippet-list command with filtering"
```

---

### Task 3: /snippet-add command

**Files:**
- Create: `commands/snippet-add.md`
- Create: `commands/snip-add.md` (alias)

**Step 1: Create snippet-add command**

Write to `commands/snippet-add.md`:

```markdown
---
description: Create a new snippet interactively
argument-hint: [trigger]
allowed-tools: [Bash, Read, Write, Glob]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Create a new snippet in `~/.claude/snippets/`.

**Step 1:** Read config:
!`cat ~/.claude/snippets/config.json 2>/dev/null || echo '{"snippets_dir":"~/.claude/snippets","default_category":"general"}'`

**Step 2:** Gather snippet details from the user. If a trigger was provided as argument ($ARGUMENTS), use it. Otherwise ask for each:

1. **trigger** (required): The keyword to invoke this snippet. Must be unique, lowercase, hyphens allowed. Check it doesn't conflict with an existing snippet:
   !`ls ~/.claude/snippets/*.md 2>/dev/null | xargs -I{} head -5 {} | grep "^trigger:" | sed 's/trigger: //'`

2. **description** (required): A short human-readable description of what this snippet does.

3. **category** (optional): Category for grouping. Default from config.

4. **tags** (optional): Comma-separated tags for search and composition. Format as YAML array.

5. **compose** (optional): Comma-separated list of other snippet triggers to include before this one.

6. **body** (required): The template text. Tell the user they can use:
   - `{{placeholder}}` for dynamic values (built-in: date, time, clipboard, cwd, git_branch, user_name, hostname, random_uuid)
   - `{{shell:command}}` for shell command output
   - `{{file:path}}` for file content inclusion
   - `{{snippet:trigger}}` to nest other snippets
   - `{{name:default}}` for placeholders with defaults
   - Any other `{{custom}}` will prompt the user at expansion time

**Step 3:** Assemble the Markdown file with YAML frontmatter and write it:

```
---
trigger: <trigger>
description: <description>
category: <category>
tags: [<tags>]
compose: [<compose>]  # only if provided
---
<body>
```

Write to `~/.claude/snippets/<trigger>.md`

**Step 4:** Confirm creation: "Created snippet `<trigger>` at `~/.claude/snippets/<trigger>.md`"
```

**Step 2: Create alias**

Write to `commands/snip-add.md`:

```markdown
---
description: Create a new snippet (alias for /snippet-add)
argument-hint: [trigger]
allowed-tools: [Bash, Read, Write, Glob]
---

Run the /snippet-add command with these arguments: $ARGUMENTS
```

**Step 3: Commit**

```bash
git add commands/snippet-add.md commands/snip-add.md
git commit -m "feat: add /snippet-add command for creating snippets"
```

---

### Task 4: /snippet command (main expand)

The core command. Reads a snippet, resolves composition and placeholders, outputs the expanded text.

**Files:**
- Create: `commands/snippet.md`
- Create: `commands/snip.md` (alias)

**Step 1: Create snippet command**

Write to `commands/snippet.md`:

```markdown
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
| `{{date}}` | !`date +%Y-%m-%d` |
| `{{date:FORMAT}}` | !`date +FORMAT` (convert strftime) |
| `{{time}}` | !`date +%H:%M` |
| `{{datetime}}` | !`date -u +%Y-%m-%dT%H:%M:%S` |
| `{{timestamp}}` | !`date +%s` |
| `{{clipboard}}` | !`pbpaste` |
| `{{cwd}}` | !`pwd` |
| `{{git_branch}}` | !`git branch --show-current 2>/dev/null || echo "none"` |
| `{{user_name}}` | !`whoami` |
| `{{hostname}}` | !`hostname` |
| `{{random_uuid}}` | !`uuidgen \| tr '[:upper:]' '[:lower:]'` |
| `{{shell:CMD}}` | Execute CMD and use stdout |
| `{{file:PATH}}` | Read PATH content |

Also check config `placeholders` object for custom overrides.

For `{{name:default}}` syntax: extract default value, use it if user doesn't provide a value.

**Step 6:** Identify remaining unresolved `{{placeholders}}`:

- Collect all `{{word}}` patterns not yet resolved
- These are custom placeholders that need user input
- Ask the user for each value, or infer from surrounding conversation context
- If a placeholder has a default (`:default` syntax), offer the default

**Step 7:** Output the fully expanded text.

Present the expanded snippet content. This becomes the working instruction for Claude to act on. Do NOT wrap it in code blocks or say "here is the expanded snippet" — treat it as the user's actual message and respond to it naturally.
```

**Step 2: Create alias**

Write to `commands/snip.md`:

```markdown
---
description: Expand a snippet by trigger keyword (alias for /snippet)
argument-hint: [trigger|trigger1+trigger2] [--tag=tag]
allowed-tools: [Bash, Read, Glob]
---

Run the /snippet command with these arguments: $ARGUMENTS
```

**Step 3: Commit**

```bash
git add commands/snippet.md commands/snip.md
git commit -m "feat: add /snippet command with composition and placeholder resolution"
```

---

### Task 5: /snippet-edit command

**Files:**
- Create: `commands/snippet-edit.md`

**Step 1: Create snippet-edit command**

Write to `commands/snippet-edit.md`:

```markdown
---
description: Edit an existing snippet
argument-hint: [trigger]
allowed-tools: [Bash, Read, Edit, Glob]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Edit an existing snippet in `~/.claude/snippets/`.

**Step 1:** If no trigger argument provided, run `/snippet-list` and ask user which snippet to edit.

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
```

**Step 2: Commit**

```bash
git add commands/snippet-edit.md
git commit -m "feat: add /snippet-edit command"
```

---

### Task 6: /snippet-delete command

**Files:**
- Create: `commands/snippet-delete.md`

**Step 1: Create snippet-delete command**

Write to `commands/snippet-delete.md`:

```markdown
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
!`grep -l "trigger_name" ~/.claude/snippets/*.md 2>/dev/null`

If referenced, warn: "This snippet is referenced by: X, Y. Deleting it will break those compositions. Continue? (yes/no)"

**Step 5:** Delete the file:
```bash
rm ~/.claude/snippets/<trigger>.md
```

**Step 6:** Confirm: "Deleted snippet `<trigger>`"
```

**Step 2: Commit**

```bash
git add commands/snippet-delete.md
git commit -m "feat: add /snippet-delete command with reference checking"
```

---

### Task 7: /snippet-save command

**Files:**
- Create: `commands/snippet-save.md`

**Step 1: Create snippet-save command**

Write to `commands/snippet-save.md`:

```markdown
---
description: Quick-save text from conversation as a snippet
allowed-tools: [Bash, Read, Write, Glob]
---

## Instructions

Save text from the current conversation as a new snippet.

**Step 1:** Ask the user: "What text would you like to save as a snippet? You can:
- Paste the text directly
- Say 'last message' to save your previous message
- Describe what to save from this conversation"

**Step 2:** Once you have the text, analyze it:
- Identify parts that should be `{{placeholders}}` (specific names, paths, URLs, topics that would change each use)
- Suggest converting those to placeholders
- Show the user the template version for approval

**Step 3:** Ask for snippet metadata:
- **trigger** (required): keyword to invoke
- **description** (required): what this snippet does
- **category** (optional): grouping
- **tags** (optional): for search/composition

**Step 4:** Write the snippet file to `~/.claude/snippets/<trigger>.md` with proper frontmatter.

**Step 5:** Confirm: "Saved snippet `<trigger>` at `~/.claude/snippets/<trigger>.md`"
```

**Step 2: Commit**

```bash
git add commands/snippet-save.md
git commit -m "feat: add /snippet-save command for quick-saving from conversation"
```

---

### Task 8: /snippet-compose command

**Files:**
- Create: `commands/snippet-compose.md`
- Create: `commands/snip-compose.md` (alias)

**Step 1: Create snippet-compose command**

Write to `commands/snippet-compose.md`:

```markdown
---
description: Interactively compose a new snippet from existing ones
allowed-tools: [Bash, Read, Write, Glob]
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

```markdown
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

**Step 6:** Confirm: "Created composed snippet `<trigger>` from [list]. Preview with `/snippet-preview <trigger>`"
```

**Step 2: Create alias**

Write to `commands/snip-compose.md`:

```markdown
---
description: Interactively compose a new snippet (alias for /snippet-compose)
allowed-tools: [Bash, Read, Write, Glob]
---

Run the /snippet-compose command with these arguments: $ARGUMENTS
```

**Step 3: Commit**

```bash
git add commands/snippet-compose.md commands/snip-compose.md
git commit -m "feat: add /snippet-compose command for interactive composition"
```

---

### Task 9: /snippet-preview command

**Files:**
- Create: `commands/snippet-preview.md`
- Create: `commands/snip-preview.md` (alias)

**Step 1: Create snippet-preview command**

Write to `commands/snippet-preview.md`:

```markdown
---
description: Preview snippet expansion without executing
argument-hint: [trigger|trigger1+trigger2]
allowed-tools: [Bash, Read, Glob]
---

## Arguments

User arguments: $ARGUMENTS

## Instructions

Preview how a snippet expands without treating it as an instruction.

**Step 1:** Follow the same resolution process as `/snippet` (Steps 1-5: parse args, find files, resolve composition, resolve built-in placeholders).

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
```

**Step 2: Create alias**

Write to `commands/snip-preview.md`:

```markdown
---
description: Preview snippet expansion (alias for /snippet-preview)
argument-hint: [trigger|trigger1+trigger2]
allowed-tools: [Bash, Read, Glob]
---

Run the /snippet-preview command with these arguments: $ARGUMENTS
```

**Step 3: Commit**

```bash
git add commands/snippet-preview.md commands/snip-preview.md
git commit -m "feat: add /snippet-preview command for dry-run expansion"
```

---

### Task 10: /snippet-history command

**Files:**
- Create: `commands/snippet-history.md`
- Create: `commands/snip-history.md` (alias)

**Step 1: Create snippet-history command**

Write to `commands/snippet-history.md`:

```markdown
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

```bash
find ~/.claude/projects/ -name "*.jsonl" -mtime -30 -exec grep -h '"type":"user"' {} \; 2>/dev/null | head -500
```

Parse each line as JSON, extract the message content from `message.content` (handle both string and array content formats).

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

**Step 9:** Write the snippet to `~/.claude/snippets/<trigger>.md`

**Step 10:** Confirm: "Created snippet `<trigger>` from conversation history."
```

**Step 2: Create alias**

Write to `commands/snip-history.md`:

```markdown
---
description: Save repeated prompts from history (alias for /snippet-history)
argument-hint: [count] [--search=keyword]
allowed-tools: [Bash, Read, Write, Glob, Grep]
---

Run the /snippet-history command with these arguments: $ARGUMENTS
```

**Step 3: Commit**

```bash
git add commands/snippet-history.md commands/snip-history.md
git commit -m "feat: add /snippet-history command for saving from conversation history"
```

---

### Task 11: SKILL.md for auto-detection and inline triggers

**Files:**
- Create: `skills/saynippet/SKILL.md`

**Step 1: Create the skill file**

Write to `skills/saynippet/SKILL.md`:

```markdown
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
```

**Step 2: Commit**

```bash
git add skills/saynippet/SKILL.md
git commit -m "feat: add SKILL.md for auto-detection and inline triggers"
```

---

### Task 12: Starter snippets

**Files:**
- Create: `examples/search.md`
- Create: `examples/think.md`
- Create: `examples/summarize.md`
- Create: `examples/deep-research.md`
- Create: `examples/pr-description.md`
- Create: `examples/code-review.md`
- Create: `examples/commit-detailed.md`
- Create: `examples/bug-report.md`
- Create: `examples/daily-standup.md`

**Step 1: Create examples directory and individual building block snippets**

Write to `examples/search.md`:
```markdown
---
trigger: search
description: Instruct Claude to search the web thoroughly
tags: [web, research]
category: ai
---
Search the web thoroughly for the most up-to-date information on this topic.
Use multiple search queries if needed to get comprehensive coverage.
Cite all sources with links.
```

Write to `examples/think.md`:
```markdown
---
trigger: think
description: Instruct Claude to think deeply and critically
tags: [reasoning]
category: ai
---
Think step by step. Consider multiple perspectives and challenge your initial assumptions.
Identify edge cases, potential issues, and trade-offs before proposing a solution.
```

Write to `examples/summarize.md`:
```markdown
---
trigger: summarize
description: Instruct Claude to provide a concise summary
tags: [output]
category: ai
---
Provide a concise, well-structured summary of your findings.
Use bullet points for key takeaways. Keep it actionable.
```

**Step 2: Create composed snippets**

Write to `examples/deep-research.md`:
```markdown
---
trigger: deep-research
description: Combined deep research with web search, thinking, and summary
compose: [search, think, summarize]
tags: [web, research, reasoning]
category: ai
---
Apply all of the above approaches to research: {{topic}}

Provide a comprehensive analysis with cited sources.
```

Write to `examples/pr-description.md`:
```markdown
---
trigger: pr-desc
description: Generate a pull request description
tags: [git, workflow]
category: code
---
Analyze the full commit history on this branch using `git diff main...HEAD` and `git log main..HEAD`.

Write a comprehensive PR description with:

## Summary
- 1-3 bullet points explaining the changes

## Changes
- List each significant change with file references

## Test Plan
- Bulleted checklist of testing TODOs
```

Write to `examples/code-review.md`:
```markdown
---
trigger: review
description: Thorough code review with security awareness
compose: [think]
tags: [code, security]
category: code
---
Review the code for:
- **Correctness**: Logic errors, off-by-one, null handling
- **Security**: Input validation, injection, secrets exposure
- **Performance**: Unnecessary allocations, N+1 queries, missing indexes
- **Readability**: Naming, complexity, documentation needs
- **Testing**: Missing test cases, edge cases not covered

Rate each issue as CRITICAL, HIGH, MEDIUM, or LOW.
```

Write to `examples/commit-detailed.md`:
```markdown
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
```

Write to `examples/bug-report.md`:
```markdown
---
trigger: bug-report
description: Structured bug report template
tags: [debugging]
category: workflow
---
## Bug Report

**Date:** {{date}}
**Reporter:** {{user_name}}
**Branch:** {{git_branch}}

### Description
{{description}}

### Steps to Reproduce
1. {{steps}}

### Expected Behavior
{{expected}}

### Actual Behavior
{{actual}}

### Environment
- CWD: {{cwd}}
- Node: {{shell:node -v 2>/dev/null || echo "N/A"}}
- OS: {{shell:uname -s}}
```

Write to `examples/daily-standup.md`:
```markdown
---
trigger: standup
description: Daily standup update template
tags: [workflow]
category: workflow
---
## Daily Standup - {{date}}

### Yesterday
{{yesterday}}

### Today
{{today}}

### Blockers
{{blockers:None}}
```

**Step 3: Create install script for examples**

Write to `scripts/install-examples.sh`:
```bash
#!/bin/bash
# Install starter snippets to ~/.claude/snippets/
SNIPPETS_DIR="${1:-$HOME/.claude/snippets}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$SNIPPETS_DIR"

for f in "$SCRIPT_DIR"/examples/*.md; do
  name=$(basename "$f")
  if [ ! -f "$SNIPPETS_DIR/$name" ]; then
    cp "$f" "$SNIPPETS_DIR/$name"
    echo "Installed: $name"
  else
    echo "Skipped (exists): $name"
  fi
done

echo "Done. $(ls "$SNIPPETS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ') snippets total."
```

Make it executable:
```bash
chmod +x scripts/install-examples.sh
```

**Step 4: Commit**

```bash
git add examples/ scripts/install-examples.sh
git commit -m "feat: add starter snippet examples and install script"
```

---

### Task 13: Final integration and testing

**Step 1: Create directory structure for installation**

Verify the full plugin structure:
```
saynippet/
  plugin.json
  LICENSE
  README.md
  SPEC.md
  commands/
    snippet.md
    snippet-add.md
    snippet-list.md
    snippet-edit.md
    snippet-delete.md
    snippet-save.md
    snippet-compose.md
    snippet-preview.md
    snippet-history.md
    snip.md
    snip-add.md
    snip-list.md
    snip-compose.md
    snip-preview.md
    snip-history.md
  skills/
    saynippet/
      SKILL.md
  examples/
    search.md
    think.md
    summarize.md
    deep-research.md
    pr-description.md
    code-review.md
    commit-detailed.md
    bug-report.md
    daily-standup.md
  scripts/
    install-examples.sh
  docs/
    plans/
      2026-03-05-saynippet-implementation.md
```

**Step 2: Install the plugin locally for testing**

Create symlink from the project to the plugins directory:
```bash
ln -sf /Users/xicao/Projects/saynippet ~/.claude/plugins/saynippet
```

**Step 3: Install starter snippets**

```bash
bash scripts/install-examples.sh
```

**Step 4: Create default config if not exists**

```bash
[ -f ~/.claude/snippets/config.json ] || cat > ~/.claude/snippets/config.json << 'EOF'
{
  "prefix": "#",
  "snippets_dir": "~/.claude/snippets",
  "default_category": "general",
  "separator": "\n\n---\n\n",
  "history": {
    "max_days": 30,
    "min_frequency": 2
  },
  "placeholders": {}
}
EOF
```

**Step 5: Manual test checklist**

Test each command in a new Claude Code session:

1. `/snippet-list` - Should show all installed snippets grouped by category
2. `/snippet-add test-snip` - Create a test snippet interactively
3. `/snippet search` - Should expand the search snippet
4. `/snippet search+think` - Should expand both, composed
5. `/snippet-preview deep-research` - Should show composed preview with [TOPIC] placeholder
6. `/snippet-edit test-snip` - Should show and allow editing
7. `/snippet-delete test-snip` - Should delete with confirmation
8. `/snippet-save` - Should save from conversation
9. `/snippet-compose` - Should walk through interactive composition
10. `/snippet-history` - Should scan and show repeated prompts
11. Type `#search what is Rust` in a message - Should trigger inline expansion
12. `/snip-list` - Alias should work

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: complete saynippet plugin with all commands and examples"
```
