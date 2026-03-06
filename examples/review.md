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
