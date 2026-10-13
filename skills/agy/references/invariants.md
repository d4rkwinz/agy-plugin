# agy invariants

Verified against `agy` 1.1.22 on macOS arm64, 2026-09-02, then re-verified
by running the commands against `agy` 1.1.27 and, most recently, `agy` 1.3.3
(Linux x86-64, 2026-10-13). Statements below that name a version were checked
on that version only.
Several of these contradict third-party documentation — trust this file. When a
new agy release changes behaviour, change this file only.

## Invocation shape

    agy [--add-dir <dir>] --model <id> -p='<prompt>'

`--effort` and the effort-suffixed model ids (`gemini-3.8-flash-high` etc.)
are alternatives: in 1.3.3, `--model gemini-3.8-flash-high --effort low`
errors with "conflicts with --effort". Pick the effort via the model id.

## Hard rules

1. **The prompt must be attached to the flag: `-p='...'`.** A bare `-p` takes
   the *next argument* as its prompt, so `agy -p --model X "real prompt"`
   would consume `--model` as the prompt and discard the real one. agy detects
   this and errors out: it prints an explicit message that the next flag was
   consumed as the prompt, and exits non-zero (exit code 2).

2. **`agy -p` silently ignores stdin.** `git diff | agy -p='review this'`
   answers "no stdin was provided". Never pipe. Write the content to a file and
   pass `--add-dir <that dir>` so agy reads it itself. This is also the cheaper
   path: the content never enters the orchestrating agent's context, which is
   the entire reason this skill exists.

3. **Reads need no permission grant, but a directory-analysis prompt can fail
   NONDETERMINISTICALLY — and it fails with exit 0 and empty stdout.**
   Pointing agy at a file or directory and asking it to analyse it usually
   works with no extra flags. Sometimes agy reaches for a shell tool (to
   enumerate or grep the directory) instead of its built-in file reader, and in
   headless mode that tool needs the `command` permission it cannot prompt for,
   so it is auto-denied and the run produces nothing:

       jetski: no output produced — a tool required the "command" permission
       that headless mode cannot prompt for, so it was auto-denied.

   **The important part: agy exits 0.** A caller checking only `$?` records a
   success and silently loses the work. Always treat empty output as failure
   regardless of exit status.

   Measured on agy 1.1.27 (Linux), 2026-09-07 — same prompt, same directory:
   observed DENIED once, then ALLOWED on 3 consecutive retries with the
   settings file untouched, and ALLOWED with no `permissions` block at all.
   A bisect over `command(ls)`, bare `command`, `command(*)`,
   `list_directory` and `read_file` returned ALLOWED for every variant
   *including the empty baseline*, which proves none of them is the deciding
   factor. So this is **not** a missing allow-rule: do not "fix" it by
   widening `permissions.allow`.

   Correct handling, in order:
   - Pass `--dangerously-skip-permissions` for a read you have already scoped
     with `--add-dir`; it removes the tool-choice gamble.
   - Or name the specific files in the prompt instead of asking about "the
     directory", which steers agy to its file reader.
   - Or retry once — this is a genuine transient, so a retry is legitimate
     here, unlike a retry on a wrong answer.

4. **Writes and web search may need `--dangerously-skip-permissions`.** There
   is **no `--yolo` flag** (checked on 1.1.22 and 1.3.3: "flags provided but
   not defined: -yolo") — third-party docs that mention one predate or
   mistarget this CLI. The narrower alternative is a `write_file(<dir>)`
   entry under `permissions.allow` in
   `~/.gemini/antigravity-cli/settings.json`.

   On 1.3.3 (Linux), file writes under `/tmp` and web search succeeded in
   headless mode *without* the flag and without any `permissions` block, so
   the grant may be implicit in some setups (that settings file only had
   `trustedWorkspaces`). Do not rely on it: a write that reports success but
   changes nothing was denied — see Verify in [delegate.md](delegate.md).

5. **`--sandbox` is not containment.** Do not present it as a safety boundary.

6. Run any write task on a dedicated branch and verify with
   `rtk proxy git status` afterwards. Never trust a self-reported "done".

## Real flags

`-p` / `--print`, `--model`, `--effort low|medium|high|xhigh|max` (conflicts
with an effort-suffixed `--model` id), `--add-dir` (repeatable),
`--print-timeout` (default `0s` = no limit in 1.3.3; it was `5m` in 1.1.x;
**on expiry agy prints partial output and exits 0**, with stderr
`[agy] print timeout after <N> with turn in progress; returning partial output`.
Verified on 1.3.3 with `--print-timeout 2s`. Do not pass it for long work;
if you do, capture stderr and treat a `print timeout after` line as a
failure, never as success: the exit code will not tell you), `--output-format
text|json|stream-json`, `--json-schema`, `--mode accept-edits|plan`,
`--dangerously-skip-permissions`, `--continue`, `--conversation <id>`.

## Tiers

| tier | model |
|------|-------|
| `lo` | `gemini-3.8-flash-low` |
| `flash` | `gemini-3.8-flash-high` |
| `pro` | *(none — no Gemini pro model as of 2026-10-13)* |

There is currently no `pro` tier: the Gemini 3.1 pro model was removed upstream
(agy 1.3.3 rejects it: "not recognized as a known model"). Use `flash`; if it
fails, fall back to the caller's own model, not to another agy id. Re-check with
`agy models`, and run `scripts/check_models.sh` after any edit to model ids.

Gemini 3.8 Flash is the current workhorse (Google positions it for "complex
agentic tasks at scale") and replaced 3.7 as the default tier here on
2026-09-07; 3.7 was removed by 2026-10-13. `agy models` lists everything
available, including non-Gemini entries (`claude-sonnet-4-6`,
`claude-opus-4-6-thinking`, `gpt-oss-120b-medium`) — note that routing to a
Claude model through agy spends Anthropic capacity, which defeats the point if
you delegated to save it.

## Host hazard: RTK rewrites git

If your shell runs an RTK `PreToolUse` hook, it rewrites `git diff` to
`rtk git diff`, which **drops context lines** and breaks unified-diff parsing.
Always capture diffs and status with **`rtk proxy git diff`** /
`rtk proxy git status`. Sending the rewritten form to a reviewer hands it a
summary of the change instead of the change.

If RTK is not installed, plain `git` is correct — check with `command -v
rtk`. Wherever this skill writes `rtk proxy git …`, drop the `rtk proxy`
prefix if `command -v rtk` finds nothing; the hazard above is specific to RTK
being present, not to git itself.

## Auth markers

`agy models` succeeding proves authentication. To distinguish "installed but
never authenticated" from ready without a network call, check for
`~/.gemini/antigravity-cli/antigravity-oauth-token` (1.3.3; older versions
used `~/.gemini/oauth_creds.json`) and
`~/.gemini/antigravity-cli/settings.json`. Never print the token file.

## Digest contract

Close every read/analysis prompt with an explicit output contract, e.g.
"Output ONLY 5–8 bullets. No file contents, no code blocks." Then ingest the
digest and **do not re-read the files agy already handled** — re-reading them
puts back exactly the cost this skill removes.
