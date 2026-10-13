# Changelog

## 0.2.0

- Replaced removed Gemini model ids (3.1 pro, 3.7) with
  `gemini-3.8-flash-high` / `gemini-3.8-flash-low`; there is no `pro` tier now.
- Added `scripts/check_models.sh`, which fails if the skill names a model id
  that `agy models` does not list.
- Open-source release prep: MIT `LICENSE`, README claims corrected, broken
  design-doc link removed, security reporting note, shorter skill description,
  invariants re-verified against agy 1.3.3 (new auth marker file, `--effort`
  conflicts with effort-suffixed model ids, `--print-timeout` default), Hermes
  tap/direct-GitHub install tested and documented.

## 0.1.0

- Initial release: the `agy` skill (setup, review, delegate, research, media),
  Claude Code plugin manifests, Hermes install notes, `smoke.sh`.
