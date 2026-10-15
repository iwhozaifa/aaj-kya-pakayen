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
