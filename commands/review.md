---
description: Independent cross-model review of the current diff via agy (Gemini)
argument-hint: '[--base <ref>] [--adversarial] [paths]'
allowed-tools: Read, Grep, Bash(agy:*), Bash(rtk:*), Bash(git:*), Bash(mkdir:*), Bash(wc:*), Bash(rm:*)
disable-model-invocation: true
---
Read `${CLAUDE_PLUGIN_ROOT}/skills/agy/references/review.md` and follow it exactly.

This command is review-only. Do not fix issues or apply patches.

Arguments: $ARGUMENTS
