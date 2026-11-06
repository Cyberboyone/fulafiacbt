# Adding courses without touching release setup

**Short answer:** yes — after the loader in this change ships once, adding a course
is just a JSON edit in this repository. No keystore, GitHub Actions secret,
`key.properties`, Play Console upload, or new APK/AAB is needed for each course.

One honest caveat: the app that is already installed on users' phones cannot
magically gain the loader. You still need **one ordinary app update** to ship
this Dart code. After that update, new courses and question updates are pure
data. The existing CI workflow keeps using its secrets in GitHub Actions; you do
not need to handle them here.

## What this change does

- `assets/questions/courses.json` is the single course catalog. It is bundled in
  the app as an offline fallback and also read live from the public repo at
  `HEAD` (currently `master`).
- `CourseCatalogService` downloads the public catalog and only the new/changed
  question JSON files, validates them, and caches everything in Hive.
- `CourseProvider` shows the cached courses immediately, then refreshes in the
  background.
- **Settings → Course Updates** shows sync status and lets the user force a
  check.
- Nothing under `.github/workflows/`, `android/app/build.gradle`,
  `key.properties`, keystores, or signing config was changed.

The remote source is a public HTTPS URL:

```text
https://raw.githubusercontent.com/Cyberboyone/fulafiacbt/HEAD/assets/questions/courses.json
```

`HEAD` resolves to the repository's default branch, so pushing/merging to
`master` publishes the new content. No token is used because the repo is public.

## Add a new course (no app build)

1. Create `assets/questions/<course_id>.json`.

   Use lowercase letters, digits, `_` or `-` for `<course_id>`, for example
   `csc112.json`. The file must sit in the **same folder** as `courses.json`.

   ```json
   {
     "course_id": "csc112",
     "course_name": "Introduction to Programming II",
     "version": "1.0.0",
     "questions": [
       {
         "id": "csc112_001",
         "text": "Which structure repeats a block while a condition is true?",
         "options": ["Sequence", "Loop", "Function", "Constant"],
         "correct_index": 1,
         "explanation": "A loop repeats while its condition holds.",
         "difficulty": 1
       }
     ]
   }
   ```

   Notes:
   - `correct_index` is zero-based.
   - `text` or the legacy `question` key is accepted.
   - `explanation` and `difficulty` are optional.
   - Keep `version` in the question file equal to the catalog entry's `version`.

2. Add one entry to `assets/questions/courses.json`:

   ```json
   {
     "id": "csc112",
     "code": "CSC 112",
     "name": "Introduction to Programming II",
     "icon": "💾",
     "colorHex": "#DCEEFF",
     "mode": "100_level",
     "file": "csc112.json",
     "version": "1.0.0"
   }
   ```

   `file` must be a safe `.json` filename in the same folder — no paths, URLs,
   or `..` segments. `id` values must be unique, and `colorHex` must be a
   6-digit hex colour such as `#DCEEFF`. `mode` is currently `100_level` for
   every course.

3. Bump the top-level `updatedAt` timestamp, for example:

   ```json
   "updatedAt": "2026-11-07T09:30:00Z"
   ```

   The app ignores an online catalog whose `updatedAt` is older than the one it
   already has, so forgetting this step means users will not see the change.

4. Validate locally:

   ```bash
   python3 scripts/validate_courses.py
   ```

   This checks the catalog, every referenced question bank, versions, option
   indexes, IDs, colours, and that `pubspec.yaml` still bundles
   `assets/questions/`.

5. Commit and push/merge to the default branch (`master`):

   ```bash
   git add assets/questions/courses.json assets/questions/csc112.json
   git commit -m "content: add CSC 112 course"
   git push origin master   # or merge your PR into master
   ```

   That's it. The app picks it up on next launch while online, or immediately
   when the user taps **Settings → Course Updates → refresh**. Downloaded
   courses are cached and work offline afterwards.

   Merging to `master` also runs the existing GitHub Actions build. That
   workflow uses the secrets already stored in GitHub, so you still do not need
   them on your machine — but you also do not need to upload that build for a
   content-only course change.

## Update an existing course's questions

Edit the question JSON, then bump **both**:

- that course's `version` in `courses.json` (or rename its `file`), and
- the question file's own `version` to match.

Also bump the top-level `updatedAt`. The app re-downloads only that course's
bank. If a download fails, the old cached questions stay available and the
update is retried on the next sync.

## Remove a course

Delete its entry from `courses.json` and bump `updatedAt`. Its cached questions
and local progress remain on the device, but the course no longer appears.

## What still needs a normal app release

- Shipping this loader to existing users for the first time.
- Any future Dart/UI changes, dependency changes, or app version bumps.
- A Play Store upload of a new binary (the existing signed CI workflow handles
  the signing; you do not need the secrets locally).

For local testing without release keys, a debug build is enough:

```bash
flutter build apk --debug
```

To test content from a branch or another host before merging to `master`, point
the app at a different catalog URL at build time:

```bash
flutter run \
  --dart-define=COURSE_CATALOG_URL=https://raw.githubusercontent.com/Cyberboyone/fulafiacbt/<commit-sha>/assets/questions/courses.json
```

The override URL should serve `courses.json` and the question files from the
same folder. A commit SHA is unambiguous; for a branch whose name contains
slashes, GitHub also accepts the `refs/heads/...` form, for example:

```text
https://raw.githubusercontent.com/Cyberboyone/fulafiacbt/refs/heads/arena/7f8fda9b-fulafiacbt/assets/questions/courses.json
```

## Security and store-policy notes

- This channel downloads **JSON data only**, never Dart/code or executable
  assets. Keep it that way for Play Store compliance.
- Question filenames are restricted to safe basenames and resolved only against
  the catalog URL's own host. Catalog schema, course IDs, options, and answer
  indexes are validated before caching.
- Requests contain only the public file URL; no profile, progress, scores, or
  tokens are sent. The privacy policy lists GitHub as the public content host.
- If this repository ever becomes private, the default raw URL will stop
  working for users. Move the catalog and question files to another public
  HTTPS host (or a public Firebase/Cloud Storage bucket) and override
  `COURSE_CATALOG_URL`; still no app secrets are required for public read-only
  content.
