# PHY 104 question bank

`assets/questions/phy104.json` now contains **200 unique, source-grounded
multiple-choice questions** for **PHY 104 — Vibration, Waves & Optics**, replacing
the previous 200 copies of a generic placeholder stem.

## What changed

| Item | Before | After |
| --- | --- | --- |
| Question stems | 1 unique generic stem | 200 unique stems |
| Options | Same "Concept A/B/C/D" set | Plausible, question-specific options |
| Explanations | 1 generic sentence | One explanation per question |
| Difficulty | All `1` | Mix of `1` (65), `2` (115) and `3` (20) |
| Answer positions | Exactly 50 each | Spread across indices 0–3 |
| Bank version | `1.0.0` | `2.0.0` |
| Catalog `updatedAt` | `2026-11-06T00:00:00Z` | `2026-11-06T09:00:00Z` |

The catalog entry for `phy104` was bumped to `2.0.0`, and the top-level
`updatedAt` was bumped. Installed apps will therefore re-download only the PHY
104 bank on their next catalog sync, using the existing public JSON mechanism.

## Topics covered

1. Simple Harmonic Motion — 44 questions
2. Damped, Forced & Coupled Oscillations — 8
3. Wave Properties & Equations — 34
4. Superposition, Interference & Diffraction — 13
5. Sound Intensity & Perception — 40
6. Doppler Effect, Beats & Echoes — 10
7. Waves in Pipes & Resonance — 19
8. Geometrical Optics — 24
9. Wave Optics & Polarization — 8

Each question carries a `topic` tag, and the bank has a top-level `topics` list.
The current quiz UI does not display or filter by these tags yet; they are
forward-compatible metadata in the JSON file only, so no Dart or release change
was needed.

## Sources used

- `100level/second semester/phy104/PHY 104 complete.pdf`
- `100level/second semester/phy104/PHY 104 LECTURE NOTE(3)_013225.pdf`

Conceptual items follow definitions and statements in those notes. Numerical
items use formulas and worked examples from the same material, including
`T = 2π√(m/k)`, `T = 2π√(l/g)`, `v = fλ`, `v = ω/k`, `I = P/A`,
`β = 10 log10(I/I₀)`, `v = 331√(1 + Tc/273)`, `v = √(E/ρ)`, `v = √(B/ρ)`,
`fbeat = |f₁ − f₂|`, `v = 2f(l₂ − l₁)`, `P = 1/f`, Snell's law and the
critical-angle relation.

## Not included

`100level/second semester/phy104/PHY 104 Questions.pdf` is image-only. It has
no extractable text, so its past questions were **not copied, guessed, or
OCR-generated**. Adding them requires OCR or manual transcription first.

These are new practice questions derived from the course notes, not a
transcription of that scanned past-questions paper.

## Regenerate and validate

From the repository root:

```bash
python3 scripts/generate_phy104.py
python3 scripts/validate_courses.py
```

The generator is deterministic and checks for duplicate stems, duplicate
options, invalid answer indices, empty explanations and leftover placeholder
wording before writing the JSON.

No keystore, signing configuration, GitHub Actions secret, or Play Console
upload is involved. This is a public JSON content update plus a local authoring
script.
