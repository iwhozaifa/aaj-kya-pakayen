# Aaj Kya Pakayen — آج کیا پکائیں؟

**Dinner, decided. — رات کا کھانا، طے!**

A Flutter app that answers one question: *what's for dinner tonight?* It looks at:

- what was cooked in the last 7 days
- whether tonight is a sabzi day or a gosht day
- the chicken, beef, mutton and mince in the kitchen

It is built Urdu-first, with large text, for Pakistani home cooks.

## What it does

- **Today**: tonight's top idea with its reasons and a side dish, two more ideas, and a sabzi or gosht day badge. Actions: Cooking this, Show another, Ordering outside, and Swap today's type.
- **Stock**: chicken, beef, mutton and mince with ± 250 g buttons, purchases, and low-stock badges. Cooking a dish uses the oldest meat first.
- **History**: the last 7 days at a glance and every dinner from the last 60 days. Past days can be added, edited or deleted, and the suggestions adjust.
- **Dishes**: 78 Pakistani dishes. Search them, filter by type, switch any off, and add your own.
- **Settings**: اردو or English, household size, how long before a dish repeats, time to cook, a daily reminder (default 4:30 PM), and cuisine packs.
- **First run**: three questions (language, people at dinner, meat at home).
- Works fully offline. Every logging action can be undone.

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
- [Accessibility](docs/ACCESSIBILITY.md)
- [Releasing](docs/RELEASING.md)
- [Git workflow](docs/GIT_WORKFLOW.md)
- [Changelog](CHANGELOG.md)
- [Decisions](docs/DECISIONS.md)
