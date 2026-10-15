# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-15

The first release: dinner, decided. — رات کا کھانا، طے!

### Added

**Today**
- Tonight's top suggestion with a curated side dish and the reasons for it (protein in stock, a different protein from last time, a fresh cooking style, fits the time, served with rice or roti).
- Two other ideas below the top suggestion.
- Sabzi day and gosht day alternate automatically from the last dinner logged.
- Actions:
  - **Cooking this** logs the dinner and uses the oldest meat in stock first.
  - **Show another** steps through more ideas.
  - **Ordering outside** logs a meal from outside, with an optional note.
  - **Swap today's type** changes tonight only and doesn't break tomorrow's alternation.
- No dish or dish variant repeats within the window (7 days by default). When nothing at home is possible, the app suggests ordering outside and says which meat to restock.

**Stock**
- Chicken, beef, mutton and mince, with ± 250 g buttons, purchases with a date, the age of the oldest batch, and low-stock badges sized to the household.

**History**
- The last 7 days at a glance and every dinner from the last 60 days. Past days can be added, edited or deleted, the stock is corrected, and suggestions adjust.

**Dishes**
- 78 Pakistani dishes with 19 curated pairings.
- Search in Urdu or English, filter by type, switch dishes off and on, and add your own.

**Settings**
- اردو or English (right-to-left for Urdu).
- Household size and the no-repeat window.
- Time to cook.
- An optional daily reminder (4:30 PM by default).
- Cuisine packs: Pakistani included, others coming soon.

**First run**
- Three questions: language, people at dinner, and the meat at home.

**Throughout**
- Every logging action can be undone from a snackbar.
- Accessibility:
  - Text of at least 18sp and touch targets of at least 48 dp.
  - High-contrast brand colours.
  - Readable at 2× system text.
  - Visible Cancel buttons; no hidden gestures.
  - Friendly empty states, and error states with Try again.
- Works fully offline with a local SQLite database (Drift). A sync interface is ready for later.

[1.0.0]: https://github.com/iwhozaifa/aaj-kya-pakayen/releases/tag/v1.0.0
