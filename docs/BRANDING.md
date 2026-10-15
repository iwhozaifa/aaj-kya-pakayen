# Branding

**Name:** Aaj Kya Pakayen — آج کیا پکائیں؟ ("What shall we cook today?")
**Tagline:** "Dinner, decided." — "رات کا کھانا، طے!"

## Palette

| Token | Hex | Use |
| --- | --- | --- |
| Turmeric | `#F2A900` | Primary |
| Cardamom | `#3E6B48` | Veg / secondary |
| Chilli | `#C0392B` | Meat / accent |
| Cream | `#FFF8EC` | Background |
| Chai Brown | `#2B2118` | Text |
| Saffron tint | `#FFE2A8` | Surface highlight |

## Typography

- Latin: Poppins (headings) and Nunito (body). Urdu: Noto Nastaliq Urdu.
- Fonts are bundled as assets, not fetched at runtime (see DECISIONS D-004).
- Body text is at least 18sp. Nastaliq needs a taller line height (≈1.8).

## Shape and iconography

- Material 3, rounded 20dp cards, soft shadows.
- The logo is a simple pot/karahi mark, kept in `assets/brand/` as SVG.
- Launcher icons are generated with `flutter_launcher_icons`, splash screens with `flutter_native_splash`.

## Voice

Warm, brief and respectful, with no jargon. For example: "Aaj sabzi ka din hai."

The theme and assets are built in `feature/design-system` (#2).
