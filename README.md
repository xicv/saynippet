# SayNippet

A Claude Code plugin for managing reusable text snippets stored as Markdown files. Create, compose, and expand prompt templates with dynamic placeholders — triggered by slash commands or inline `#keywords`.

Inspired by [Espanso](https://espanso.org) and [massCode](https://masscode.io).

## Installation

**Clone directly:**

```bash
git clone https://github.com/xicv/saynippet.git ~/.claude/plugins/saynippet
```

**Or symlink from a local checkout:**

```bash
ln -s /path/to/saynippet ~/.claude/plugins/saynippet
```

**Install starter snippets:**

```bash
bash ~/.claude/plugins/saynippet/scripts/install-examples.sh
```

This copies 9 example snippets to `~/.claude/snippets/`. Existing files are never overwritten.

Start a **new Claude Code session** after installation so the plugin loads.

## Quick Start

```
/snippet-list                    # See all your snippets
/snippet search                  # Expand a snippet by trigger
/snippet search+think            # Compose two snippets on the fly
#search what is Rust ownership   # Inline trigger in regular message
/snippet-add my-template         # Create a new snippet
/snippet-history                 # Find repeated prompts to save
```

## How It Works

Each snippet is a Markdown file in `~/.claude/snippets/` with YAML frontmatter:

```markdown
---
trigger: greet
description: Professional greeting template
category: communication
tags: [email]
---
Hello {{name}},

Thank you for reaching out about {{topic}}.
I'll follow up by {{date}}.

Best regards,
{{user_name}}
```

When you run `/snippet greet`, Claude:
1. Reads the file and resolves built-in placeholders (`{{date}}`, `{{user_name}}`)
2. Asks you for custom placeholders (`{{name}}`, `{{topic}}`)
3. Outputs the expanded text as your working instruction

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `/snippet <trigger>` | `/snip` | Expand a snippet by keyword |
| `/snippet-list [filter]` | `/snip-list` | List all snippets with filtering |
| `/snippet-add [trigger]` | `/snip-add` | Create a new snippet interactively |
| `/snippet-edit <trigger>` | — | Edit an existing snippet |
| `/snippet-delete <trigger>` | — | Delete a snippet (with reference checking) |
| `/snippet-save` | — | Save text from current conversation as a snippet |
| `/snippet-compose` | `/snip-compose` | Build a composed snippet from existing ones |
| `/snippet-preview <trigger>` | `/snip-preview` | Preview expansion without executing |
| `/snippet-history` | `/snip-history` | Find and save repeated prompts from history |

## Placeholders

### Built-in (auto-resolved)

| Placeholder | Output |
|-------------|--------|
| `{{date}}` | `2026-03-05` |
| `{{date:%B %d, %Y}}` | `March 05, 2026` |
| `{{time}}` | `14:30` |
| `{{datetime}}` | `2026-03-05T14:30:00` |
| `{{timestamp}}` | `1772870400` |
| `{{clipboard}}` | System clipboard content |
| `{{cwd}}` | Current working directory |
| `{{git_branch}}` | Current git branch |
| `{{user_name}}` | System username |
| `{{hostname}}` | Machine hostname |
| `{{random_uuid}}` | Random UUID v4 |
| `{{shell:command}}` | Output of any shell command |
| `{{file:path}}` | Content of a file |

### Custom (user-prompted)

Any `{{word}}` not matching a built-in will prompt the user at expansion time. Add defaults with colon syntax:

```
{{name}}              # Prompts: "name?"
{{name:John}}         # Defaults to "John" if not provided
{{blockers:None}}     # Defaults to "None"
```

## Snippet Composition

Four ways to combine snippets into larger prompts:

### 1. Compose field

Prepend other snippets automatically via frontmatter:

```yaml
---
trigger: deep-research
compose: [search, think, summarize]
---
Apply all of the above to research: {{topic}}
```

### 2. Nested references

Include snippets inline in the body:

```
{{snippet:search}}

Now analyze what you found:
{{snippet:think}}
```

### 3. Chained triggers (`+`)

Combine on the fly without creating a new file:

```
/snippet search+think+summarize
```

### 4. Tag-based composition

Expand all snippets sharing a tag:

```
/snippet --tag=pre-commit
```

Circular references are detected and produce a clear error.

## Inline Triggers

Use snippets directly in your messages with a prefix character (default `#`):

```
#search what are the best practices for error handling in Rust
```

Claude detects `#search`, expands the snippet, and treats the combined text as your instruction. Multiple triggers compose naturally:

```
#search #think what's the difference between Mutex and RwLock
```

Escape with backslash to use literal `#`:

```
Please update the \#search snippet
```

## History-Based Save

`/snippet-history` scans your Claude Code conversation logs, finds prompts you've sent repeatedly, and offers to save them as snippets:

```
> /snippet-history
Recent repeated prompts (last 30 days):

  1. [x5] "Search the web for the latest docs on..."
  2. [x3] "Review this code for security issues..."
  3. [x2] "Write tests for the function I just created"

Select (number): 1
Refine before saving? [Y/n]: y
```

The refinement engine rewrites raw prompts into clean templates, automatically extracting variable parts as `{{placeholders}}`.

## Configuration

Optional config at `~/.claude/snippets/config.json`:

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
    "user_name": "your-name",
    "user_email": "you@example.com"
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `prefix` | `"#"` | Inline trigger character (`":"`, `"!"`, `"@"`, `"~"`) |
| `snippets_dir` | `"~/.claude/snippets"` | Where snippet files are stored |
| `default_category` | `"general"` | Default category for new snippets |
| `separator` | `"\n\n---\n\n"` | Separator between composed snippets |
| `history.max_days` | `30` | How far back to scan history |
| `history.min_frequency` | `2` | Min repeat count to show in history |
| `placeholders` | `{}` | Custom defaults for any placeholder |

All settings are optional with sensible defaults.

## Starter Snippets

The plugin ships with 9 example snippets:

| Trigger | Category | Description |
|---------|----------|-------------|
| `search` | ai | Web search instruction |
| `think` | ai | Deep thinking instruction |
| `summarize` | ai | Concise summary instruction |
| `deep-research` | ai | Composed: search + think + summarize |
| `pr-desc` | code | Pull request description generator |
| `review` | code | Code review with security (composes: think) |
| `commit-detail` | code | Conventional commit message |
| `bug-report` | workflow | Bug report template with auto-filled fields |
| `standup` | workflow | Daily standup template |

Install with: `bash scripts/install-examples.sh`

## Security Notes

- **`{{shell:command}}`** executes arbitrary shell commands. Only use commands you trust in your snippets.
- **`{{file:path}}`** reads file contents. Avoid referencing files with sensitive data (credentials, keys).
- **`{{clipboard}}`** inserts clipboard contents, which may contain sensitive information.
- Snippet files are plain text — do not embed secrets (API keys, tokens) directly in templates.

## Portability

Snippets are plain Markdown files. Sync across machines with:

- **Git:** `cd ~/.claude/snippets && git init`
- **Cloud sync:** `ln -s ~/Dropbox/snippets ~/.claude/snippets`
- **Copy:** Just copy the `~/.claude/snippets/` folder

If version-controlling your snippets, consider excluding personal config:

```gitignore
# ~/.claude/snippets/.gitignore
config.json
```

## File Structure

```
~/.claude/plugins/saynippet/      # The plugin
  plugin.json
  commands/                        # 9 commands + 6 aliases
  skills/saynippet/SKILL.md        # Auto-detection + inline triggers
  examples/                        # Starter snippets
  scripts/install-examples.sh      # Installer

~/.claude/snippets/                # Your snippets (portable)
  config.json                      # Preferences (optional)
  search.md
  think.md
  ...
```

## License

MIT
