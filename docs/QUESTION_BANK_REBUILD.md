# Question-bank rebuild

All **13 placeholder banks** have been replaced with 200 unique, source-grounded
practice MCQs each. PHY 104 was the pilot; the remaining 12 were rebuilt in the
same data-only way.

| Item | Before | After |
| --- | --- | --- |
| Placeholder banks | 13 × 200 generic objects | 0 |
| Rebuilt banks | 0 | 13 × 200 questions |
| PHY 104 version | `1.0.0` | `2.0.0` |
| Other 12 versions | `1.0.0` | `2.0.0` |
| Catalog `updatedAt` | `2026-11-06T00:00:00Z` | `2026-11-06T10:00:00Z` |
| Total bundled questions | 3,800 objects | 3,800 objects, now all meaningful |

The six banks that already had varied questions (`bly111`, `csc111`, `gst111`,
`gst112`, `gst113_1`, `phy111`) were left unchanged. Three duplicate stems that
already existed in those pre-existing banks remain; this rebuild introduced no
cross-bank duplicate stems.

## Rebuilt IDs

- `phy104` — pilot, built by `scripts/generate_phy104.py`
- `chem111`, `mth111`, `bio102`, `bly121`, `bly122`, `chm102`, `chm121`,
  `chm122`, `gst113_2`, `mth121`, `phy102`, `phy121` — built by
  `scripts/generate_remaining_banks.py`

Every rebuilt bank has:

- 200 unique stems and 200 unique IDs;
- four shuffled, question-specific options (no "Concept A/B/C/D");
- a `correct_index` spread across 0–3;
- one explanation per question;
- a `difficulty` from 1 to 3;
- a bank-level `topics` list and a question-level `topic` tag;
- `sources` and `source_note` describing the material used.

The `topic` fields are forward-compatible metadata. The current quiz UI does not
display or filter by them yet, so no Dart or release change was needed.

## How the 12 banks were built

`scripts/generate_remaining_banks.py` reads text-bearing files already bundled
under `100level/`:

- PDFs via `pypdf`;
- `.docx` slides/notes via their XML text;
- `.pptx` modules via slide XML text;
- extensionless files whose bytes start with `%PDF`.

It then:

1. Reuses existing real questions where available:
   - 55 chemistry questions from `gen_questions.py` for `chem111`;
   - 70 mathematics questions from `assets/questions/mth111.p1.json` for
     `mth111`.
2. Extracts cleaned sentences from each course's source folders.
3. Blanks one course-specific term per sentence to create a cloze MCQ.
4. Uses three other course terms as distractors and shuffles the correct answer.
5. Cites the source file and the original sentence in the explanation.
6. Deduplicates stems globally across all rebuilt banks.
7. Validates count, uniqueness, options, answer indices, explanations,
   difficulty, topics and leftover placeholder wording before writing JSON.
8. Bumps the 12 catalog versions to `2.0.0` and `updatedAt` to
   `2026-11-06T10:00:00Z`, so installed apps re-download only those banks.

Related source folders were allowed to overlap where a course had few
text-bearing files (for example, PHY 102 also uses PHY 121 electricity and
magnetism notes). Global stem deduplication prevents the same cloze item from
appearing in two banks.

## Important limitations

- These are **new practice questions derived from the course notes**, not a
  transcription of official past exams. Image-only past-question PDFs were
  skipped; no OCR was performed. To add those exact questions, they need OCR or
  manual transcription first.
- PDF text extraction is imperfect. A small number of generated stems retain
  minor spacing or line-break artifacts from the source PDFs (for example,
  `"i nternal"` or `"nding"`). The questions remain answerable from the quoted
  sentence and explanation, but they are not hand-edited prose.
- The generator requires `pypdf`:

  ```bash
  python3 -m pip install pypdf
  ```

## Regenerate and validate

From the repository root:

```bash
python3 -m pip install pypdf
python3 scripts/generate_phy104.py
python3 scripts/generate_remaining_banks.py
python3 scripts/validate_courses.py
```

`generate_phy104.py` does not import `pypdf`; it is deterministic and can be
run on its own. The install line is only needed for
`generate_remaining_banks.py`, which reads the bundled PDFs.
`scripts/validate_courses.py` currently reports:

```text
OK: 19 courses, 3800 bundled questions, 0 warning(s).
```

The generator also checks for duplicate stems, duplicate options, invalid
answer indices, empty explanations, "Concept A/B/C/D" wording and
"all/none of the above" meta-options.

## No release setup involved

No keystore, `key.properties`, signing configuration, GitHub Actions secret,
Play Console upload, or app version bump was touched for this content update.
The existing public JSON catalog loader handles the refresh on installed apps;
after that, course-content changes remain public JSON edits.
