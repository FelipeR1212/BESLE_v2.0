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


def location(relative: str, index: int, left: float, right: float, error: float) -> dict[str, object]:
    return {
        "file": relative,
        "token": index,
        "reference": left,
        "candidate": right,
        "absolute_error": error,
    }


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
    structural_errors: list[str] = []
    examples: list[dict[str, object]] = []

    report: dict[str, object] = {
        "reference_root": str(args.reference),
        "candidate_root": str(args.candidate),
        "tolerance": {
            "formula": "abs(candidate-reference) <= atol + rtol*abs(reference)",
            "rtol": args.rtol,
            "atol": args.atol,
        },
        "files": len(reference_files),
        "tokens": 0,
        "violations": 0,
        "max_absolute_error": None,
        "max_relative_error": None,
        "relative_l2_error": None,
        "violation_examples": examples,
        "structural_errors": structural_errors,
    }

    if not reference_files:
        structural_errors.append("The reference tree contains no .vtk files.")

    missing = sorted(set(reference_files) - set(candidate_files))
    extra = sorted(set(candidate_files) - set(reference_files))
    if missing:
        structural_errors.append("Missing candidate files: " + ", ".join(missing))
    if extra:
        structural_errors.append("Unexpected candidate files: " + ", ".join(extra))

    squared_error = 0.0
    squared_reference = 0.0
    max_absolute = -1.0
    max_relative = -1.0

    for relative in sorted(set(reference_files) & set(candidate_files)):
        expected = numbers(reference_files[relative])
        actual = numbers(candidate_files[relative])
        if len(expected) != len(actual):
            structural_errors.append(
                f"{relative}: numeric token count differs "
                f"({len(expected)} != {len(actual)})"
            )
            continue

        report["tokens"] = int(report["tokens"]) + len(expected)
        for index, (left, right) in enumerate(zip(expected, actual)):
            if not (math.isfinite(left) and math.isfinite(right)):
                if left != right:
                    structural_errors.append(
                        f"{relative}: non-finite value differs at token {index}"
                    )
                continue

            absolute = abs(left - right)
            relative_error = absolute / max(abs(left), args.atol)
            squared_error += absolute * absolute
            squared_reference += left * left

            if absolute > max_absolute:
                max_absolute = absolute
                report["max_absolute_error"] = location(
                    relative, index, left, right, absolute
                )
            if relative_error > max_relative:
                max_relative = relative_error
                relative_location = location(relative, index, left, right, absolute)
                relative_location["relative_error"] = relative_error
                report["max_relative_error"] = relative_location

            if absolute > args.atol + args.rtol * abs(left):
                report["violations"] = int(report["violations"]) + 1
                if len(examples) < 20:
                    item = location(relative, index, left, right, absolute)
                    item["allowed_error"] = args.atol + args.rtol * abs(left)
                    examples.append(item)

    if squared_reference > 0.0:
        report["relative_l2_error"] = math.sqrt(squared_error / squared_reference)
    elif squared_error == 0.0:
        report["relative_l2_error"] = 0.0

    failed = bool(structural_errors) or int(report["violations"]) > 0
    report["status"] = "failed" if failed else "passed"

    output = json.dumps(report, indent=2, sort_keys=True)
    print(output)
    if args.report:
        args.report.write_text(output + "\n", encoding="utf-8")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
