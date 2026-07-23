# Branch Protection Notes

Recommended branch protection for YohPal Live streaming overlay:

## Protected branches

- main
- develop
- release/*

## Required status checks

- Streaming Overlay Guardrails

## Pull request rules

- require PR before merge
- require at least one developer review
- require CI success
- block force pushes
- block direct pushes to main
- require conversation resolution

## Streaming-specific rule

Any PR that modifies:

```text
modules/live-streaming/
```

must include evidence of:

- `npm run ci`
- local Docker startup /health endpoint
- browser test client
- Flutter analyzer
- device validation if applicable
