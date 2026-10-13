# Installing agy on Hermes Agent

> **Tested on Hermes.** The skill has been run on Hermes on Linux x86-64
> (agy 1.1.27, then 1.3.3), including from inside Kanban worker subprocesses
> across multiple profiles. The manual-copy path and the multi-profile
> distribution below were verified 2026-09-07. On 2026-10-13 the tap and
> direct-GitHub installs were tested in a throwaway `HERMES_HOME` while the
> repo was still private: `hermes skills tap add d4rkwinz/agy-plugin`
> succeeded and `hermes skills install d4rkwinz/agy-plugin/skills/agy`
> installed `SKILL.md` plus all six `references/*.md` files. The bare-name form
> `hermes skills install agy` did **not** resolve (see below).

`skills/agy/` is a standard [agentskills.io](https://agentskills.io/specification)
skill directory, which is why it works on both hosts unchanged.

## Tap install (preferred)

    hermes skills tap add d4rkwinz/agy-plugin
    hermes skills install d4rkwinz/agy-plugin/skills/agy

The tap's default root path is `skills/`, which is exactly where this skill
lives. `references/` is downloaded alongside `SKILL.md`.

Use the full path. In testing, `hermes skills install agy` after adding the
tap answered "No exact match for 'agy'" and suggested unrelated skills; it may
behave differently once the repo is public — re-check then.

## Direct GitHub source

    hermes skills install d4rkwinz/agy-plugin/skills/agy

A path component is required. Bare `owner/repo` fails — `GitHubSource.fetch()`
finds no `SKILL.md` at the repo root
([#41171](https://github.com/NousResearch/hermes-agent/issues/41171)).

## Manual fallback

    cp -R skills/agy ~/.hermes/skills/

Installed skills only take effect in new sessions. Use `/reset` to invalidate
the prompt cache immediately.

**Verified 2026-09-07.** This is the path in production use here.

## Multi-profile installs (verified)

`~/.hermes/skills/` belongs to the **default** profile only. Under
`gateway.multiplex_profiles`, every named profile has its own
`~/.hermes/profiles/<name>/skills/` tree and sees nothing from the default
profile's. A Kanban task created with `--skill agy` passes `--skills agy` to
the worker, and if the skill is absent from **that profile**, the CLI exits
with `Error: Unknown skill(s): agy` before doing any work — which the
dispatcher only observes as a dead pid, and retries until the circuit breaker
gives up. The symptom looks nothing like a missing skill.

So on a multi-profile install, copy into every profile that will use it:

    for p in ~/.hermes/profiles/*/; do
      mkdir -p "$p/skills/orchestration"
      cp -R skills/agy "$p/skills/orchestration/"
    done

Two things to check afterwards, both of which have bitten this repo's
downstream consumer:

1. **Verify the `references/` files arrived, not just `SKILL.md`.** A
   copy routine that only handles a single markdown file installs a skill
   whose `invariants.md` is missing — the one file that prevents the expensive
   mistakes. Count them: `find <dest>/agy -type f | wc -l` should be 7.
2. **Editing a skill inside a profile is not durable.** Any redistribution
   step overwrites it from source. Patch this repo, then redistribute.

## Do not use the URL form

    # BROKEN — do not use
    hermes skills install https://.../SKILL.md

The docs claim referenced files under `references/` are fetched too, but
`UrlSource.fetch` hardcodes a single-file download
([#35125](https://github.com/NousResearch/hermes-agent/issues/35125)). You would
get `SKILL.md` with six dangling links and no operations.

## Shortening the slash command

Hermes exposes every installed skill as a slash command, so this one is
`/agy`. `--name` is documented for the URL form only; if it also works on
GitHub sources, this should shorten it:

    hermes skills install d4rkwinz/agy-plugin/skills/agy --name agy

Tested 2026-10-13: the flag was accepted and the skill installed as `agy`.
Since the default name is already `agy`, it does not shorten anything here.

## Name collisions

**This skill is named `agy`, and that name is already taken.** Two public
`SKILL.md` files declare it, measured 2026-09-02:

- `phuongduyphan/cc-tmux-agents` — `skills/agy/SKILL.md`
- `iicmaster/antigravity-plugins` — `plugins/agy/skills/agy/SKILL.md`

The short name was chosen deliberately for legibility. The risk is real:
Hermes keys its security-scan cache on frontmatter `name` rather than the
source identifier
([#78004](https://github.com/NousResearch/hermes-agent/issues/78004)), so a
name shared with another indexed skill can silently install **that** skill
instead — and unlike this one, it may ship executables.

**So install by fully-qualified path, never bare name:**

    hermes skills install d4rkwinz/agy-plugin/skills/agy

Then verify what actually landed before first use:

    hermes skills list

`hermes skills list` shows name, category, source, trust and status, not the description; to see the
description run `hermes skills inspect d4rkwinz/agy-plugin/skills/agy` and
confirm it mentions Antigravity. If it does not, you got someone else's `agy` — uninstall and retry, or rename locally
with `--name`.

Claude Code is unaffected: plugins are namespaced by marketplace
(`agy@agy-plugin`), so `/agy:*` cannot collide.

If you do hit a collision, rename the directory and the `name:` field together
— they must match.

## Frontmatter caveat: not packageable for claude.ai / the Skills API

`SKILL.md` carries top-level `version` and `platforms` keys. Claude Code and
Hermes both read them fine. But the Agent Skills packaging path used by
claude.ai uploads and the Skills API accepts only six top-level properties —
`allowed-tools`, `compatibility`, `description`, `license`, `metadata`,
`name` — so packaging this skill for those targets would fail on `version`
and `platforms`. Out of scope for v1; recorded here so it is a known
limitation rather than a surprise.

## Why the security scan is a non-event here

Hermes scans installed skills because a skill can ship executables. This one
contains no `scripts/` directory and no executable of any kind — only markdown.
`smoke.sh` lives at the repo root, outside `skills/`, so it is never fetched.
