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

## D-027 — Editing history
- **Editing a past day** re-logs it through `LogDinner`. Stock from the old entry is given back, and the new dish's protein is deducted, so the pantry always matches the log. The change is applied now; the pantry isn't rebuilt for the past.
- **Day type of an edited day** comes from the chosen dish: veg or pulse means veg day, meat means non-veg day, and outside means non-veg day. Undo restores the original entry exactly, including a swapped day type.
- **Entries added from History** are marked `was_suggested = false`.
- **History shows 60 days.** Inactive dishes still show their names, but the edit picker only offers active dishes.
- **The week strip** is Material `Tooltip`/`InkWell` chips at least 48 dp wide on a 360 dp phone.

## D-028 — Font fallback between scripts
The Urdu theme falls back to Nunito, and the English theme falls back to Noto Nastaliq Urdu. User text such as outside notes can be in either script; without the fallback, Latin text in Urdu mode rendered as missing-glyph boxes.

## D-029 — Custom dishes
- **One name, used for both languages.** The add sheet asks for a single name, typed in Urdu or English, and stores it as both `name_en` and `name_ur`. Asking for two names would make the form twice as long, and a dish the cook named herself reads correctly in either language.
- **Names must be unique.** The check ignores case and extra spaces and covers both languages and hidden dishes. The sheet shows the clash before saving, and `AddCustomDish` checks again.
- **Ids continue from 10000** (`firstCustomDishId`, now defined in the domain). Each new dish gets the highest custom id plus one, so ids are never reused while history might point at them.
- **Meat portions default** to 200 g per adult, or 150 g for mince, matching the seed. Custom dishes are never offered as sides, because sides come only from curated pairings (D-020).
- **No delete.** Built-in and custom dishes are switched off ("Not suggested") instead, which keeps history intact. Only the undo straight after adding a dish deletes it, through `deleteCustom`, which ignores built-in ids.

## D-030 — Dishes screen layout
- **Type filters** are a wrapping row of chips rather than a horizontally scrolling one, so no chip is hidden off-screen (no hidden gestures).
- **"Add dish"** is a full-width button fixed below the list rather than a floating action button, so it never covers a dish's switch.
- **Each dish row** is a whole-row `SwitchListTile`, a large tap target. Switching it off or on shows an undo snackbar. Hidden dishes stay listed, after the active ones, so they can be switched back on.

## D-031 — Daily reminder
- **Off by default, 4:30 PM when turned on.** Turning it on asks for notification permission. If permission is refused, the switch stays off and a snackbar explains how to allow it in the phone's settings.
- **Inexact scheduling** (`AndroidScheduleMode.inexactAllowWhileIdle`) with `DateTimeComponents.time` repeats daily. A dinner nudge doesn't need to be exact to the minute, so the app avoids the exact-alarm permission that Android 14 restricts.
- **Time zone** is the phone's own (`flutter_timezone`), falling back to Asia/Karachi. The boot receiver in the manifest re-creates the reminder after a restart.
- **Text follows the app language.** Changing the time or language while the reminder is on reschedules it. Android names the channel only once, so the channel name shows both languages.
- **Android only.** The app ships for Android. On other platforms `LocalNotificationsReminderScheduler` does nothing. The domain depends only on `ReminderScheduler`, and tests use a fake.

## D-032 — Settings, onboarding and navigation
- **Settings save as they change.** There is no Save button. The app follows through the settings stream: the language comes from `AppSettings.languageCode` (`appLocaleProvider`), and suggestions re-run on household, window or budget changes.
- **Limits:** household 1–20 people and repeat window 3–14 days, clamped in `AppSettings`. The stepper buttons disable at the ends.
- **Cuisine packs** list Pakistani as "Included" and Indian, Afghan and Chinese as "Coming soon". The Pakistani pack can't be switched off, because with it off there would be nothing to suggest.
- **Onboarding** has three steps: language, household, then meat at home (None, 500 g, 1 kg, 2 kg or 3 kg per protein, saved as purchases made today). The language is saved as soon as it is chosen, so the next two steps appear in that language. The go_router redirect watches `onboardingComplete`, and startup loads settings before the first frame, so a returning cook never sees onboarding flash.
- **Five tabs.** With five tabs there is room for one short word per label at 18sp. The Urdu History tab reads "ریکارڈ"; the screen title is still "پچھلے کھانے".

## D-033 — App wiring lives in core
`core/router`, `core/startup` and `core/l10n/locale_provider.dart` compose the app: they route to every feature screen, seed and preload data, and read the saved language. They import `data/providers.dart` and feature screens, which the plain `core/` rule forbids. These files are the documented exception rather than a separate `app/` layer, which would add a folder for three files. Reusable `core/` code (theme, widgets, labels, utils) still imports neither `data/` nor `features/`.

## D-034 — Large text
Tested at 2× system text on a 360 dp phone (`test/accessibility/large_text_test.dart`). Overflow errors aren't the only way large text fails, so the test also fails on text faded out by `TextOverflow.fade` and on a single word split across lines.
- **Nav labels are capped at 1×.** They are already 18sp (1.5× Material's 12sp), and each has an icon. With five tabs on 360 dp, larger labels split mid-word ("Histor / y"). Screen content is not capped.
- **Protein tiles** stack the ± buttons below the name when text is over 1.3×, so "Chicken" keeps its full width.
- **History week strip** measures the longest weekday name. The 7 chips go in one row if the names fit; otherwise they go in balanced rows (4 + 3), never 6 + 1. This replaces the fixed 7-column row of D-027, which faded Urdu names like جمعرات even at 1×.
- **Settings choices** (language, time budget) are full-width option rows, not chips, because chip labels can't wrap.
- **Every sheet has a Cancel button**, so closing one doesn't depend on a drag or a tap outside.
- **Error states** show "Try again", which reloads the screen's provider. Riverpod also retries on its own in the background.

## D-035 — Performance pass
- **The engine takes about 2.5 ms per suggestion** with 1,000 dishes and a year of history, against 78 real dishes. `test/engine/engine_performance_test.dart` fails above 50 ms per suggestion to catch accidental quadratic work.
- **Queries that filter use indexes** (dish type, pantry protein, movements by dinner). Screens read through providers that refresh on drift change feeds rather than polling.
- **No further optimisation was needed.** Lists are 78 dishes and 60 days of history, well within what Flutter builds per frame. Adding complexity such as caching or isolates would not pay for itself.
