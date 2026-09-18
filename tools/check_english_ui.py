#!/usr/bin/env python3
"""Check the English-only BESLE UI and its contributor banner."""

import argparse
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
CONTRIBUTOR = "Andres Felipe Ramirez Correa"
SPANS = (
    "By Andres F. Galvis",
    "Contributions: Daniel M. Prada",
    "Lucas S. Moura",
    CONTRIBUTOR,
    "Coordinator: Paulo Sollero",
    "University of Campinas",
)
SPANISH = re.compile(
    r"\b(?:configuraci[oó]n|ejecuci[oó]n|simulaci[oó]n|carpeta|archivo|proyecto|"
    r"presione|seleccione|selecci[oó]n|procesos|instalando|ejecutar|resultados|"
    r"par[aá]metros|par[aá]metro|mayor|menor|vac[ií]o|termin[oó]|cargada|prueba|"
    r"desconocido|asignaci[oó]n)\b|\b(?:no se|no puede|debe ser)\b",
    re.IGNORECASE,
)


def check():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", type=Path, help="Also check a compiled BESLE run's banner.")
    args = parser.parse_args()
    files = [
        ROOT / "packaging/windows/BESLE.iss",
        ROOT / "packaging/windows/run-besle.cmd",
        ROOT / "packaging/windows/run-besle.ps1.in",
        ROOT / "packaging/windows/run-besle-auxiliary.ps1.in",
        ROOT / "BESLE_ROOT/BESLE.nml",
        ROOT / "BESLE_ROOT/Material/Material.nml",
        ROOT / "BESLE_ROOT/Mesh/General/General.nml",
        ROOT / "BESLE_ROOT/Mesh/Polycrystal/Polycrystal.nml",
    ]
    for directory in (
        "BESLE_ROOT/src", "BESLE_ROOT/Material/src",
        "BESLE_ROOT/Mesh/General/src", "BESLE_ROOT/Mesh/Polycrystal/src",
    ):
        files.extend(path for path in (ROOT / directory).rglob("*")
                     if path.suffix.lower() in {".f90", ".cc", ".hh", ".c", ".h"})
    errors = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), 1):
            if SPANISH.search(line):
                errors.append(f"{path.relative_to(ROOT)}:{number}: untranslated text: {line.strip()}")
        if re.search(r"(?im)^\s*pause\s*$", text):
            errors.append(f"{path.relative_to(ROOT)}: a localized Windows pause prompt is not suppressed")

    installer = (ROOT / "packaging/windows/BESLE.iss").read_text(encoding="utf-8")
    languages = re.search(r"(?ms)^\[Languages\]\s*\n(.*?)(?=^\[|\Z)", installer)
    names = re.findall(r'(?im)^Name:\s*"([^"]+)"', languages.group(1) if languages else "")
    if names != ["english"]:
        errors.append(f"The installer must bundle English only, not {names}.")
    for flag in ("ShowLanguageDialog", "UsePreviousLanguage"):
        if not re.search(rf"(?im)^{flag}=no\s*$", installer):
            errors.append(f"The installer must set {flag}=no.")

    banner = (ROOT / "BESLE_ROOT/src/Input.f90").read_text(encoding="utf-8")
    for span in SPANS:
        if span not in banner:
            errors.append(f"Missing original credit or contributor in the banner: {span}")
    if banner.count(CONTRIBUTOR) != 1:
        errors.append("The new contributor must appear exactly once in the source banner.")

    if args.log:
        raw = args.log.read_bytes()
        log = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8")
        for span in (*SPANS, "Active MPI processes:", "BESLE configuration loaded from:"):
            if span not in log:
                errors.append(f"Missing English message or credit in compiled run log: {span}")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"English-only UI and contributor audit passed ({len(files)} source files).")
    if args.log:
        print(f"Compiled English banner verified: {args.log}")


if __name__ == "__main__":
    check()
