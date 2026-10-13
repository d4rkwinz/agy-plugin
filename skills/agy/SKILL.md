---
name: agy
description: Delegate bulk work and second opinions to Antigravity (agy).
version: 0.2.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [gemini, antigravity, delegation, code-review]
    category: development
    requires_toolsets: [terminal]
---

# agy

Hand work to Google's Antigravity CLI (`agy`, running Gemini) and keep the
judgment here. You stay the conductor: you own requirements, verification, and
the final call. agy is the executor.

**Read [references/invariants.md](references/invariants.md) before your first
`agy` call in a session.** It carries the flag rules that a plausible-looking
invocation gets silently wrong — the failure mode is a confident wrong answer,
not an error, so guessing the syntax is the expensive mistake here.

## When to use

Delegate when the offloaded volume clearly exceeds the cost of specifying the
task, the round trip, and verifying the result. Bulk, repetitive, or parallel
work qualifies. A two-line edit does not — doing it yourself is cheaper.

Also use it for things this agent cannot do at all: hearing audio, watching
video, and getting a genuinely independent second opinion from a different
model family.

## Operations

| operation | when | how |
|-----------|------|-----|
| setup | first run, or agy misbehaving | [references/setup.md](references/setup.md) |
| review | before commit or merge | [references/review.md](references/review.md) |
| delegate | bulk build, scaffolding, tests | [references/delegate.md](references/delegate.md) |
| research | multi-source web questions | [references/research.md](references/research.md) |
| media | audio, video, images | [references/media.md](references/media.md) |

## Two rules that decide whether this pays off

**Ask for a digest, never raw output.** Close every read/analysis prompt with an
explicit contract — "Output ONLY 5–8 bullets, no file contents." This is the
whole cost saving.

**Never re-read what agy already handled.** Ingest the digest and move on.
Re-reading the files puts back exactly the cost you just removed.

## Verification gates

Never trust a self-reported "done".

- **Writes:** confirm with `rtk proxy git status` (or `git status` if RTK is not
  installed) that files actually changed. Run write tasks on a dedicated branch.
- **Review findings:** corroborate each one against the real code before acting.
  Cross-model agreement is a strong signal; disagreement means look closer.
- **Research citations:** open the URLs. agy can present parametric knowledge as
  a sourced fact.
- **Transcripts:** treat flagged-unclear passages as unverified. Read the
  timestamp slice before relying on any load-bearing figure or quote.
