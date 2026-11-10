#!/usr/bin/env python3
"""Rebuild the 12 placeholder question banks from bundled course material.

This complements scripts/generate_phy104.py. It replaces the generic
"Concept A/B/C/D" banks for these catalog IDs with 200 unique,
source-grounded multiple-choice questions each:

    chem111, mth111, bio102, bly121, bly122, chm102, chm121, chm122,
    gst113_2, mth121, phy102, phy121

Questions are generated from text-bearing PDFs, DOCX and PPTX files already
in the repository. Image-only PDFs are skipped; no OCR is performed. Each
cloze item blanks a course-specific term in a sentence from the notes and
uses other course terms as distractors. Existing real questions from
gen_questions.py (CHM 111) and assets/questions/mth111.p1.json (MTH 111)
are reused as seeds.

The catalog versions and updatedAt are bumped so installed apps re-download
only the changed banks through the existing public JSON mechanism.

Run from the repository root:

    python3 -m pip install pypdf
    python3 scripts/generate_remaining_banks.py
    python3 scripts/validate_courses.py

No signing, keystore, GitHub Actions secret, or release configuration is
involved.
"""

from __future__ import annotations

import json
import logging
import random
import re
import runpy
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:  # pragma: no cover - compatibility fallback
    try:
        from PyPDF2 import PdfReader
    except ImportError as exc:  # pragma: no cover
        raise SystemExit(
            "pypdf is required: python3 -m pip install pypdf"
        ) from exc

logging.getLogger("pypdf").setLevel(logging.ERROR)

ROOT = Path(__file__).resolve().parents[1]
QUESTIONS_DIR = ROOT / "assets/questions"
CATALOG = QUESTIONS_DIR / "courses.json"
VERSION = "2.0.0"
UPDATED_AT = "2026-11-06T10:00:00Z"
TARGET_COUNT = 200

IDS = [
    "chem111",
    "mth111",
    "bio102",
    "bly121",
    "bly122",
    "chm102",
    "chm121",
    "chm122",
    "gst113_2",
    "mth121",
    "phy102",
    "phy121",
]

# Courses with the fewest independent source sentences are generated first so
# that overlapping source folders do not starve them during global dedupe.
ORDER = [
    "mth121",
    "chm122",
    "chem111",
    "mth111",
    "chm121",
    "gst113_2",
    "phy121",
    "phy102",
    "bio102",
    "bly121",
    "bly122",
    "chm102",
]

SOURCE_NOTE = (
    "Source-grounded practice MCQs generated from text-bearing PDFs, DOCX and "
    "PPTX course files bundled in the repository. Image-only PDFs were skipped "
    "and no OCR was performed. Existing real questions were reused where "
    "available. Question-level topic tags are metadata; the current quiz UI "
    "does not filter by them yet."
)


def terms(value: str) -> list[str]:
    return [part.strip() for part in value.split("|") if part.strip()]


RAW_TERMS = {
    "chem111": """matter|atom|molecule|mole|molar mass|Avogadro|stoichiometry|limiting reagent|percent yield|ideal gas|Boyle|Charles|Gay-Lussac|Dalton|partial pressure|kinetic molecular theory|real gas|van der Waals|enthalpy|entropy|Gibbs free energy|exothermic|endothermic|thermochemistry|calorimeter|heat capacity|Hess|internal energy|chemical equilibrium|Le Chatelier|equilibrium constant|acid|base|pH|pKa|buffer|titration|indicator|reaction rate|rate law|reaction order|half-life|activation energy|catalyst|collision theory|Arrhenius|oxidation|reduction|electrode|galvanic cell|electrolysis|solution|concentration|solubility|precipitate|atomic theory|periodic table|bond energy|ideal solution""",
    "mth111": """set|subset|union|intersection|complement|Venn diagram|relation|function|domain|range|mapping|equivalence|matrix|determinant|inverse|transpose|vector|scalar|dot product|cross product|complex number|real part|imaginary part|modulus|argument|De Moivre|polynomial|quadratic equation|root|discriminant|binomial theorem|sequence|series|arithmetic progression|geometric progression|limit|continuity|derivative|differentiation|integral|logarithm|exponential|trigonometry|sine|cosine|tangent|radian|inequality|permutation|combination|probability|Cartesian product|power set|binary operation|empty set|universal set""",
    "bio102": """ecology|ecosystem|habitat|niche|population|community|biosphere|biome|adaptation|evolution|natural selection|speciation|genetics|gene|allele|chromosome|DNA|RNA|mitosis|meiosis|reproduction|gamete|fertilization|photosynthesis|respiration|enzyme|metabolism|homeostasis|taxonomy|kingdom|phylum|class|order|family|genus|species|virus|bacteria|fungi|algae|plant|animal|food chain|food web|energy flow|nutrient cycle|symbiosis|parasitism|mutualism|commensalism|predation|competition|biodiversity|conservation|carrying capacity|ecological succession|density dependence|abiotic|biotic|producer|consumer|decomposer|trophic level|carbon cycle|nitrogen cycle|water cycle|pollution|climate""",
    "bly121": """cryptogam|thallophyte|bryophyte|pteridophyte|spermatophyte|algae|fungi|lichen|moss|fern|gymnosperm|angiosperm|root|stem|leaf|flower|seed|fruit|hydrophyte|xerophyte|halophyte|epiphyte|sciophyte|heliophyte|aerenchyma|cuticle|stomata|adaptation|ecology|ecosystem|habitat|population|community|animal kingdom|taxonomy|symmetry|asymmetry|radial|bilateral|germ layer|ectoderm|endoderm|mesoderm|diploblast|triploblast|coelom|invertebrate|vertebrate|classification|phylogeny|nomenclature|binomial|lower plant|vascular tissue|spore|gametophyte|sporophyte|alternation of generations|pollination|photosynthesis""",
    "bly122": """animal|body plan|symmetry|asymmetry|radial|bilateral|germ layer|ectoderm|endoderm|mesoderm|diploblast|triploblast|coelom|pseudocoelom|acoelomate|invertebrate|vertebrate|phylum|porifera|cnidaria|platyhelminthes|nematoda|annelida|arthropoda|mollusca|echinodermata|chordata|adaptation|ecology|habitat|niche|population|community|taxonomy|classification|phylogeny|binomial|specimen|microscope|dissection|practical|morphology|anatomy|physiology|reproduction|embryogenesis|segmentation|appendage|exoskeleton|endoskeleton|notochord|vertebral column|sponge|sea anemone""",
    "chm102": """organic chemistry|carbon|hydrocarbon|alkane|alkene|alkyne|aromatic|benzene|fullerene|nanotube|allotrope|isomer|functional group|homologous series|alcohol|ether|aldehyde|ketone|carboxylic acid|ester|amine|amide|alkyl halide|polymer|monomer|addition|substitution|elimination|oxidation|reduction|hybridization|sigma bond|pi bond|covalent bond|electronegativity|IUPAC|nomenclature|saturated|unsaturated|resonance|aromaticity|electrophile|nucleophile|carbocation|free radical|stereochemistry|chirality|enantiomer|cracking|petroleum|natural product|nanochemistry|molecular formula|structural formula|empirical formula|combustion|Lavoisier|Wohler|vital force""",
    "chm121": """atomic structure|quantum number|orbital|electron configuration|periodic table|periodicity|chemical bond|ionic bond|covalent bond|metallic bond|Lewis structure|VSEPR|molecular geometry|hybridization|intermolecular force|hydrogen bond|dipole moment|electronegativity|ionization energy|electron affinity|oxidation state|redox|stoichiometry|mole|concentration|acid|base|pH|buffer|titration|thermodynamics|kinetics|equilibrium|catalyst|reaction mechanism|coordination compound|ligand|complex ion|crystal field|transition metal|oxidation number|s-block|p-block|d-block|periodic law|valence electron|shielding|effective nuclear charge|Pauli|Hund|Aufbau|octet rule|Bohr""",
    "chm122": """functional group|homologous series|isomerism|alcohol|phenol|ether|aldehyde|ketone|carboxylic acid|ester|amine|amide|nitrile|halide|aromatic compound|benzene|electrophilic substitution|nucleophilic substitution|addition|elimination|oxidation|reduction|polymer|condensation|hydrolysis|saponification|esterification|Grignard reagent|carbohydrate|lipid|protein|amino acid|nucleic acid|spectroscopy|infrared|NMR|mass spectrometry|chromatography|stereochemistry|chirality|optical activity|enantiomer|diastereomer|racemic mixture|carbocation|carbanion|free radical|resonance|aromaticity|IUPAC|alkane|alkene|alkyne|carbonyl|carboxyl|hydroxyl|amino|alkyl|aryl""",
    "gst113_2": """trade|barter|specialization|communication|market|money|agriculture|industrialization|self-reliance|colonialism|amalgamation|Lord Lugard|ethnic group|nationality|culture|language|religion|custom|myth of origin|diversity|unity|marginalization|exclusion|unemployment|poverty|security|banditry|insurgency|democracy|federalism|constitution|nationalism|precolonial|postcolonial|economy|development|education|health|gender|youth|migration|urbanization|conflict|peacebuilding|governance|corruption|leadership|citizenship|human rights|sustainable development|entrepreneurship|technology|globalization|tourism|cultural heritage|festival|marriage|family|kinship|chieftaincy|traditional ruler|local government|state|region|geopolitics|census|population|Nigeria""",
    "mth121": """limit|continuity|derivative|differentiation|chain rule|product rule|quotient rule|implicit differentiation|higher derivative|maxima|minima|inflection|curve sketching|integral|indefinite integral|definite integral|substitution|integration by parts|partial fractions|area under curve|volume of solid|differential equation|separable equation|sequence|series|convergence|divergence|Taylor series|Maclaurin series|power series|function|domain|range|asymptote|logarithm|exponential|trigonometric function|inverse function|matrix|determinant|vector|complex number|polar coordinates|parametric equation|gradient|partial derivative|multiple integral|mean value theorem|Rolle|L'Hopital|Riemann sum|fundamental theorem of calculus|critical point|turning point""",
    "phy102": """electric circuit|current|voltage|resistance|Ohm|Kirchhoff|charge|capacitor|capacitance|inductor|inductance|DC circuit|AC circuit|resistor|series circuit|parallel circuit|power|energy|electromotive force|internal resistance|Wheatstone bridge|potentiometer|ammeter|voltmeter|galvanometer|magnetic field|magnetic flux|Faraday|Lenz|electromagnetic induction|transformer|motor|generator|Lorentz force|Biot-Savart|Ampere|solenoid|torque|magnetic dipole|Maxwell|electromagnetic wave|semiconductor|diode|transistor|rectifier|amplifier|logic gate|digital circuit|photon|photoelectric effect|atomic model|radioactivity|nuclear reaction|half-life|quantum|wave-particle duality|uncertainty principle|relativity""",
    "phy121": """Coulomb|electric field|electric potential|potential difference|equipotential|Gauss|flux|dipole|polarization|dielectric|capacitor|capacitance|current density|drift velocity|resistivity|conductivity|electromotive force|Kirchhoff|RC circuit|magnetic force|magnetic field|magnetic flux|Faraday|Lenz|inductance|mutual induction|self induction|AC|RMS|impedance|reactance|resonance|transformer|electromagnetic wave|Poynting|reflection|refraction|interference|diffraction|polarization|photoelectric effect|Compton|Bohr|quantum number|wave function|uncertainty principle|radioactivity|alpha decay|beta decay|gamma decay|half-life|nuclear fission|nuclear fusion|binding energy|semiconductor|PN junction|diode|transistor|logic gate|operational amplifier|relativity|Lorentz transformation|time dilation|length contraction""",
}

TOPICS = {
    "chem111": [
        "Matter & Stoichiometry",
        "Gas Laws & Kinetic Theory",
        "Thermochemistry",
        "Chemical Equilibrium",
        "Acids, Bases & Solutions",
        "Kinetics & Electrochemistry",
    ],
    "mth111": [
        "Sets & Logic",
        "Relations & Functions",
        "Matrices & Vectors",
        "Complex Numbers",
        "Polynomials & Sequences",
        "Trigonometry & Calculus Basics",
    ],
    "bio102": [
        "Ecology & Ecosystems",
        "Population & Community",
        "Energy Flow & Nutrient Cycles",
        "Genetics & Evolution",
        "Taxonomy & Diversity",
        "Adaptation & Conservation",
    ],
    "bly121": [
        "Lower Plants",
        "Plant Adaptations",
        "Plant Structure & Reproduction",
        "Animal Classification",
        "Body Plans & Germ Layers",
        "Ecology & Diversity",
    ],
    "bly122": [
        "Animal Body Plans",
        "Invertebrate Phyla",
        "Vertebrate Diversity",
        "Taxonomy & Nomenclature",
        "Morphology & Practical",
        "Ecology & Adaptation",
    ],
    "chm102": [
        "Organic Chemistry Basics",
        "Hydrocarbons",
        "Functional Groups",
        "Isomerism & Nomenclature",
        "Reaction Types",
        "Carbon Nanostructures",
    ],
    "chm121": [
        "Atomic Structure & Periodicity",
        "Chemical Bonding",
        "Molecular Geometry",
        "Acids, Bases & Redox",
        "Coordination Chemistry",
        "Thermodynamics & Kinetics",
    ],
    "chm122": [
        "Functional Groups",
        "Aliphatic Compounds",
        "Aromatic Compounds",
        "Reaction Mechanisms",
        "Stereochemistry",
        "Biomolecules & Analysis",
    ],
    "gst113_2": [
        "Trade & Self-Reliance",
        "Nigerian Peoples & Culture",
        "Colonialism & Nationalism",
        "Governance & Development",
        "Social Issues",
        "Cultural Heritage",
    ],
    "mth121": [
        "Limits & Continuity",
        "Differentiation",
        "Applications of Derivatives",
        "Integration",
        "Sequences & Series",
        "Differential Equations",
    ],
    "phy102": [
        "DC Circuits",
        "Circuit Components & Measurements",
        "Electromagnetism",
        "AC & Transformers",
        "Semiconductors",
        "Modern Physics",
    ],
    "phy121": [
        "Electrostatics",
        "Electric Circuits",
        "Magnetism & Induction",
        "Electromagnetic Waves & Optics",
        "Atomic & Nuclear Physics",
        "Semiconductors & Relativity",
    ],
}

FOLDERS = {
    "chem111": ["100level/first semester/chem111"],
    "mth111": ["100level/first semester/mth111"],
    "bio102": [
        "100level/second semester/bio102",
        "100level/first semester/bly111",
        "100level/second semester/bly121",
    ],
    "bly121": ["100level/second semester/bly121"],
    "bly122": [
        "100level/second semester/bly122",
        "100level/second semester/bly121",
    ],
    "chm102": [
        "100level/second semester/chm102",
        "100level/second semester/chm122",
        "100level/second semester/chm121",
    ],
    "chm121": ["100level/second semester/chm121"],
    "chm122": [
        "100level/second semester/chm122",
        "100level/second semester/chm121",
        "100level/second semester/chm102",
    ],
    "gst113_2": [
        "100level/second semester/gst113",
        "100level/first semester/gst113",
    ],
    "mth121": [
        "100level/second semester/mth121",
        "100level/first semester/mth111",
    ],
    "phy102": [
        "100level/second semester/phy102",
        "100level/second semester/phy121",
    ],
    "phy121": ["100level/second semester/phy121"],
}

NAMES = {
    "chem111": "Introductory Physical Chemistry",
    "mth111": "General Mathematics I",
    "bio102": "General Biology II (Ecology)",
    "bly121": "General Biology II (Diversity)",
    "bly122": "General Biology II (Survey & Practical)",
    "chm102": "General Chemistry II",
    "chm121": "Introductory Inorganic Chemistry",
    "chm122": "Introductory Organic Chemistry",
    "gst113_2": "Nigeria People and Culture II",
    "mth121": "General Mathematics II",
    "phy102": "Electricity & Magnetism",
    "phy121": "Electricity, Magnetism & Modern Physics",
}

COURSES = {
    cid: {
        "id": cid,
        "name": NAMES[cid],
        "topics": TOPICS[cid],
        "folders": FOLDERS[cid],
        "terms": terms(RAW_TERMS[cid]),
        "seed": sum(map(ord, cid)),
    }
    for cid in IDS
}

ALL_TERMS = sorted({term for course in COURSES.values() for term in course["terms"]})

# Words that are too ambiguous to make a good cloze answer on their own.
BAD_CORRECT = {
    "state", "power", "energy", "class", "order", "family", "area", "volume",
    "mass", "time", "work", "heat", "light", "sound", "wave", "cell", "gene",
    "organ", "tissue", "species", "animal", "plant", "market", "money",
    "trade", "culture", "language", "religion", "population", "community",
    "education", "health", "gender", "youth", "region", "matter", "atom",
    "molecule", "acid", "base", "solution", "current", "charge", "set",
    "root", "series", "function", "domain", "range",
}

GENERIC = {
    "pH", "AC", "DC", "RMS", "IUPAC", "VSEPR", "DNA", "RNA", "NMR",
}


def sanitize(value: str) -> str:
    value = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def read_pdf(path: Path) -> str:
    try:
        reader = PdfReader(str(path))
        return "\n".join((page.extract_text() or "") for page in reader.pages)
    except Exception:
        return ""


def read_docx(path: Path) -> str:
    try:
        with zipfile.ZipFile(path) as archive:
            root = ET.fromstring(archive.read("word/document.xml"))
        ns = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
        return "\n".join(
            "".join(node.text or "" for node in paragraph.iter(ns + "t"))
            for paragraph in root.iter(ns + "p")
        )
    except Exception:
        return ""


def read_pptx(path: Path) -> str:
    try:
        with zipfile.ZipFile(path) as archive:
            names = sorted(
                (
                    name
                    for name in archive.namelist()
                    if re.match(r"ppt/slides/slide\d+\.xml$", name)
                ),
                key=lambda name: int(re.search(r"slide(\d+)", name).group(1)),
            )
            parts = []
            ns = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
            for name in names:
                root = ET.fromstring(archive.read(name))
                parts.append(
                    "\n".join(node.text or "" for node in root.iter(ns + "t"))
                )
        return "\n".join(parts)
    except Exception:
        return ""


TEXT_CACHE: dict[Path, str] = {}


def read_any(path: Path) -> str:
    if path in TEXT_CACHE:
        return TEXT_CACHE[path]
    suffix = path.suffix.lower()
    if suffix == ".pdf" or (suffix == "" and path.read_bytes()[:4] == b"%PDF"):
        text = read_pdf(path)
    elif suffix == ".docx":
        text = read_docx(path)
    elif suffix == ".pptx":
        text = read_pptx(path)
    else:
        text = ""
    TEXT_CACHE[path] = text
    return text


def collect_sources(folders: list[str]) -> list[tuple[str, str]]:
    sources: list[tuple[str, str]] = []
    for folder in folders:
        base = ROOT / folder
        if not base.exists():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            suffix = path.suffix.lower()
            if suffix not in (".pdf", ".docx", ".pptx"):
                if not (suffix == "" and path.read_bytes()[:4] == b"%PDF"):
                    continue
            text = read_any(path)
            if len(text) < 100:
                continue
            sources.append((path.relative_to(ROOT).as_posix(), text))
    return sources


def sentences(text: str):
    cleaned = sanitize(text)
    cleaned = re.sub(r"([A-Za-z])- ([A-Za-z])", r"\1\2", cleaned)
    seen: set[str] = set()
    for sentence in re.split(r"(?<=[.!?])\s+", cleaned):
        sentence = " ".join(sentence.split())
        if not sentence or sentence in seen:
            continue
        seen.add(sentence)
        yield sentence


def term_pattern(term: str) -> str:
    return r"(?i)(?<!\w)" + re.escape(term) + r"(?!\w)"


def candidate_tiers(course: dict):
    strict_terms = [
        term
        for term in course["terms"]
        if len(term) >= 4
        and term.lower() not in GENERIC
        and term.lower() not in BAD_CORRECT
    ]
    loose_terms = [
        term
        for term in course["terms"]
        if len(term) >= 4 and term.lower() not in BAD_CORRECT
    ]
    strict_terms.sort(key=len, reverse=True)
    loose_terms.sort(key=len, reverse=True)

    tiers: list[list[tuple[str, str, str, str]]] = [[] for _ in range(4)]
    sources = collect_sources(course["folders"])

    for source, text in sources:
        for sentence in sentences(text):
            length = len(sentence)
            if not (30 <= length <= 350):
                continue
            if not re.search(r"[A-Za-z]{4}", sentence):
                continue
            if re.search(r"http|www|@|©|Page \d|______|____", sentence):
                continue
            if re.search(r"\b(ans|answer|solution|correct option)\b", sentence, re.I):
                continue

            # Prefer a specific course term; fall back to a looser term only if
            # no strict term appears in this sentence.
            term = None
            matches: list[re.Match] = []
            for candidate_term in strict_terms:
                found = list(re.finditer(term_pattern(candidate_term), sentence))
                if found:
                    term = candidate_term
                    matches = found
                    break
            if term is None:
                for candidate_term in loose_terms:
                    found = list(re.finditer(term_pattern(candidate_term), sentence))
                    if found:
                        term = candidate_term
                        matches = found
                        break
            if term is None:
                continue

            blanked = (
                sentence[: matches[0].start()]
                + "______"
                + sentence[matches[0].end() :]
            )
            stem = (
                "Which term correctly completes this statement from the "
                f'course notes? "{blanked}"'
            )
            record = (stem, term, sentence, source)

            if (
                60 <= length <= 220
                and len(matches) == 1
                and not re.search(r"\d{4,}", sentence)
            ):
                tiers[0].append(record)
            elif 50 <= length <= 260 and len(matches) <= 2:
                tiers[1].append(record)
            elif 40 <= length <= 300:
                tiers[2].append(record)
            else:
                tiers[3].append(record)

    return tiers, [source for source, _ in sources]


def normalize_seed_question(raw: dict, course: dict, index: int):
    text = sanitize(raw.get("text") or raw.get("question") or "")
    if not text:
        return None
    options = [
        sanitize(re.sub(r"^[A-D]\)\s*", "", str(option)))
        for option in raw.get("options", [])
    ]
    joined = " ".join(options).lower()
    if "all of the above" in joined or "none of the above" in joined:
        return None
    if len(options) < 2 or len(set(options)) != len(options):
        return None
    correct_index = raw.get("correct_index")
    if not isinstance(correct_index, int) or not (0 <= correct_index < len(options)):
        return None
    explanation = sanitize(raw.get("explanation") or "")
    if not explanation:
        return None
    difficulty = raw.get("difficulty", 2)
    if not isinstance(difficulty, int) or not (1 <= difficulty <= 5):
        difficulty = 2
    return {
        "text": text,
        "options": options,
        "correct_index": correct_index,
        "explanation": explanation,
        "difficulty": difficulty,
        "topic": course["topics"][index % len(course["topics"])],
    }


def seed_questions(course: dict) -> list[dict]:
    cid = course["id"]
    raw_items: list[dict] = []

    if cid == "chem111":
        namespace = runpy.run_path(str(ROOT / "gen_questions.py"))
        raw_items = namespace.get("questions", [])
    elif cid == "mth111":
        data = json.loads(
            (QUESTIONS_DIR / "mth111.p1.json").read_text(encoding="utf-8")
        )
        raw_items = data.get("questions", [])

    result = []
    for index, raw in enumerate(raw_items):
        item = normalize_seed_question(raw, course, index)
        if item is not None:
            result.append(item)
    return result


def similar(a: str, b: str) -> bool:
    a = a.casefold()
    b = b.casefold()
    return a in b or b in a


def choose_distractors(correct: str, course: dict, rng: random.Random):
    pool = [
        term
        for term in course["terms"]
        if term.casefold() != correct.casefold()
        and not similar(term, correct)
        and 3 <= len(term) <= 45
    ]
    rng.shuffle(pool)
    chosen: list[str] = []
    seen = {correct.casefold()}

    for term in pool:
        key = term.casefold()
        if key in seen or any(similar(term, existing) for existing in chosen):
            continue
        chosen.append(term)
        seen.add(key)
        if len(chosen) == 3:
            break

    if len(chosen) < 3:
        fallback = [
            term
            for term in ALL_TERMS
            if term.casefold() != correct.casefold()
            and not similar(term, correct)
            and 3 <= len(term) <= 45
        ]
        rng.shuffle(fallback)
        for term in fallback:
            key = term.casefold()
            if key in seen or any(similar(term, existing) for existing in chosen):
                continue
            chosen.append(term)
            seen.add(key)
            if len(chosen) == 3:
                break

    if len(chosen) != 3:
        raise RuntimeError(f"Could not build distractors for {correct}")
    return chosen


def build_options(correct: str, course: dict, rng: random.Random):
    distractors = choose_distractors(correct, course, rng)
    options = [correct, *distractors]
    if len({option.casefold() for option in options}) != len(options):
        raise RuntimeError(f"Duplicate options for {correct}")
    rng.shuffle(options)
    return options, options.index(correct)


def topic_for(course: dict, term: str, fallback_index: int) -> str:
    try:
        position = course["terms"].index(term)
    except ValueError:
        position = fallback_index
    return course["topics"][position % len(course["topics"])]


def cloze_question(record, course: dict, rng: random.Random, index: int):
    stem, term, sentence, source = record
    options, correct_index = build_options(term, course, rng)
    length = len(sentence)
    difficulty = 1 if length < 120 else 2 if length < 220 else 3
    explanation = (
        f"From {Path(source).name}: {sentence} The missing term is '{term}'."
    )
    explanation = sanitize(explanation)
    if len(explanation) > 600:
        explanation = explanation[:597] + "..."
    return {
        "text": stem,
        "options": options,
        "correct_index": correct_index,
        "explanation": explanation,
        "difficulty": difficulty,
        "topic": topic_for(course, term, index),
    }


def validate_bank(bank: dict, cid: str):
    questions = bank["questions"]
    if bank["version"] != VERSION:
        raise RuntimeError(f"{cid}: bad bank version")
    if bank["course_id"] != cid or bank["course_name"] != NAMES[cid]:
        raise RuntimeError(f"{cid}: bad identity")
    if len(questions) != TARGET_COUNT:
        raise RuntimeError(f"{cid}: expected 200 questions, got {len(questions)}")
    if len({q["text"] for q in questions}) != TARGET_COUNT:
        raise RuntimeError(f"{cid}: duplicate stems")
    if len({q["id"] for q in questions}) != TARGET_COUNT:
        raise RuntimeError(f"{cid}: duplicate ids")

    for question in questions:
        options = question["options"]
        if not (2 <= len(options) <= 6):
            raise RuntimeError(f"{cid}: bad option count")
        if len(set(options)) != len(options):
            raise RuntimeError(f"{cid}: duplicate options")
        if not (0 <= question["correct_index"] < len(options)):
            raise RuntimeError(f"{cid}: bad correct_index")
        if not question["explanation"].strip():
            raise RuntimeError(f"{cid}: empty explanation")
        if not (1 <= question["difficulty"] <= 5):
            raise RuntimeError(f"{cid}: bad difficulty")
        if question["topic"] not in bank["topics"]:
            raise RuntimeError(f"{cid}: unknown topic")
        lowered = " ".join([question["text"], *options]).lower()
        if re.search(r"\bconcept [a-d]\b", lowered):
            raise RuntimeError(f"{cid}: placeholder wording")
        if "all of the above" in lowered or "none of the above" in lowered:
            raise RuntimeError(f"{cid}: forbidden meta-option")


def update_catalog():
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    catalog["updatedAt"] = UPDATED_AT
    for entry in catalog["courses"]:
        if entry["id"] in IDS:
            entry["version"] = VERSION
    CATALOG.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main():
    used_stems: set[str] = set()
    generated: dict[str, dict] = {}

    for cid in ORDER:
        course = COURSES[cid]
        seeds = seed_questions(course)
        for question in seeds:
            used_stems.add(question["text"])

        tiers, sources = candidate_tiers(course)
        rng = random.Random(course["seed"])
        selected = []

        for tier in tiers:
            rng.shuffle(tier)
            for record in tier:
                stem = record[0]
                if stem in used_stems or any(item[0] == stem for item in selected):
                    continue
                used_stems.add(stem)
                selected.append(record)
                if len(seeds) + len(selected) >= TARGET_COUNT:
                    break
            if len(seeds) + len(selected) >= TARGET_COUNT:
                break

        if len(seeds) + len(selected) != TARGET_COUNT:
            raise RuntimeError(
                f"{cid}: only {len(seeds) + len(selected)} questions available"
            )

        questions = list(seeds)
        for offset, record in enumerate(selected):
            questions.append(cloze_question(record, course, rng, len(seeds) + offset))

        for index, question in enumerate(questions, start=1):
            question["id"] = f"{cid}_{index:03d}"

        bank = {
            "course_id": cid,
            "course_name": course["name"],
            "version": VERSION,
            "sources": sources,
            "source_note": SOURCE_NOTE,
            "topics": course["topics"],
            "questions": questions,
        }
        validate_bank(bank, cid)
        generated[cid] = bank

        path = QUESTIONS_DIR / f"{cid}.json"
        path.write_text(
            json.dumps(bank, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(
            f"Wrote {path.relative_to(ROOT).as_posix()}: "
            f"{len(questions)} questions ({len(seeds)} seeded, "
            f"{len(selected)} source-grounded), {len(sources)} source file(s)"
        )

    update_catalog()
    print(f"Updated {CATALOG.relative_to(ROOT).as_posix()}: updatedAt={UPDATED_AT}, 12 bank versions={VERSION}")
    print(f"Globally unique cloze stems: {len(used_stems) - sum(len(seed_questions(COURSES[c])) for c in IDS)}")


if __name__ == "__main__":
    main()
