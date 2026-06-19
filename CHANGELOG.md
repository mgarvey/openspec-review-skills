# Changelog

## Unreleased

## v0.2.1 - 2026-06-19

- Teach `ensure-openspec-repo` to safely adopt legacy vendored metadata and
  validator files from older rollouts, including `v0.1.2`, while still refusing
  unknown user files.

## v0.2.0 - 2026-06-19

- Add `ensure-openspec-repo` for safe repo-local OpenSpec/Codex bootstrap and
  repair using vendored real `.agents/skills` files.
- Refine skill routing so focused review skills handle ordinary PR, proposal,
  evidence, security, and fixup-review requests.
- Make `review-code` an explicit-only multi-lens review suite for final
  readiness checks.
- Add OpenAI UI metadata for each skill.
- Add managed install options, validation scripts, routing fixtures, release
  manifest generation, CI validation, and downstream rollout templates.
