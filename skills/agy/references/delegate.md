# delegate — hand a scoped task to agy

Read [invariants.md](invariants.md) first.

## Break-even, before anything else

Delegate only when the offloaded volume clearly exceeds specifying the task +
the round trip + verifying the result. Bulk, repetitive, or parallel work
qualifies. A small edit does not — do it yourself. Delegating everything is a
measured net loss.

## Pick a tier

| tier | for |
|------|-----|
| `lo` | trivial, mechanical |
| `flash` | most bulk work — the default |
| `pro` | none today — use `flash`; see invariants.md |

Tier-to-model mapping lives in [invariants.md](invariants.md) § Tiers.

## Read / analysis task

`--add-dir` lets agy read the real files, so you never paste them into your own
context. That is where the saving comes from.

    agy --add-dir "$PWD" --model gemini-3.8-flash-high -p='<task>. Output ONLY
    5-8 bullets. No file contents, no code blocks.'

The output contract is not optional. Without it agy returns bulk text and the
delegation costs more than doing the work yourself.

## Write task

Writes may need a grant (some setups allow them implicitly — see
[invariants.md](invariants.md) § Hard rules, rule 4). Do not rely on that. Two
options, narrower first:

1. A `write_file(<dir>)` entry under `permissions.allow` in
   `~/.gemini/antigravity-cli/settings.json` — recursive beneath `<dir>`, no
   flag needed.
2. `--dangerously-skip-permissions`, which auto-approves every tool — see
   [invariants.md](invariants.md) § Hard rules before reaching for it.

Then:

    rtk proxy git checkout -b agy/<short-task-name>
    agy --add-dir "$PWD" --model gemini-3.8-flash-high \
        --dangerously-skip-permissions \
        -p='<task>. Report ONLY which files you changed and why, one line each.'

Always on a dedicated branch — see [invariants.md](invariants.md) § Hard rules
for why the sandbox flag is not a substitute.

## Verify — always

    rtk proxy git status --short
    rtk proxy git diff --stat

If agy reports success but that status output is empty, the write was denied. Fix the
grant (option 1 or 2 above) and re-run; do not report success.

Then actually exercise the result — run the tests, run the build, read the
changed lines. A self-reported "done" is not evidence.

## Report

What you delegated, which tier, what came back, and how you verified it. Ingest
the digest only — **do not re-read the files agy already handled.**
