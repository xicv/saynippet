---
name: add
description: Create a new snippet interactively. Use when the user wants to create, add, or make a new snippet template.
argument-hint: "[trigger]"
allowed-tools: Bash, Read, Write, Glob
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
