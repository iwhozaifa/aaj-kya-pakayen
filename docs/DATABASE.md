# Database

Local SQLite via [Drift](https://drift.simonbinder.eu/). Schema version **1**.

- Tables: `lib/data/db/tables.dart`
- Database: `lib/data/db/app_database.dart`
- DAOs: `lib/data/db/daos/`
- Repositories (domain-typed): `lib/data/repositories_impl/`, exposed by `lib/data/providers.dart`

Seed data arrives in `feature/seed-dishes` (#4).

## ER diagram

```mermaid
erDiagram
    dishes ||--o{ dish_pairings : "main_dish_id"
    dishes ||--o{ dish_pairings : "side_dish_id"
    dishes ||--o{ dinner_log : "main_dish_id / side_dish_id"
    pantry_items ||--o{ pantry_movements : "pantry_item_id"
    dinner_log |o--o{ pantry_movements : "dinner_log_id"

    dishes {
        int id PK
        text name_en
        text name_ur
        text cuisine "default 'pakistani'"
        text dish_type "indexed"
        bool is_veg
        text protein_type "nullable"
        int protein_grams_per_person "nullable"
        text staple_pairing
        text cooking_style
        int prep_minutes
        bool can_be_side
        bool is_custom
        bool is_active
        text variant_group "nullable, D-007"
        text notes "nullable"
    }
    dish_pairings {
        int main_dish_id PK,FK
        int side_dish_id PK,FK
        int priority "lower = preferred"
    }
    pantry_items {
        int id PK
        text protein_type "indexed"
        int quantity_grams
        datetime added_on
        datetime updated_at
    }
    pantry_movements {
        int id PK
        int pantry_item_id FK
        int delta_grams
        text reason
        int dinner_log_id FK "nullable, indexed"
        datetime created_at
    }
    dinner_log {
        int id PK
        text date UK "yyyy-MM-dd"
        text day_type
        text source
        int main_dish_id FK "nullable"
        int side_dish_id FK "nullable"
        text outside_note "nullable"
        bool was_suggested
        datetime created_at
    }
    app_settings {
        text key PK
        text value
    }
```

## Storage conventions

- **Enums** are stored by their Dart name. The brief's upper-case names map like this:

  | Brief | Stored |
  | --- | --- |
  | `VEG_DAY` | `vegDay` |
  | `NON_VEG_DAY` | `nonVegDay` |
  | `RICE_DISH` | `riceDish` |
  | `VEGETABLE` | `vegetable` |
  | `CHICKEN` | `chicken` |

  The rest follow the same pattern.
- **`dinner_log.date`** is `yyyy-MM-dd` text with a `UNIQUE` constraint. That gives one dinner per calendar day and the index the brief asks for. Saving a second entry for a date replaces the first and keeps its id.
- **`dishes.is_veg` and `protein_type`** are written from `dish_type`, so they never disagree with it.
- **Foreign keys** are switched on at open:
  - Deleting a dish removes its pairings.
  - Deleting a dinner sets `pantry_movements.dinner_log_id` to null.
  - Dishes are deactivated (`is_active`), never deleted, so history keeps its references.
- **Pantry:**
  - Each purchase is a new `pantry_items` row with a `purchase` movement.
  - Every change goes through `PantryRepository.applyMovement`, which updates the batch and appends the movement in one transaction. It refuses to go below zero.
  - Batches with 0 g are kept for the ledger but hidden from stock lists.
- **Settings** are one readable row per key:

  | Key | Example |
  | --- | --- |
  | `household_size` | `4` |
  | `repeat_window_days` | `7` |
  | `language` | `ur` |
  | `enabled_cuisines` | `pakistani` (comma-separated) |
  | `reminder_enabled` | `false` |
  | `reminder_time` | `16:30` |
  | `time_budget` | `normal` |
  | `day_type_override` | `2026-10-15:nonVegDay` |
  | `onboarding_complete` | `false` |

  Unreadable values fall back to defaults.

## Indexes

| Index | Columns |
| --- | --- |
| `idx_dishes_dish_type` | `dishes(dish_type)` |
| `idx_pantry_items_protein_type` | `pantry_items(protein_type)` |
| `idx_pantry_movements_dinner_log` | `pantry_movements(dinner_log_id)`, used by undo |
| *(unique autoindex)* | `dinner_log(date)` |

## Migrations

1. Change the tables and bump `schemaVersion`.
2. Run `dart run drift_dev make-migrations`. It dumps `drift_schemas/app_database/drift_schema_vN.json` and regenerates `test/data/db/migrations/generated/`. Commit both.
3. Add the step to `migration` in `AppDatabase`.
4. `test/data/db/migrations/migration_test.dart` checks:
   - that the code schema matches the latest dump
   - every upgrade path between dumped versions
