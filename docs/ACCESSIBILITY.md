# Accessibility

The app is built for a home cook who reads Urdu, may use large system text, and should never have to guess how to do something. These rules apply to every screen, and tests enforce them.

## Rules

| Rule | How it is met | Enforced by |
| --- | --- | --- |
| Text at least 18sp | Every `TextTheme` style is 18sp or more; Urdu uses Noto Nastaliq with 1.9 line height | `test/core/theme/app_theme_test.dart` |
| Touch targets at least 48 dp | Buttons are 56 dp (main actions 64 dp); icon buttons 56 dp; history day chips at least 48 dp wide | `androidTapTargetGuideline` in each screen test |
| Every control is labelled | Icon-only buttons have tooltips, which screen readers read | `labeledTapTargetGuideline` |
| High contrast | Chai Brown text on Cream; Turmeric only as a fill under dark text (D-026) | `textContrastGuideline` |
| Readable at 2x system text | Layouts reflow instead of squeezing: protein tiles put ± below the name; the week strip wraps into balanced rows; settings options are full-width rows. Nav labels are capped at 18sp because they already have icons (D-034). | `test/accessibility/large_text_test.dart` drives every tab and sheet at 2x on a 360 dp phone in both languages and fails on overflow, faded text, or a word split across lines |
| Right-to-left Urdu | `Directionality` comes from the locale; layouts use `start`/`end` | `test/app_test.dart` |
| No hidden gestures | Every sheet has a visible Cancel button; no swipe-to-delete; filters wrap instead of scrolling sideways (D-030) | Screen tests tap Cancel |
| Undo after logging | Cooking, ordering outside, editing or deleting history, stock changes, and hiding or adding dishes all show an undo snackbar | Screen tests tap Undo |
| Empty and error states | Each list has a friendly empty state; each screen that loads data shows "Something went wrong" with Try again | Screen tests; `test/accessibility/error_states_test.dart` |

## Checking a change by hand

1. Set the phone's font size to the largest and display size to large.
2. Switch the app to اردو and walk through every tab and sheet.
3. Turn on TalkBack. Every button should announce what it does, and the
   day chips announce their date.
