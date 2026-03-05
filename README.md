# SayNippet

Snippet management for Claude Code. Create, compose, and expand reusable prompt templates stored as Markdown files.

## Features

- **9 slash commands** for full snippet lifecycle management
- **Composition** -- combine multiple snippets with `+` operator
- **Inline triggers** -- expand snippets mid-sentence with `#name`
- **Placeholder substitution** -- `{{variable}}` replacement with defaults
- **History-based save** -- `/snippet-save` suggests snippets from recent conversation
- **Category organization** -- group snippets by domain
- **Fuzzy search** -- find snippets by name or content
- **Import/export** -- share snippet collections
- **Configurable** -- custom prefix, directories, and defaults

## Installation

Clone into your Claude Code plugins directory:

```bash
git clone https://github.com/xicao/saynippet.git ~/.claude/plugins/saynippet
```

Or symlink from a local checkout:

```bash
ln -s /path/to/saynippet ~/.claude/plugins/saynippet
```

## Quick Start

```
/snippet-list              # List all snippets
/snippet-add review        # Create a new snippet named "review"
/snippet search refactor   # Search snippets by keyword
#review                    # Expand inline with trigger prefix
#review+fixes              # Compose multiple snippets
```

## Documentation

See [SPEC.md](SPEC.md) for the full design specification.

## License

MIT
