# SayNippet - Claude Code Snippet Management Skill

## Overview

A Claude Code skill/plugin for managing reusable text snippets stored as Markdown files. Snippets support dynamic placeholders and can be triggered by keyword within Claude Code conversations.

**Inspired by:** [Espanso](https://espanso.org) (text expander), [massCode](https://masscode.io) (snippet manager)

---

## Research Summary

### Existing Solutions Reviewed

| Tool | Format | Placeholders | Portability | CLI | Notes |
|------|--------|-------------|-------------|-----|-------|
| **Espanso** | YAML files in `match/` dir | Date, clipboard, shell, script, choice, random, form | Excellent (file-based, `$CONFIG` var) | Yes | Best placeholder system, but OS-level text expansion |
| **massCode** | JSON database | None (static) | Good (local files) | Community CLI | Desktop app, not CLI-first |
| **TextExpander** | Proprietary cloud | Date, clipboard, fill-in fields | Cloud-only | No | Paid, not open source |
| **Lepton** | GitHub Gists | None | Via GitHub | No | Gist-based, too heavyweight |

### Key Takeaways

1. **Espanso's YAML approach** is powerful but too complex for our needs - we want Markdown files, not YAML
2. **Espanso's placeholder system** is the gold standard - we should adopt `{{variable}}` syntax with built-in and custom variables
3. **File-per-snippet** (Markdown) is more readable and portable than a single YAML/JSON database
4. **Claude Code's native skill system** already supports Markdown files with frontmatter - perfect fit
5. **No existing Claude Code snippet skill** exists - this is a novel integration

---

## Architecture

### Config File

`~/.claude/snippets/config.json` stores user preferences:

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
  "placeholders": {
    "user_name": "xicao",
    "user_email": "xi@example.com",
    "signature": "Best regards,\nXi Cao"
  }
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `prefix` | string | `"#"` | Inline trigger prefix character. Set to `":"`, `"!"`, `"@"`, `"~"`, or any string |
| `snippets_dir` | string | `"~/.claude/snippets"` | Where snippet files are stored |
| `default_category` | string | `"general"` | Default category for new snippets |
| `separator` | string | `"\n\n---\n\n"` | Separator between composed snippets |
| `history.max_days` | number | `30` | How far back to scan conversation history |
| `history.min_frequency` | number | `2` | Minimum repeat count to show in `/snippet-history` |
| `placeholders` | object | `{}` | Custom default values for placeholders (overrides built-in `user_name`, etc.) |

The config file is optional — all settings have sensible defaults. Commands read it at runtime.

### Storage

```
~/.claude/snippets/
  config.json              # User preferences (optional)
  greeting.md
  email-reply.md
  code-review-template.md
  git-commit-body.md
  meeting-notes.md
```

Each snippet is a standalone Markdown file with YAML frontmatter:

```markdown
---
trigger: greet
description: Professional greeting with name
category: communication
---
Hello {{name}},

Thank you for reaching out. I wanted to follow up on {{topic}}.

Best regards,
{{user_name}}
```

### Frontmatter Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `trigger` | Yes | string | Keyword to invoke the snippet (unique) |
| `description` | No | string | Human-readable description shown in list |
| `category` | No | string | Grouping for organization (default: "general") |
| `tags` | No | string[] | Tags for search and composition (e.g., `[web, research]`) |
| `compose` | No | string[] | Other snippet triggers to include before this one |
| `author` | No | string | Who created it |

### Body

The body is the template text. Supports:
- Plain text
- Markdown formatting
- `{{placeholder}}` dynamic variables
- `{{snippet:trigger}}` nested snippet references
- Multi-line content

---

## Placeholder System

### Built-in Placeholders

| Placeholder | Description | Example Output |
|-------------|-------------|----------------|
| `{{date}}` | Current date (YYYY-MM-DD) | `2026-03-05` |
| `{{date:format}}` | Formatted date (strftime) | `{{date:%B %d, %Y}}` -> `March 05, 2026` |
| `{{time}}` | Current time (HH:MM) | `14:30` |
| `{{datetime}}` | ISO datetime | `2026-03-05T14:30:00` |
| `{{timestamp}}` | Unix timestamp | `1772870400` |
| `{{clipboard}}` | System clipboard content | (clipboard text) |
| `{{cwd}}` | Current working directory | `/Users/xicao/Projects/foo` |
| `{{git_branch}}` | Current git branch | `feature/my-feature` |
| `{{user_name}}` | System username | `xicao` |
| `{{hostname}}` | Machine hostname | `Xis-MacBook-Pro` |
| `{{random_uuid}}` | Random UUID v4 | `a1b2c3d4-...` |
| `{{shell:command}}` | Output of shell command | `{{shell:node -v}}` -> `v20.11.0` |
| `{{file:path}}` | Content of a file | `{{file:~/.signature}}` |

### Custom Placeholders (User-Prompted)

Any `{{placeholder}}` not matching a built-in will prompt the user for input:

```markdown
---
trigger: email
description: Email template
---
To: {{recipient_email}}
Subject: {{subject}}

Hi {{recipient_name}},

{{body}}

Best,
{{user_name}}
```

When triggered, Claude will ask:
- "recipient_email?" -> user provides value
- "subject?" -> user provides value
- "recipient_name?" -> user provides value
- "body?" -> user provides value
- `{{user_name}}` resolves automatically (built-in)

### Placeholder with Defaults

```
{{name:John}}          -> Defaults to "John" if not provided
{{date_format:%Y-%m-%d}} -> Default format
```

---

## Snippet Composition

Snippets can be combined in multiple ways, making them reusable prompt building blocks.

### 1. Nested References (`{{snippet:trigger}}`)

Any snippet can include another snippet inline:

```markdown
---
trigger: deep-search
description: Search the web with deep thinking
category: ai
---
{{snippet:search}}

{{snippet:think}}

Now combine these approaches to answer: {{query}}
```

When `deep-search` is expanded, `{{snippet:search}}` and `{{snippet:think}}` are resolved first (recursively), then any remaining placeholders are handled. Circular references are detected and produce an error.

### 2. Compose Field (Frontmatter Chaining)

The `compose` field in frontmatter prepends other snippets automatically:

```markdown
---
trigger: thorough-review
description: Code review with security analysis and thinking
compose: [think, security-checklist]
---
Now review the code at {{file_path}} using the above guidelines.
```

This expands `think` and `security-checklist` before the body, creating a composed prompt without manually writing `{{snippet:...}}` references.

### 3. Chained Trigger Syntax (`+`)

Users can combine snippets on the fly using `+` in the trigger:

```
/snippet search+think
/snip review+security-checklist+think
```

The `+` operator expands each snippet in order and concatenates them with a blank line separator. Placeholders are collected from all snippets and resolved together (duplicates merged).

### 4. Tag-Based Composition

Snippets tagged with the same tag can be composed by tag:

```
/snippet --tag=pre-commit
```

This expands ALL snippets with the `pre-commit` tag in alphabetical order, useful for composing checklists or multi-step workflows.

### Composition Examples

**Individual snippets:**

```markdown
# ~/.claude/snippets/search.md
---
trigger: search
description: Instruct Claude to search the web
tags: [web, research]
category: ai
---
Search the web thoroughly for the most up-to-date information on this topic.
Use multiple search queries if needed. Cite sources.
```

```markdown
# ~/.claude/snippets/think.md
---
trigger: think
description: Instruct Claude to think deeply
tags: [reasoning]
category: ai
---
Think step by step. Consider multiple perspectives. Challenge your initial assumptions.
Identify edge cases and potential issues before proposing a solution.
```

```markdown
# ~/.claude/snippets/deep-research.md
---
trigger: deep-research
description: Combined deep research with web search and thinking
compose: [search, think]
category: ai
---
Apply both approaches above to research: {{topic}}

Provide a comprehensive analysis with sources.
```

**Usage:**
```
/snippet deep-research              # Uses compose field
/snippet search+think               # Ad-hoc chaining (same result)
/snippet --tag=research             # All research-tagged snippets
```

### Composition Resolution Order

1. Resolve `compose` field (prepend referenced snippets in order)
2. Resolve `{{snippet:trigger}}` references in body (recursive, depth-first)
3. Resolve built-in placeholders (`{{date}}`, `{{clipboard}}`, etc.)
4. Collect remaining custom placeholders and prompt user (or infer from context)

Circular references (A includes B, B includes A) are detected and produce a clear error: `"Circular snippet reference detected: search -> think -> search"`

---

## Inline Triggers

Beyond slash commands, snippets can be triggered inline within regular messages using a **prefix character**.

### Prefix Character: `#`

When typing a message to Claude, use `#trigger` to expand a snippet inline:

```
Can you #search for the latest Vue 4 docs and #think about migration strategy
```

Claude detects the `#trigger` patterns, expands the referenced snippets, and treats the expanded text as the full instruction.

### How It Works

1. **Detection:** The SKILL.md auto-detects `#word` patterns in user messages
2. **Expansion:** Each `#trigger` is replaced with its snippet body (built-in placeholders resolved)
3. **Prompt Assembly:** The expanded message becomes Claude's working instruction
4. **Execution:** Claude acts on the composed prompt naturally

### Inline Chaining

Multiple inline triggers compose naturally:

```
#search #think What are the best practices for Rust error handling?
```

Expands to the combined `search` + `think` instructions, followed by the user's question.

### Inline with Custom Placeholders

If an inline-triggered snippet has custom placeholders, Claude resolves them from the surrounding message context (or asks if ambiguous):

```
#email to john@example.com about the project deadline
```

Claude infers `recipient_email=john@example.com` and `subject=project deadline` from context.

### Escaping

To use a literal `#` without triggering expansion, use `\#`:

```
Please update the \#search snippet to include DuckDuckGo
```

### Prefix Character (Configurable)

Default is `#`, chosen because:
- Visually distinct and familiar (hashtag convention)
- Unlikely to conflict in normal developer conversations
- Easy to type
- Works well with trigger keywords (e.g., `#search`, `#think`, `#review`)

**Customizable** via `config.json`:

```json
{ "prefix": ":" }
```

Now `:search :think` triggers expansion instead of `#search #think`.

Other popular choices:
- `":"` — Espanso convention (e.g., `:search`, `:think`)
- `"!"` — Bang syntax (e.g., `!search`, `!think`)
- `"@"` — Mention style (e.g., `@search`, `@think`)
- `"~"` — Tilde prefix (e.g., `~search`, `~think`)

---

## Commands

### `/snippet [trigger]` (or `/snip [trigger]`)

**Primary command.** Expand a snippet by its trigger keyword.

```
/snippet greet
/snippet search+think           # Chained composition
/snippet --tag=pre-commit       # Tag-based composition
```

Behavior:
1. Parse trigger: detect `+` chaining or `--tag=` flag
2. Find snippet file(s) where `trigger` matches
3. Resolve `compose` field and `{{snippet:...}}` references
4. Resolve all built-in placeholders
5. Prompt user for any custom placeholders (or infer from context)
6. Output the expanded text as Claude's working instruction

If no trigger argument: show interactive list (like `/snippet-list`).

### `/snippet-add [trigger]` (or `/snip-add`)

Create a new snippet interactively or from the current conversation context.

```
/snippet-add greet
```

Behavior:
1. If trigger provided, use it; otherwise ask
2. Ask for description
3. Ask for category (optional)
4. Ask for the template body (or capture from conversation context)
5. Write the Markdown file to `~/.claude/snippets/`

Also supports saving from voice/conversation:
> "Save this as a snippet" -> triggers `/snippet-add` with the relevant text

### `/snippet-list` (or `/snip-list`)

List all available snippets with filtering.

```
/snippet-list              # List all
/snippet-list email        # Filter by keyword
/snippet-list --cat=code   # Filter by category
```

Output format:
```
Snippets (12 total):

[communication]
  greet       - Professional greeting with name
  email       - Email template
  sig         - Email signature

[code]
  pr-desc     - Pull request description template
  commit-body - Detailed commit message body
  review      - Code review template

[general]
  meeting     - Meeting notes template
  standup     - Daily standup update
```

### `/snippet-edit [trigger]`

Open a snippet for editing. Uses the Edit tool to modify the file.

```
/snippet-edit greet
```

### `/snippet-delete [trigger]`

Delete a snippet file (with confirmation).

```
/snippet-delete greet
```

### `/snippet-save`

Quick-save from conversation context. Captures text from the current conversation and creates a snippet.

```
/snippet-save
```

Behavior:
1. Ask what text to save (or infer from recent conversation)
2. Ask for trigger keyword
3. Ask for description
4. Write the snippet file

### `/snippet-history` (or `/snip-history`)

**Save from Claude Code conversation history.** Browse past conversations, select a message or prompt you've sent repeatedly, optionally refine it, and save as a reusable snippet.

```
/snippet-history
/snippet-history 10          # Show last 10 conversations
/snippet-history --search "deploy"  # Search history for keyword
```

Behavior:
1. **Scan history:** Read Claude Code conversation logs from `~/.claude/projects/` (JSONL files)
2. **List recent user messages:** Show a numbered list of recent user prompts/messages (deduplicated, most recent first)
3. **User selects:** Pick one or more messages by number
4. **Frequency hint:** Show how many times similar messages were sent (helps identify repetitive prompts)
5. **Refine (optional):** Ask "Would you like to refine this before saving?"
   - If yes: Claude rewrites the message into a cleaner, more effective prompt template
   - Extracts variable parts as `{{placeholders}}` automatically
   - Shows the refined version for approval
6. **Save:** Ask for trigger, description, category
7. **Write:** Save as snippet Markdown file

Example session:
```
> /snippet-history
Recent prompts (last 7 days):

  1. [x5] "Search the web for the latest docs on X and think deeply about..."
  2. [x3] "Review this code for security issues and suggest fixes"
  3. [x3] "Can you create a PR with a good description"
  4. [x2] "Write tests for the function I just created"
  5. [x2] "Analyze this error and suggest a fix"

Select (number): 1
This prompt was sent 5 times. Refine before saving? [Y/n]: y

Refined:
---
trigger: research
description: Deep web research with critical thinking
tags: [web, reasoning]
category: ai
---
Search the web for the latest documentation and information on {{topic}}.
Think deeply about the findings. Consider multiple perspectives.
Provide a comprehensive analysis with cited sources.

Save this snippet? [Y/n]: y
Created: ~/.claude/snippets/research.md
```

#### How History Access Works

Claude Code stores conversation transcripts as JSONL files in:
```
~/.claude/projects/<project-hash>/
  *.jsonl           # Session transcripts
```

The `/snippet-history` command:
1. Scans JSONL files for `"type":"user"` messages
2. Extracts the message content
3. Groups similar messages (fuzzy matching on content similarity)
4. Ranks by frequency and recency
5. Presents the top candidates

#### Refinement Engine

When the user opts to refine, Claude:
1. Analyzes the raw prompt for its intent
2. Identifies variable parts (specific file names, topics, URLs) and converts them to `{{placeholders}}`
3. Rewrites for clarity and effectiveness as a reusable template
4. Preserves the user's intent and style
5. Shows before/after for approval

### `/snippet-compose [trigger]` (or `/snip-compose`)

**Interactive composition builder.** Create a new composed snippet from existing ones.

```
/snippet-compose
```

Behavior:
1. List all available snippets grouped by category
2. Ask user to select snippets to compose (by trigger, multi-select)
3. Show preview of the composed expansion
4. Ask for a new trigger name for the composed snippet
5. Ask if user wants to add custom body text after the composed parts
6. Write the new snippet with `compose` field populated

Example session:
```
> /snippet-compose
Available snippets:
  [ai] search, think, summarize
  [code] review, security-checklist, test-plan
  [communication] greet, email, sig

Select snippets to compose (comma-separated): search, think
Preview:
  ---
  Search the web thoroughly for the most up-to-date information...
  ---
  Think step by step. Consider multiple perspectives...

Trigger for composed snippet: deep-research
Add body text? (optional): Research {{topic}} comprehensively.

Created: ~/.claude/snippets/deep-research.md
```

### `/snippet-preview [trigger]` (or `/snip-preview`)

**Preview expansion without executing.** Shows what the final expanded text looks like.

```
/snippet-preview deep-research
/snippet-preview search+think+summarize
```

Behavior:
1. Resolve all composition (compose field, nested refs, chaining)
2. Resolve built-in placeholders
3. Show `[PLACEHOLDER]` markers for custom placeholders instead of prompting
4. Display the full expanded text for review

Useful for debugging complex compositions and verifying snippet content.

---

## Skill File (SKILL.md)

The skill auto-detects when snippet operations are needed:

**Triggers:**
- User says "save this as a snippet" / "add to snippets" / "create a snippet"
- User says "use snippet" / "expand snippet" / "my [trigger] snippet"
- User says "list snippets" / "show snippets"
- User says "edit snippet" / "update snippet"
- User says "combine snippets" / "compose snippets" / "chain snippets"
- User says "save from history" / "I keep typing this" / "I always send this"
- User message contains `#trigger` inline patterns matching known snippet triggers

---

## Implementation Plan

### Phase 1: Core Infrastructure

1. **Create directory structure**
   ```
   ~/.claude/plugins/saynippet/
     plugin.json
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
       snip.md              # alias -> snippet
       snip-add.md          # alias -> snippet-add
       snip-list.md         # alias -> snippet-list
       snip-compose.md      # alias -> snippet-compose
       snip-preview.md      # alias -> snippet-preview
       snip-history.md      # alias -> snippet-history
     skills/
       saynippet/
         SKILL.md           # Auto-detection + inline trigger handling
     scripts/
       resolve-placeholders.sh
       list-snippets.sh
       compose-snippets.sh  # Composition engine
   ```

2. **Create `plugin.json` manifest**

3. **Create `~/.claude/snippets/` directory** for snippet storage

4. **Create default `config.json`** with sensible defaults (prefix, snippets_dir, etc.)

### Phase 2: Commands (CRUD)

4. **`/snippet-list`** - List command (simplest, good first)
   - Bash script to scan `~/.claude/snippets/*.md`, parse frontmatter, format output
   - Show tags and compose dependencies

5. **`/snippet-add`** - Add command
   - Interactive prompt for trigger, description, category, tags, compose, body
   - Write Markdown file with frontmatter

6. **`/snippet`** - Main expand command
   - Find snippet by trigger
   - Detect `+` chaining and `--tag=` flags
   - Resolve composition chain (compose field + nested refs)
   - Resolve built-in placeholders via shell script
   - Prompt for custom placeholders (or infer from context)
   - Output expanded text

7. **`/snippet-edit`** - Edit existing snippet
   - Read and display current snippet
   - Allow modifications via Edit tool

8. **`/snippet-delete`** - Delete with confirmation

9. **`/snippet-save`** - Quick save from context

### Phase 3: Composition Engine

10. **`/snippet-compose`** - Interactive composition builder
    - Multi-select snippets from list
    - Preview composed result
    - Save as new composed snippet

11. **`/snippet-preview`** - Preview expansion without executing
    - Show full composed + expanded text
    - Mark custom placeholders as `[PLACEHOLDER]`

12. **Shell script `compose-snippets.sh`**
    - Parse `compose` field from frontmatter
    - Resolve `{{snippet:trigger}}` references (recursive, depth-first)
    - Detect circular references (maintain visited set)
    - Concatenate results with separators

### Phase 4: Placeholder Engine

13. **Shell script `resolve-placeholders.sh`**
    - Regex-based placeholder detection
    - Built-in resolution (date, time, clipboard, cwd, git_branch, etc.)
    - Shell command execution for `{{shell:...}}`
    - File inclusion for `{{file:...}}`
    - Default value extraction for `{{name:default}}`
    - Returns list of unresolved (custom) placeholders

### Phase 5: History-Based Save

14. **`/snippet-history`** - Browse and save from conversation history
    - Scan `~/.claude/projects/` JSONL files for user messages
    - Group similar messages by fuzzy content matching
    - Rank by frequency and recency
    - Refinement engine: rewrite raw prompt into clean template with `{{placeholders}}`
    - Save as snippet with full frontmatter

### Phase 6: Skill Auto-Detection + Inline Triggers

15. **SKILL.md** - Auto-detect snippet-related requests
    - Pattern matching on user messages for snippet operations
    - Route to appropriate command
    - **Inline trigger detection:** scan for `#trigger` patterns
    - Match `#word` against known snippet triggers
    - Expand inline and treat as composed instruction

### Phase 7: Example Snippets

16. **Starter pack** - Ship with useful defaults

    **Individual building blocks:**
    - `search.md` - Web search instruction
    - `think.md` - Deep thinking instruction
    - `summarize.md` - Summarization instruction

    **Composed templates:**
    - `deep-research.md` - compose: [search, think, summarize]
    - `pr-description.md` - PR template
    - `commit-detailed.md` - Detailed commit message
    - `code-review.md` - compose: [think, security-checklist]
    - `daily-standup.md` - Standup update
    - `bug-report.md` - Bug report template

---

## Alternative Approaches Considered

### 1. Single JSON/YAML Database
**Rejected:** Less readable, harder to edit manually, harder to diff in git.

### 2. Espanso Integration (OS-level)
**Rejected:** Different purpose - Espanso expands text system-wide while typing. We need Claude Code-specific expansion with AI-awareness.

### 3. Storing snippets inside CLAUDE.md
**Rejected:** Pollutes project config, not portable across projects.

### 4. Plugin vs Standalone Commands
**Chosen: Plugin.** Cleaner organization, proper namespacing, easier distribution. Falls back to `~/.claude/commands/` if plugin system isn't preferred.

---

## Portability

Snippets are plain Markdown files in `~/.claude/snippets/`. To sync across machines:

1. **Git repo**: `cd ~/.claude/snippets && git init` - track snippets in version control
2. **Symlink**: `ln -s ~/Dropbox/snippets ~/.claude/snippets` - cloud sync
3. **Copy**: Just copy the folder to a new machine

The plugin itself lives in `~/.claude/plugins/saynippet/` and can be installed via git clone or the plugin marketplace.

---

## Security Considerations

- `{{shell:...}}` executes arbitrary commands - document the risk
- `{{file:...}}` reads arbitrary files - restrict to non-sensitive paths
- `{{clipboard}}` may contain sensitive data - warn in docs
- Snippet files should not contain secrets - add to `.gitignore` guidance
- No network requests in built-in placeholders (shell extension can, but that's user-controlled)

---

## Success Criteria

- [ ] All 9 commands work correctly (snippet, add, list, edit, delete, save, compose, preview, history)
- [ ] Built-in placeholders resolve properly
- [ ] Custom placeholders prompt the user (or infer from context)
- [ ] Snippets stored as readable Markdown files
- [ ] **Composition works:** `compose` field, `{{snippet:...}}` nesting, `+` chaining, `--tag=` grouping
- [ ] **Circular reference detection** prevents infinite loops
- [ ] **Inline triggers** (`#trigger`) detected and expanded in regular messages
- [ ] Skill auto-detects snippet-related requests
- [ ] **History scanning** finds repeated prompts and ranks by frequency
- [ ] **Refinement engine** converts raw prompts into clean templates with placeholders
- [ ] Starter snippets included (individual blocks + composed examples)
- [ ] Portable across machines (copy folder)
- [ ] Works as Claude Code plugin with proper manifest
