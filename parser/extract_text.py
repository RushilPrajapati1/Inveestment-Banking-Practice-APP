"""Step 1 — convert PDF -> plain text with layout preserved.

Run once. Idempotent: skips work if raw.txt already exists.
Requires pdftotext on PATH (ships with Git for Windows / poppler).
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PDF = ROOT / "400-IB-Questions-Interview-Guide.pdf"
OUT = ROOT / "raw.txt"


def main() -> int:
    if not PDF.exists():
        print(f"PDF not found: {PDF}", file=sys.stderr)
        return 1
    if OUT.exists():
        print(f"raw.txt already exists ({OUT.stat().st_size} bytes) — skipping")
        return 0
    if shutil.which("pdftotext") is None:
        print("pdftotext not found on PATH", file=sys.stderr)
        return 1
    subprocess.run(["pdftotext", "-layout", str(PDF), str(OUT)], check=True)
    print(f"Wrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
