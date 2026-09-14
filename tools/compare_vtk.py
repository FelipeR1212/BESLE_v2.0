#!/usr/bin/env python3
"""Compare numeric content from two BESLE VTK result trees."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path

NUMBER = re.compile(
    r"(?<![A-Za-z0-9_.])"
    r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[EeDd][+-]?\d+)?"
    r"(?![A-Za-z0-9_.])"
)


def vtk_files(root: Path) -> dict[str, Path]:
    return {
        path.relative_to(root).as_posix(): path
        for path in sorted(root.rglob("*.vtk"))
    }


def numbers(path: Path) -> list[float]:
    text = path.read_text(encoding="utf-8", errors="strict")
    return [float(token.replace("D", "E").replace("d", "e")) for token in NUMBER.findall(text)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("reference", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--rtol", type=float, default=1.0e-7)
    parser.add_argument("--atol", type=float, default=1.0e-9)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    reference_files = vtk_files(args.reference)
    candidate_files = vtk_files(args.candidate)

    report: dict[str, object] = {
        "reference_root": str(args.reference),
        "candidate_root": str(args.candidate),
        "rtol": args.rtol,
        "atol": args.atol,
        "files": len(reference_files),
        "tokens": 0,
        "max_absolute_error": 0.0,
        "max_relative_error": 0.0,
        "errors": [],
    }
    errors: list[str] = report["errors"]  # type: ignore[assignment]

    if not reference_files:
        errors.append("The reference tree contains no .vtk files.")

    missing = sorted(set(reference_files) - set(candidate_files))
    extra = sorted(set(candidate_files) - set(reference_files))
    if missing:
        errors.append("Missing candidate files: " + ", ".join(missing))
    if extra:
        errors.append("Unexpected candidate files: " + ", ".join(extra))

    for relative in sorted(set(reference_files) & set(candidate_files)):
        expected = numbers(reference_files[relative])
        actual = numbers(candidate_files[relative])
        if len(expected) != len(actual):
            errors.append(
                f"{relative}: numeric token count differs "
                f"({len(expected)} != {len(actual)})"
            )
            continue

        report["tokens"] = int(report["tokens"]) + len(expected)
        for index, (left, right) in enumerate(zip(expected, actual)):
            if not (math.isfinite(left) and math.isfinite(right)):
                if left != right:
                    errors.append(f"{relative}: non-finite value differs at token {index}")
                    break
                continue

            absolute = abs(left - right)
            relative_error = absolute / max(abs(left), args.atol)
            report["max_absolute_error"] = max(float(report["max_absolute_error"]), absolute)
            report["max_relative_error"] = max(float(report["max_relative_error"]), relative_error)

            if absolute > args.atol + args.rtol * abs(left):
                errors.append(
                    f"{relative}: tolerance exceeded at token {index}: "
                    f"reference={left:.17g}, candidate={right:.17g}, "
                    f"abs={absolute:.3e}"
                )
                break

    output = json.dumps(report, indent=2, sort_keys=True)
    print(output)
    if args.report:
        args.report.write_text(output + "\n", encoding="utf-8")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
