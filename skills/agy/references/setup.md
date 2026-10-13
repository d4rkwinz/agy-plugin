# setup — is agy ready?

Report whether `agy` is installed, authenticated, and ready.
Read [invariants.md](invariants.md) first.

## Run

    agy --version
    agy models

See [invariants.md](invariants.md) § Auth markers.

## Then check the state markers

    ls ~/.gemini/antigravity-cli/antigravity-oauth-token ~/.gemini/antigravity-cli/settings.json

## Report

- Is `agy` on PATH, and what version?
- Did `agy models` succeed? Which tiers are available — are lo and flash
  present (there is no pro tier)? See [invariants.md](invariants.md) § Tiers.
- Are both state markers present?
- Is `rtk` installed (`command -v rtk`)? If yes, see [invariants.md](invariants.md)
  § Host hazard.

If anything is missing, give the exact fix command and nothing more. Keep the
report to a few lines.
