# agy

Delegate bulk work, code review, web research, and audio/video transcription
from your AI coding agent to Google's [Antigravity CLI](https://antigravity.google/docs/cli-using)
(`agy`, running Gemini).

The skill itself is Markdown only (`skills/agy/`); two optional shell scripts
(`smoke.sh`, `scripts/check_models.sh`) are for maintainers and are never
run or loaded by the skill. A Hermes skill install fetches only `skills/agy/`;
the Claude Code plugin copy is the whole repository, so it contains the scripts
too. One canonical skill, two hosts.

## Why

Claude Code's own subagents run Claude models. Getting a different model family
into the loop — for a genuinely independent code review, or for the multimodal
work this agent cannot do at all — needs a delegation layer. This is the
smallest one that works.

The saving comes from a single mechanic: **agy reads and writes files directly
and returns a digest.** Your orchestrating agent never ingests the raw content.

## Install

### Claude Code

    /plugin marketplace add d4rkwinz/agy-plugin
    /plugin install agy@agy-plugin

Then `/agy:setup` to confirm agy is authenticated.

### Hermes Agent

    hermes skills tap add d4rkwinz/agy-plugin
    hermes skills install d4rkwinz/agy-plugin/skills/agy

Install by the full path: the bare name `agy` is shared with other public
skills and did not resolve through the tap when tested. See
[docs/HERMES.md](docs/HERMES.md).

## Requirements

- `agy` installed and authenticated (`agy models` lists Gemini models)
- macOS or Linux. Not Windows — headless `agy -p` is unreliable there.

## Commands

| command | what it does |
|---------|--------------|
| `/agy:setup` | Is agy installed, authenticated, and which tiers are available |
| `/agy:review` | Independent cross-model review of the current diff. Review-only |
| `/agy:delegate` | Hand off a scoped task under cost discipline, then verify |
| `/agy:research` | Grounded multi-source research; citations verified before synthesis |
| `/agy:media` | Audio/video/image → timestamped digest, full transcript to a file |

On Hermes these are one slash command, `/agy`, plus description-triggered
invocation.

## Design notes

`skills/agy/references/invariants.md` holds every verified `agy` behaviour
in one file — including three that contradict third-party documentation:
the prompt must be attached as `-p='...'`, `agy -p` silently ignores stdin, and
there is no `--yolo` flag (checked on agy 1.1.22 and 1.3.3). When agy changes,
that file changes.

Design rationale: [docs/MOTIVATION.md](docs/MOTIVATION.md).

## Test

    ./smoke.sh

Structural validation only — frontmatter parses, required fields exist, every
reference link resolves, no stale agy flags anywhere. The runtime check is
`/agy:setup`. After editing model ids, run `scripts/check_models.sh` (needs
`agy` installed; compares ids in the skill against `agy models`).

## Security

Report vulnerabilities privately through GitHub's "Report a vulnerability"
button on the repository's Security tab (private vulnerability reporting), or
open an issue asking for a private contact channel without including details.
Do not post exploit details publicly.

## Not affiliated

Not affiliated with Google or Anthropic. "Antigravity" and "Gemini" are
trademarks of Google LLC. Community project, MIT licensed (see [LICENSE](LICENSE)).
