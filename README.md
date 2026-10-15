# Aaj Kya Pakayen — آج کیا پکائیں؟

**Dinner, decided. — رات کا کھانا، طے!**

A Flutter app that answers one question: *what's for dinner tonight?* It looks at:

- what was cooked in the last 7 days
- whether tonight is a sabzi day or a gosht day
- the chicken, beef, mutton and mince in the kitchen

It is built Urdu-first, with large text, for Pakistani home cooks.

## Getting started

```bash
flutter pub get
dart run build_runner build -d
flutter gen-l10n
flutter run
```

Requires Flutter 3.47.x (Dart 3.13).

## Quality gates

```bash
flutter analyze
flutter test --coverage          # add --update-goldens after an intended UI change
scripts/check_domain_coverage.sh 80
```

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Database](docs/DATABASE.md)
- [Branding](docs/BRANDING.md)
- [Git workflow](docs/GIT_WORKFLOW.md)
- [Decisions](docs/DECISIONS.md)
