---
title: Post Ideas
tags:
---

# Post Ideas

Another test update for CI/CD

## Find files in named subdirectories

tags: bash

```bash
# Recursively find lines matching "draft" in all files/folders with "hexo" in the name
find . -name hexo | xargs grep -r -i --color=auto draft
```