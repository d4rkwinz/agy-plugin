# research — grounded multi-source research

agy does the cheap grounded legwork; **you own the plan, the verification, and
the synthesis.** Read [invariants.md](invariants.md) first.

agy's print-mode citations are coarse, often domain-level, and it can present
parametric knowledge as a sourced fact. Never ship its citations unchecked.

## 1. Plan (you)

Break the topic into 3–6 sub-questions. List the load-bearing claims — the ones
where being wrong changes the conclusion. Those are what you will verify.

## 2. Fan out, one call per sub-question

Web search may need the permission flag in headless mode (some setups allow
it implicitly — see [invariants.md](invariants.md) § Hard rules, rule 4); pass
it to be safe:

    agy --model gemini-3.8-flash-high --dangerously-skip-permissions \
        -p='Web-search: <sub-question>. Return 5-8 bullet findings, each with
        the exact source URL and publication date. Output ONLY findings, URLs,
        and dates.'

In an interactive session these can run in the background; when you are
headless, run them synchronously.

## 3. Turn domain-level citations into quotes

For each load-bearing claim:

    agy --model gemini-3.8-flash-high --dangerously-skip-permissions \
        -p='Open <URL> and quote the exact sentence(s) supporting: "<claim>".
        If the page does not support it, reply NOT SUPPORTED.'

## 4. Verify adversarially (you)

- Corroborate each key claim across two independent domains.
- Treat any single, vague, or domain-only citation as unverified.
- Sanity-check publication dates — a stale source can be technically correct
  and practically wrong.
- Watch for confident claims with no URL attached. That is the parametric-knowledge
  failure mode.

## 5. Synthesize (you)

Write the report from verified findings only. Mark anything uncorroborated as
**unverified** in the text — not in a footnote. `--print` does one agentic pass
per call, so dispatch follow-up calls to close gaps rather than expecting agy to
iterate on its own.
