# CI/CD Guardrails

## Purpose

This guardrail layer prevents the YohPal Live streaming overlay from breaking the existing YohPal Live foundation.

## What CI validates

- required overlay files exist
- Node server smoke tests pass
- signaling contract tests pass
- Docker Compose config parses
- TURN config can be generated
- Flutter overlay static file structure exists
- merge safety notes are present
- overlay does not contain dangerous replacement paths

## GitHub workflow

Workflow file:

```text
.github/workflows/yohpal-live-streaming-overlay.yml
```

### Commands

From: `modules/live-streaming/`

Run: `npm run ci`

Or individually:

```
npm run ci:required-files
npm run ci:no-overwrite
npm run test
npm run ci:merge-safety
```

### Protected branch recommendation

Require these checks before merging into:

- main
- develop
- release/*

### Required PR evidence

Every pull request changing streaming must include:

- screenshot of `npm run ci`
- Docker health check evidence
- browser client validation evidence
- Flutter analyzer result from real YohPal Live app
- Android/iOS validation if native behavior changed
