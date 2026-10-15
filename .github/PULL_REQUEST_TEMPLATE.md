<!-- PR title must be a Conventional Commit, e.g. `feat(engine): enforce 7-day no-repeat` — it becomes the squash commit. -->

## Summary
<!-- What does this PR do and why? One or two sentences. -->

## Changes
-

## Screenshots
<!-- Required for any UI change (EN + اردو / RTL). Delete if not applicable. -->

| English | اردو |
| ------- | ---- |
|         |      |

## Test evidence
<!-- Paste the relevant output: analyze, test, coverage. -->
```
flutter analyze:
flutter test:
domain coverage:
```

## Checklist
- [ ] `flutter analyze` reports no issues
- [ ] TDD: failing tests committed before the implementation (red → green visible in commits)
- [ ] Tests added/updated and passing; domain coverage ≥ 80%
- [ ] UI strings live in ARB files (en + ur); no hardcoded text
- [ ] Screenshots attached for UI changes
- [ ] Docs updated (`docs/`), deviations recorded in `docs/DECISIONS.md`
- [ ] No TODOs without an issue link
- [ ] < 500 changed lines excluding generated code (or justified below)

## Linked issue
Closes #
