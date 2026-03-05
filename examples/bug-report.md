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
