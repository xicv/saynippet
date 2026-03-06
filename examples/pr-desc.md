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
