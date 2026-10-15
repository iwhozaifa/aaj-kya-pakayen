# Database

Local SQLite via [Drift](https://drift.simonbinder.eu/). The schema, DAOs, migrations and ER
diagram land in `feature/database-schema` (#3). The seed data arrives in `feature/seed-dishes` (#4).

## Tables (planned, schema v1)

| Table | Purpose |
| --- | --- |
| `dishes` | Bilingual dish catalogue with type, protein needs, cooking style, staple pairing |
| `dish_pairings` | Curated main → side pairings with priority |
| `pantry_items` | One row per protein purchase batch (enables oldest-first use) |
| `pantry_movements` | Append-only ledger of stock changes (purchase, cooked, adjust, discard) |
| `dinner_log` | One row per day: day type, home/outside, main and side dish |
| `app_settings` | Key/value settings |

## Migrations

- Each schema version is dumped with `dart run drift_dev make-migrations` and the dumps are committed.
- Every migration step has a test that runs the generated schema verifier.
