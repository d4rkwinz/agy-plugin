# Motivation

## Problem to Solve

Claude Code's native subagents only run Claude models, so every bulk,
repetitive, or mechanical task — large diff reviews, bulk scaffolding,
multi-source research, transcribing audio/video — burns the same expensive
primary-subscription quota as real reasoning work. Pulling large payloads
(a big diff, a directory of files, a transcript) into the orchestrating
agent's context also compounds cost on every subsequent turn of the session,
not just the one that needed the data.

A single-model workflow is also a single point of view: it's prone to
self-confirmation bias with no adversarial second opinion, and it has no
native way to perceive audio or video at all. Google's Antigravity CLI (`agy`,
running Gemini) is cheap, has a distinct model family, and natively ingests
audiovisual input — but only pays off when the volume of offloaded work
clearly exceeds the fixed cost of specifying the task, the round trip, and
verifying the result. A two-line edit or a trivial query delegated to a
subshell is a net loss, not a saving.

## How It Works

The entire saving comes from one mechanic: **agy reads and writes files
directly on disk and returns only a digest.** The orchestrating agent never
ingests the raw content — not the diff, not the directory contents, not the
transcript.

That means every prompt to agy must close with an explicit output contract
("5-8 bullets, no file contents, no code blocks"), because an unconstrained
response or an inline file dump erases the saving before it starts. It also
means content is handed to agy via `--add-dir <path>` (agy's headless mode
silently ignores piped stdin, which conveniently forces this file-based
handoff) rather than piped in. And once agy returns its digest, the
orchestrator must never re-read the same files itself — doing so puts back
exactly the cost that was just removed.

In this design the orchestrating agent stays the conductor: it owns scoping,
prompting, and reconciling agy's output against reality. agy is a headless,
disposable executor with no stake in the task. Different task classes route
to different model tiers (cheap/fast for bulk mechanical work, a stronger
tier for review and synthesis), and every delegation ends with a verification
gate — confirming disk changes actually happened, corroborating review
findings against the real code, and opening cited URLs rather than trusting
them. See `skills/agy/references/invariants.md` for the verified CLI flag
behavior this all depends on; it is not restated here because it changes
independently of this design.

## Proposal

Ship this as a zero-script Agent Skill: markdown instructions only, no
runtime code to maintain, and it trivially passes host security scanners
that inspect third-party plugins. The skill is built to run identically from
two hosts — Claude Code and Hermes Agent — off a single source of truth,
because a flat repository layout happens to satisfy both hosts' discovery
paths (Claude Code's plugin path, Hermes's default skill tap root) with no
adapter or duplication. Claude Code gets five lightweight slash-command
pointers into the same canonical docs; Hermes consumes the root skill file
directly.

The skill defines five operational workflows: environment setup and an
auth-readiness check, cross-model code review (review-only, never fixes,
reconciled by the orchestrator), general task delegation, multi-source
research with mandatory citation verification, and media transcription with
a timestamped-digest contract.

## Design Decisions and Non-Goals

Symlinks are deliberately avoided: GitHub's contents API returns a symlink
object rather than a directory listing, which would silently break skill
discovery on remote installs. Diff generation must go through `rtk proxy git
diff` rather than plain `git diff`, because an RTK-style host-level hook
(if your shell runs one) rewrites the latter and drops context lines that a reviewer needs.
The skill knowingly accepted a global-namespace-collision risk in choosing
the short name `agy` over a safer, uglier one, on the reasoning that
plugin namespacing and fully-qualified install paths mitigate it.

Explicit non-goals: replacing Claude Code's own subagent orchestration,
auto-routing every task to agy regardless of size (measured net loss below
a certain volume), and building custom job monitors or cost trackers on top
of what the host harness already provides.
