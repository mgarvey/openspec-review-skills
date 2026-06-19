# Security Policy

These skills are prompt instructions, not executable services, but they can
shape how an agent uses powerful tools. Treat them like code.

## Reporting

Please open a private security advisory or contact the repository maintainer
for issues involving:

- credential exposure
- instructions that could cause destructive actions without approval
- prompt-injection or supply-chain risks in skill metadata
- unsafe install instructions
- private data accidentally committed to the repository

Do not publish working exploit details before the issue is triaged.

## Expected Posture

- Review skills are read-only by default.
- OpenSpec review skills should stay read-only unless a downstream fork clearly
  documents a different, user-approved task scope.
- Destructive, production-changing, or externally mutating commands require
  explicit user approval.
- Skills should not access, print, decode, validate, or transmit real secrets.
