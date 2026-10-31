# Agent instructions

This repo's full agent-facing guide is [`CLAUDE.md`](CLAUDE.md): architecture, commands,
conventions, and the rules that matter (fully offline, encrypted storage, feature-file-first).
It's written for any AI coding agent working in this repo, not just Claude — Codex, Cursor,
Aider, etc. should read it too. `AGENTS.md` exists as the vendor-neutral entry point several
tools look for by default; it just points here rather than duplicating the content.

For a one-page map of the project before diving into `CLAUDE.md`, see [`llms.txt`](llms.txt).

Two rules worth repeating because they're easy to miss skimming a diff:

- This app is **fully offline**: no network calls of any kind, not even opt-in ones. Don't add
  one without discussing it first (see `scripts/check_no_network_code.sh`).
- Behavior changes start in `docs/features/*.feature` (Gherkin). Update the relevant feature
  file as part of the change, not after.
