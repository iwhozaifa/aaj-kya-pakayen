# Decisions

Deviations from the original brief, and interpretations of points it left open. Newest last.

## D-001 — `public_member_api_docs` disabled
`very_good_analysis` is used, but this lint is turned off: this is an app, not a published
package, and documenting every widget constructor adds noise. All other rules stay on, and
`analyze` runs with `--fatal-infos`.

## D-002 — 0 required approvals
PRs are created from the repository owner's GitHub account, and GitHub forbids self-approval.
A 1-approval rule would block every merge, so branch protection requires a PR plus a green `ci`
check instead. Review happens by process: nothing is merged until the owner confirms.

## D-003 — Back-merging `main` into `develop`
`develop` requires linear history, but the release back-merge (`main → develop`) is a merge
commit. `enforce_admins` is therefore off, and the owner (admin) pushes the back-merge directly
as a documented release step. Feature branches never bypass protection.

## D-004 — Bundled fonts
Poppins, Nunito and Noto Nastaliq Urdu are bundled under `assets/fonts/` (OFL licence) rather than
fetched with `google_fonts`. The app must work offline on first launch.

## D-005 — Generated code is not committed
`*.g.dart` and `*.freezed.dart` are git-ignored and regenerated in CI with `build_runner`.
This keeps diffs small and reviewable. Drift schema dumps (JSON) *are* committed, because
migration tests need them.

## D-006 — `sqlite3_flutter_libs` not used
With `sqlite3` 3.x, native SQLite ships through build hooks and `sqlite3_flutter_libs` is obsolete.
The app uses `drift_flutter` to open the database.

## D-007 — Engine semantics (open points in the brief)
1. **Day type:** tonight is the flip of the most recent logged dinner's `day_type`, however many
   days ago it was. With no history, the default is `VEG_DAY`.
2. **Swap:** stores a one-day override (`day_type_override` = date + type) in `app_settings`.
   The dinner logged that night records the type actually cooked, so tomorrow flips from that.
3. **No repeat:** `dishes.variant_group` (nullable, an addition to the brief's schema) groups
   variants, e.g. chicken karahi and white karahi. A dish is blocked if it or any dish in its
   group appeared as a main **or** a side within the window (`today - lastCooked < window`).
4. **Pantry:** a dish is cookable when `protein_grams_per_person × household_size` ≤ the total
   stock of that protein type. "Cooking this" deducts from the oldest batches first (FIFO) and
   writes one `pantry_movements` row per batch touched. Undo reverses them.
5. **Outside:** always offered on `NON_VEG_DAY`. It ranks first, with a restock hint, when no
   home-cooked non-veg dish passes the hard filters.
6. **Time budget:** quick ≤ 30 min, normal ≤ 60 min, elaborate = no limit.
7. **Seed:** tie-breaking randomness is seeded with `yyyymmdd * 31 + anotherCount`.
8. **Reasons:** reasons are `ReasonCode` values with arguments, localized by the UI.
   The domain layer holds no user-facing strings.
9. **Pantry tiles:** four tiles — Chicken, Beef, Mutton and Mince.

## D-008 — Bootstrap placeholder screen has no text
Until ARB files exist (#2), the placeholder home screen shows only an icon, so the
"no hardcoded strings" rule holds from the first PR.

## D-009 — Test-driven development
At the owner's request, all work from `feature/design-system` onward is test-driven: a failing
`test:` commit comes before each `feat:`/`fix:` commit (see GIT_WORKFLOW.md). The bootstrap PR is
mostly scaffolding and configuration, so only its domain enum and layering rules come with tests.

## D-010 — Localization output is generated, not committed
`flutter gen-l10n` writes to `lib/core/l10n/generated/`. That folder is git-ignored and created in CI,
like the build_runner output (D-005). Urdu (`ur`) is the default locale; `appLocaleProvider` holds it
until the Settings screen persists the choice (#10).

## D-011 — Goldens use the real fonts
`test/flutter_test_config.dart` loads the bundled fonts and Material Icons, so golden files show real
Nastaliq and Latin text instead of the Ahem test font. Goldens are made on Linux, the same platform as
CI. Regenerate them with `flutter test --update-goldens` and review the PNGs in the PR. The PR
screenshots are these goldens.

## D-012 — Cards use a border instead of a shadow
Cards use a 2dp Saffron-tint border with no elevation. That reads better on the Cream background
and stays crisp in goldens. Buttons are at least 56dp tall (the brief asks for 48dp), and `BigButton`
is 64dp.

## D-013 — Urdu text avoids the middle dot
In Nastaliq, `·` looks like the Urdu zero `٠`. Urdu strings use `—` or `،` as separators.

## D-014 — freezed classes keep classic constructor syntax
Dart 3.13's `unnecessary_type_name_in_constructor` lint wants `factory new(...)`. freezed 4.0.2, the
latest release, can't parse that yet. Each freezed file has a file-level ignore for that one lint;
every other class uses `new`.

## D-015 — Storage details not in the brief
Enums are stored by Dart name (`vegDay`, not `VEG_DAY`). `dinner_log.date` is `yyyy-MM-dd` text. Its
UNIQUE constraint provides the index on that column. Settings are typed in the domain
(`AppSettings`) and stored as key/value rows in `app_settings`. `reminder_enabled`,
`day_type_override` and `onboarding_complete` are keys we added beyond the brief's list. See
DATABASE.md.

## D-016 — json_serializable uses `explicit_to_json`
Set in `build.yaml`, so nested freezed objects (e.g. `AppSettings.dayTypeOverride`) serialize properly.
The domain coverage gate ignores `*.g.dart` and `*.freezed.dart`.

## D-017 — Seed catalogue choices
- **Dish count:** 78, beyond the brief's minimum of 70. Added everyday dishes the brief didn't list: aloo gosht, daal gosht, aloo chicken salan, chapli kebab, daal qeema, sarson ka saag and others.
- **Paye** is filed under beef. **Haleem** is beef at 100 g per person because it is mostly grain and daal.
- **Pulao and biryani** have `staple_pairing = none`, because they are the staple themselves.
- **Rice pulses:** seven pulse dishes are paired with rice (daal chawal, masoor daal, khichdi, rajma, lobia, chana pulao, kadhi).
- **`app_settings.seed_version`** is owned by the seeder. `SettingsRepository.save` only replaces the keys it owns.

## D-018 — "Show me another" rotates the ranking
D-007 planned to reseed the jitter with `anotherCount`. That doesn't guarantee a new dish on top: a
reseed can put the same dish first again. Instead, the ranking is seeded by date only, and each tap
rotates the ranked list by one. The next-best dish always comes up, and the same tap count always
gives the same answer.

## D-019 — How "Order from outside" is offered
`SuggestionResult.canOrderOutside` is true on every non-veg day, so the Today screen always shows the
button. `OutsideSuggestion` is the suggestion itself only when no home meat dish passes the hard
rules. In that case `restock` lists the proteins whose dishes are blocked only by stock. It is empty
when the no-repeat rule is the cause.

## D-020 — Side dishes come only from curated pairings
The engine proposes a side only from `dish_pairings`. It never pairs ad hoc with any `can_be_side`
dish. This keeps combinations culturally sensible. A side must also pass the no-repeat rule.

## D-021 — Pantry quick adjust and undo
- **The − button** removes 250 g, or whatever is left, oldest batch first (FIFO), with reason `adjust`.
- **The + button** adds 250 g to the newest batch, or starts a new batch. That keeps the use-it-first age honest: a top-up doesn't make old meat look new.
- **Undo** deletes the movements and restores the batches (`revertMovements`), so the ledger doesn't fill with correction rows. An undone purchase removes its batch.
- **Low stock** means less than `household × 200 g`, i.e. not enough for one typical meat dinner.

## D-022 — Urdu protein names
Tiles use the everyday kitchen words چکن، بیف، مٹن، قیمہ instead of the formal "مرغی / گائے کا گوشت / بکرے کا گوشت". They match the dish names and fit on one line at large text sizes.

## D-023 — Navigation grows tab by tab
The bottom `NavigationBar` (go_router `StatefulShellRoute`) starts with Today and Stock. History, Dishes and Settings join as their branches land, so there are never tabs that lead to empty screens.

## D-024 — Logging a dinner
- **"Cooking this"** saves the entry, then deducts `grams/person × household` of the main's protein, FIFO, linked to the entry. If stock dropped since the suggestion was made, it deducts only what is left, so logging never fails.
- **Re-logging the same date**, from Today's Change button or the history editor, first gives back the earlier entry's stock.
- **Undo, and Today's "Change"** delete the entry and revert its movements.
- **An outside dinner** is always logged as a non-veg day. A blank note is stored as none.
- **The swap button toggles.** Swapping an already swapped evening removes the override.

## D-025 — Day badge uses icons, not emoji
The brief shows "Sabzi Day 🥬 / Gosht Day 🍗". The badge uses Material icons (`eco`, `set_meal`) instead. The bundled fonts have no emoji glyphs, and system emoji render differently on each device and as blank boxes in goldens. In English the label reads "Sabzi day" / "Gosht day", as in the brief.

## D-026 — Secondary buttons use dark text
Turmeric text on cream fails WCAG contrast. Outlined and text buttons use Chai Brown text with a Turmeric border. Turmeric stays as the fill of primary buttons, which have dark text. The Today screen test checks Flutter's `textContrastGuideline`.
