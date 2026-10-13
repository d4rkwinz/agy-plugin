# review — independent cross-model review

Get a different model family's opinion on the current diff, then reconcile it
yourself. **You are the final judge.** Read [invariants.md](invariants.md)
first.

This operation is **review-only**. Do not fix anything, do not apply patches,
do not imply you are about to change code.

## 1. Capture the diff to a file

The diff must reach agy as a **file**, never a pipe — see
[invariants.md](invariants.md) § Hard rules:

    mkdir -p .agy && rtk proxy git diff > .agy/review.diff

Scope variants — same redirect, different scope:

    rtk proxy git diff --cached > .agy/review.diff        # staged only
    rtk proxy git diff <base>...HEAD > .agy/review.diff   # branch vs base
    rtk proxy git diff -- <paths> > .agy/review.diff      # specific paths

If `rtk` is not installed (`command -v rtk`), drop the `rtk proxy` prefix.
**Never use plain `git diff` on a machine where RTK is active** — see
[invariants.md](invariants.md) § Host hazard for what it does to the diff.

Check the diff is non-empty before spending a call:

    wc -l .agy/review.diff

If it is empty, also check `rtk proxy git status --short` for untracked files
before concluding there is nothing to review. If that is also empty, there is
genuinely nothing to review — report that and stop; do not spend a model
call.

## 2. Delegate the review

    agy --add-dir "$PWD" --model gemini-3.8-flash-high -p='Read
    .agy/review.diff. Review it for correctness, security, and performance
    bugs. Be skeptical; assume the author was overconfident. List each finding
    as `file:line — issue`, most severe first. If you find nothing real, say
    NONE rather than inventing something. Output ONLY the findings list.'

`flash` (high) is the strongest Gemini tier available (no `pro` tier today), so
use it for review; do not downgrade to `lo`, which gets reasoning-heavy review wrong.

If the caller passed `--adversarial`, add to the prompt: "Also challenge the
design decisions and trade-offs, not just line-level bugs."

## 3. Reconcile — the part that matters

For each finding, open the actual code and corroborate it. Then:

- **Drop false positives silently.** Do not pad the report to look thorough.
- **Keep what is real**, most severe first.
- Note where the two models agree — cross-family agreement is a stronger signal
  than either model alone. Disagreement is a prompt to look closer, not a tie
  to split.

## 4. Report

Reconciled findings only, each as `file:line — issue`, plus your verdict. State
plainly how many of agy's findings you dropped and why. If agy said NONE and
you agree, say so in one line. This is still review-only — report the
findings, do not fix them.

## Cleanup

    rm -f .agy/review.diff

Add `.agy/` to `.gitignore` if it is not already there.
