"""Step 2 — deterministic structural parse of raw.txt -> questions.raw.json.

Strips boilerplate (URLs, footers, page numbers, TOC), then walks the text
line-by-line. Tracks the current category via a known list of section
headers, and splits each category's body on `^N.` markers (numbering
resets per category, just like the PDF).

The output is intentionally "raw": question/answer text still contains
PDF wrapping artifacts. A separate LLM-cleanup pass tightens that up.
"""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "raw.txt"
OUT = ROOT / "data" / "questions.json"

# Order matters — these define the canonical category sequence.
# Each tuple is (display name, group, difficulty).
CATEGORIES: list[tuple[str, str, str | None]] = [
    ("Analytical / Attention to Detail", "Fit", None),
    ("Background / Personal", "Fit", None),
    ('"Career Changer"', "Fit", None),
    ("Commitment", "Fit", None),
    ("Culture", "Fit", None),
    ('"Future"', "Fit", None),
    ("Strengths / Weaknesses", "Fit", None),
    ("Team / Leadership", "Fit", None),
    ("Understanding Banking", "Fit", None),
    ('"Warren Buffett"', "Fit", None),
    ('"Why Banking?"', "Fit", None),
    ('"Failure"', "Fit", None),
    ('"Outside the Box"', "Fit", None),
    ("Discussing Transaction Experience", "Deals", None),
    ("Restructuring / Distressed M&A", "Restructuring", None),
    ("Accounting", "Technical", "Basic"),
    ("Accounting", "Technical", "Advanced"),
    ("Enterprise / Equity Value", "Technical", "Basic"),
    ("Enterprise / Equity Value", "Technical", "Advanced"),
    ("Valuation", "Technical", "Basic"),
    ("Valuation", "Technical", "Advanced"),
    ("Discounted Cash Flow", "Technical", "Basic"),
    ("Discounted Cash Flow", "Technical", "Advanced"),
    ("Merger Model", "Technical", "Basic"),
    ("Merger Model", "Technical", "Advanced"),
    ("LBO Model", "Technical", "Basic"),
    ("LBO Model", "Technical", "Advanced"),
    ("Brain Teaser", "Technical", None),
]

# Build the regexes used to locate category headers in body text. Each
# header line in the PDF body looks like one of:
#   "Analytical / Attention to Detail Questions & Suggested Answers"
#   "Restructuring / Distressed M&A Questions & Answers"
#   "Accounting Questions & Answers – Basic"   (– is en-dash; pdftotext sometimes mangles it)
# The dash between topic and difficulty can be `-`, `–`, or even garbled to `�`.
DASH = r"[-–—�]"


def header_regex(name: str, difficulty: str | None) -> re.Pattern[str]:
    # "Questions" is optional: most headers read "<name> Questions & Answers",
    # but "Understanding Banking & Suggested Answers" omits the word "Questions".
    base = re.escape(name) + r"\s+(?:Questions\s+)?&\s*(?:Suggested\s+)?Answers"
    if difficulty:
        base += rf"\s*{DASH}\s*" + re.escape(difficulty)
    # Discussing Transaction Experience has no "Questions & Answers" suffix.
    if name == "Discussing Transaction Experience":
        base = re.escape(name)
    return re.compile(r"^\s*" + base + r"\s*$", re.IGNORECASE)


HEADERS = [
    (name, group, diff, header_regex(name, diff))
    for (name, group, diff) in CATEGORIES
]

# Lines we always drop.
DROP_PATTERNS = [
    re.compile(r"breakingintowallstreet\.com", re.IGNORECASE),
    re.compile(r"mergersandinquisitions\.com", re.IGNORECASE),
    # A bare page-number line (just digits, maybe surrounded by whitespace).
    re.compile(r"^\s*\d{1,3}\s*$"),
]

# Capture leading indentation: real top-level questions sit at column 0,
# whereas numbered sub-lists inside an answer are indented several spaces.
QUESTION_RE = re.compile(r"^(\s*)(\d{1,3})\.\s+(.*)$")

# Minimum answer length (chars) for a numbered marker to count as a real
# question rather than a sub-list / preamble item. Calibrated against the
# shortest genuine answers in the guide.
MIN_ANSWER_CHARS = 60


def ends_question(s: str) -> bool:
    # A question line may end with a quote/paren after the '?', e.g. too high?"
    return s.rstrip("\"'”’) ").endswith("?")

# pdftotext mangles the en-dash and bullet glyphs to U+FFFD. Map them back.
REPLACEMENT = "�"


def clean_chars(text: str) -> str:
    # Leading bullet glyph on a line -> markdown bullet handled in reflow;
    # here we just normalize the glyph itself to a real bullet marker.
    text = re.sub(r"(?m)^(\s*)" + REPLACEMENT + r"\s+", r"\1• ", text)
    # En-dash used as inline separator: " <fffd> " -> " – ".
    text = text.replace(" " + REPLACEMENT + " ", " – ")
    # Any stragglers -> en-dash.
    text = text.replace(REPLACEMENT, "–")
    return text


def reflow(text: str) -> str:
    """Join PDF hard-wrapped lines back into paragraphs and bullets.

    The PDF wraps prose at a fixed width with hard newlines. We rebuild
    logical blocks: a blank line ends a block; a line beginning with a
    bullet glyph starts a new bullet (whose wrapped continuation lines are
    folded in); everything else folds into the current paragraph.
    """
    lines = [ln.rstrip() for ln in text.split("\n")]
    blocks: list[tuple[bool, str]] = []  # (is_bullet, text)
    buf: list[str] = []
    buf_is_bullet = False

    def flush():
        nonlocal buf, buf_is_bullet
        if buf:
            blocks.append((buf_is_bullet, " ".join(buf).strip()))
        buf = []
        buf_is_bullet = False

    for ln in lines:
        s = ln.strip()
        if s == "":
            flush()
            continue
        if s.startswith(("•", "•")):
            flush()
            buf = [s.lstrip("•• ").strip()]
            buf_is_bullet = True
        else:
            buf.append(s)
    flush()

    rendered = []
    for is_bullet, txt in blocks:
        if not txt:
            continue
        rendered.append(f"- {txt}" if is_bullet else txt)
    return "\n\n".join(rendered)


@dataclass
class Question:
    id: str
    n: int
    category: str
    group: str
    difficulty: str | None
    question: str
    answer: str
    source_line: int


@dataclass
class CategorySection:
    name: str
    group: str
    difficulty: str | None
    start_line: int  # 1-indexed line in raw.txt where header sits
    questions: list[Question] = field(default_factory=list)


def is_drop(line: str) -> bool:
    return any(p.search(line) for p in DROP_PATTERNS)


def find_category_at(line: str) -> tuple[str, str, str | None] | None:
    for name, group, diff, regex in HEADERS:
        if regex.match(line):
            return (name, group, diff)
    return None


def slug(name: str, diff: str | None) -> str:
    s = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    if diff:
        s += f"-{diff.lower()}"
    return s


def _split_into_sections(
    lines: list[str], first_body_idx: int
) -> list[tuple[tuple[str, str, str | None], int, list[tuple[int, str]]]]:
    """Group surviving (non-boilerplate) lines under their category header.

    Returns a list of (category_tuple, header_line_no, body_lines) where
    body_lines is a list of (1-indexed original line number, text).
    """
    sections: list[
        tuple[tuple[str, str, str | None], int, list[tuple[int, str]]]
    ] = []
    cur_meta: tuple[str, str, str | None] | None = None
    cur_header_line = 0
    cur_lines: list[tuple[int, str]] = []

    for i in range(first_body_idx, len(lines)):
        raw_line = lines[i]
        if is_drop(raw_line):
            continue
        cat = find_category_at(raw_line)
        if cat:
            if cur_meta is not None:
                sections.append((cur_meta, cur_header_line, cur_lines))
            cur_meta = cat
            cur_header_line = i + 1
            cur_lines = []
            continue
        if cur_meta is None:
            continue
        cur_lines.append((i + 1, raw_line))
    if cur_meta is not None:
        sections.append((cur_meta, cur_header_line, cur_lines))
    return sections


def _build_question(
    meta: tuple[str, str, str | None],
    n: int,
    block: list[tuple[int, str]],
    start_line: int,
) -> Question:
    name, group, diff = meta
    texts = [t for _, t in block]
    # Boundary: question text ends at the earlier of the first line ending in
    # '?' or the first blank line; the rest is the answer.
    question_parts: list[str] = []
    ans_start = len(texts)
    for idx, ln in enumerate(texts):
        s = ln.strip()
        if idx > 0 and s == "":
            ans_start = idx + 1
            break
        question_parts.append(s)
        if ends_question(s):
            ans_start = idx + 1
            break
    question_text = clean_chars(re.sub(r"\s+", " ", " ".join(question_parts)).strip())
    answer_text = reflow(clean_chars("\n".join(texts[ans_start:])))
    return Question(
        id=f"{slug(name, diff)}-{n:03d}",
        n=n,
        category=name,
        group=group,
        difficulty=diff,
        question=question_text,
        answer=answer_text,
        source_line=start_line,
    )


def parse() -> list[CategorySection]:
    # NOTE: split on "\n" only. str.splitlines() also breaks on form-feed
    # (\f) page-break markers (164 of them here), which desynchronizes line
    # counts and corrupts analysis. Convert \f to \n so page breaks become
    # ordinary blank lines and counting matches the source file.
    raw = RAW.read_text(encoding="utf-8", errors="replace").replace("\f", "\n")
    lines = raw.split("\n")

    # Find where real content starts: the first body-side category header.
    # Everything before (cover, TOC, intro) is dropped wholesale.
    first_body_idx = next(
        (i for i, line in enumerate(lines) if find_category_at(line)), None
    )
    if first_body_idx is None:
        raise RuntimeError("No category headers matched anywhere in raw.txt")

    out: list[CategorySection] = []
    for meta, header_line, body in _split_into_sections(lines, first_body_idx):
        name, group, diff = meta
        section = CategorySection(
            name=name, group=group, difficulty=diff, start_line=header_line
        )
        # All numbered markers in this section, in order.
        markers: list[tuple[int, int, int, int]] = []  # (body_index, n, indent, line)
        for bi, (orig_line, text) in enumerate(body):
            m = QUESTION_RE.match(text)
            if m:
                markers.append((bi, int(m.group(2)), len(m.group(1)), orig_line))

        # Reconstruct the 1..N question sequence. Indentation is unreliable in
        # ABSOLUTE terms (per-page margin drift), so we never compare to a
        # fixed column. Instead a marker is a real question iff its number is
        # the next expected value AND it passes at least one substance signal:
        #   - it reads as a question (contains '?'), which also rescues
        #     questions whose answer is itself a numbered list; or
        #   - it sits no deeper than the previously accepted question and is
        #     followed by a substantial answer span (a wrapped sub-list item
        #     is indented deeper AND yields only a tiny fragment).
        # Numbered sub-lists and section preambles restart at "1", are indented
        # relative to the surrounding question, and pack tightly with no answer
        # between items, so they fail without advancing the expected counter.
        accepted: list[tuple[int, int, int]] = []  # (body_index, n, orig_line)
        expected = 1
        prev_indent: int | None = None
        for pos, (bi, n, indent, orig_line) in enumerate(markers):
            if n != expected:
                continue
            marker_text = QUESTION_RE.match(body[bi][1])
            has_q = "?" in (marker_text.group(3) if marker_text else "")
            next_bi = len(body)
            for q in range(pos + 1, len(markers)):
                if markers[q][1] == expected + 1:
                    next_bi = markers[q][0]
                    break
            substance = sum(
                len(body[k][1].strip()) for k in range(bi + 1, next_bi)
            )
            not_deeper = prev_indent is None or indent <= prev_indent + 2
            if has_q or (not_deeper and substance >= MIN_ANSWER_CHARS):
                accepted.append((bi, n, orig_line))
                expected += 1
                prev_indent = indent

        # Slice the body into per-question blocks between accepted markers.
        for j, (bi, n, orig_line) in enumerate(accepted):
            end = accepted[j + 1][0] if j + 1 < len(accepted) else len(body)
            block = body[bi:end]
            # Strip the leading "N." from the first line of the block.
            first_line = block[0][1]
            m = QUESTION_RE.match(first_line)
            block = [(block[0][0], m.group(3) if m else first_line)] + block[1:]
            section.questions.append(_build_question(meta, n, block, orig_line))

        out.append(section)
    return out


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sections = parse()
    payload = {
        "categories": [
            {
                "name": s.name,
                "group": s.group,
                "difficulty": s.difficulty,
                "slug": slug(s.name, s.difficulty),
                "count": len(s.questions),
                "questions": [asdict(q) for q in s.questions],
            }
            for s in sections
        ]
    }
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    total = sum(len(s.questions) for s in sections)
    print(f"Parsed {total} questions across {len(sections)} sections -> {OUT}")
    for s in sections:
        tag = f" [{s.difficulty}]" if s.difficulty else ""
        print(f"  {s.name}{tag}: {len(s.questions)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
