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

**Step 4:** Write the snippet file to `~/.claude/snippets/<trigger>.md` with proper YAML frontmatter and body.

**Step 5:** Confirm: "Saved snippet `<trigger>` at `~/.claude/snippets/<trigger>.md`"
