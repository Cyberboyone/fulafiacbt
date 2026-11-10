#!/usr/bin/env python3
"""Validate the Fulafia CBT course catalog and every bundled question bank.

Run from the repository root:

    python3 scripts/validate_courses.py

The same rules are enforced at runtime by CourseCatalogService in Dart.
"""

from __future__ import annotations

import json
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets/questions/courses.json"
QUESTIONS_DIR = ROOT / "assets/questions"
PUBSPEC = ROOT / "pubspec.yaml"

ID_RE = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
FILE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*\.json$")
COLOR_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")
MAX_QUESTIONS = 2000

errors: list[str] = []
warnings: list[str] = []


def error(message: str) -> None:
    errors.append(message)


def warn(message: str) -> None:
    warnings.append(message)


def load_json(path: Path):
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        error(f"Missing file: {path.relative_to(ROOT)}")
    except json.JSONDecodeError as exc:
        error(f"Invalid JSON in {path.relative_to(ROOT)}: {exc}")
    return None


def is_nonempty_str(value) -> bool:
    return isinstance(value, str) and value.strip() != ""


def as_int(value):
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return None


def validate_question_bank(path: Path, course: dict) -> int:
    data = load_json(path)
    if data is None:
        return 0

    rel = path.relative_to(ROOT)
    if not isinstance(data, dict):
        error(f"{rel}: top level must be a JSON object")
        return 0

    course_id = data.get("course_id")
    if course_id is not None and course_id != course.get("id"):
        error(f"{rel}: course_id '{course_id}' does not match catalog id '{course.get('id')}'")

    file_version = data.get("version")
    catalog_version = course.get("version")
    if file_version is None:
        warn(f"{rel}: missing 'version'; add it so the app can detect updates")
    elif file_version != catalog_version:
        error(
            f"{rel}: version '{file_version}' does not match catalog version "
            f"'{catalog_version}'"
        )

    questions = data.get("questions")
    if not isinstance(questions, list) or not questions:
        error(f"{rel}: 'questions' must be a non-empty list")
        return 0
    if len(questions) > MAX_QUESTIONS:
        error(f"{rel}: too many questions ({len(questions)} > {MAX_QUESTIONS})")

    seen_ids: set[str] = set()
    for index, question in enumerate(questions, start=1):
        label = f"{rel} question #{index}"
        if not isinstance(question, dict):
            error(f"{label}: must be a JSON object")
            continue

        text = question.get("text", question.get("question"))
        if not is_nonempty_str(text):
            error(f"{label}: needs a non-empty 'text' (or legacy 'question')")

        options = question.get("options")
        if not isinstance(options, list) or not (2 <= len(options) <= 6):
            error(f"{label}: 'options' must contain 2 to 6 strings")
            options = []
        else:
            for option in options:
                if not is_nonempty_str(option):
                    error(f"{label}: option values must be non-empty strings")

        correct_index = as_int(
            question.get("correct_index", question.get("correctIndex"))
        )
        if correct_index is None or correct_index < 0 or correct_index >= len(options):
            error(f"{label}: 'correct_index' must be a valid 0-based option index")

        question_id = question.get("id")
        if not is_nonempty_str(question_id):
            warn(f"{label}: missing 'id'")
        elif question_id in seen_ids:
            warn(f"{label}: duplicate id '{question_id}'")
        else:
            seen_ids.add(question_id)

        if "explanation" in question and not isinstance(question["explanation"], str):
            warn(f"{label}: 'explanation' should be a string")

        difficulty = as_int(question.get("difficulty", 1))
        if difficulty is None or not (1 <= difficulty <= 5):
            warn(f"{label}: 'difficulty' should be an integer from 1 to 5")

    return len(questions)


def validate_catalog() -> tuple[int, int]:
    catalog = load_json(CATALOG)
    if catalog is None:
        return 0, 0

    if not isinstance(catalog, dict):
        error("assets/questions/courses.json: top level must be a JSON object")
        return 0, 0

    if catalog.get("schemaVersion") != 1:
        error("assets/questions/courses.json: schemaVersion must be 1")

    updated_at = catalog.get("updatedAt")
    if not is_nonempty_str(updated_at):
        error("assets/questions/courses.json: updatedAt must be an ISO-8601 string")
    else:
        try:
            datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
        except ValueError:
            error("assets/questions/courses.json: updatedAt must be a valid ISO-8601 timestamp")

    courses = catalog.get("courses")
    if not isinstance(courses, list) or not courses:
        error("assets/questions/courses.json: 'courses' must be a non-empty list")
        return 0, 0

    ids: set[str] = set()
    total_questions = 0

    for index, course in enumerate(courses):
        label = f"courses[{index}]"
        if not isinstance(course, dict):
            error(f"{label}: must be a JSON object")
            continue

        for key in ("id", "code", "name", "icon", "colorHex", "mode", "file", "version"):
            if not is_nonempty_str(course.get(key)):
                error(f"{label}.{key}: must be a non-empty string")

        course_id = course.get("id")
        if isinstance(course_id, str):
            if not ID_RE.match(course_id):
                error(f"{label}.id: use lowercase letters, digits, _ or - only")
            if course_id in ids:
                error(f"{label}.id: duplicate id '{course_id}'")
            else:
                ids.add(course_id)

        file_name = course.get("file")
        if isinstance(file_name, str) and not FILE_RE.match(file_name):
            error(
                f"{label}.file: must be a safe .json filename in the same folder "
                f"(letters, digits, _, -, .)"
            )

        color = course.get("colorHex")
        if isinstance(color, str) and not COLOR_RE.match(color):
            error(f"{label}.colorHex: must be a 6-digit hex colour such as #DFF5E4")

        if isinstance(file_name, str) and FILE_RE.match(file_name):
            total_questions += validate_question_bank(QUESTIONS_DIR / file_name, course)

    if PUBSPEC.exists():
        pubspec = PUBSPEC.read_text(encoding="utf-8")
        if "- assets/questions/" not in pubspec:
            error("pubspec.yaml must declare '- assets/questions/' so courses.json is bundled")
    else:
        error("pubspec.yaml is missing")

    return len(courses), total_questions


def main() -> int:
    course_count, question_count = validate_catalog()

    for message in warnings:
        print(f"WARNING: {message}")
    for message in errors:
        print(f"ERROR: {message}")

    if errors:
        print(f"\nFAILED: {len(errors)} error(s), {len(warnings)} warning(s).")
        return 1

    print(
        f"OK: {course_count} courses, {question_count} bundled questions, "
        f"{len(warnings)} warning(s)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
