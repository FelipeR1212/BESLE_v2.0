# Portability validation plan

## Scope

The Windows work is intentionally limited to portability, packaging,
reproducible installation, and validation. It does not claim a new boundary
element formulation or a change to BESLE's physical models.

The BESLE v2 New Version Announcement describes a simpler Ubuntu installation
procedure and reports no changes to the program core, input/output, or
functionality. Native Windows execution, a precompiled installer, dependency
staging, and cross-platform numerical equivalence are therefore evaluated here
as a separate software-engineering contribution.

## Acceptance criteria

1. The unchanged reference configuration compiles natively on Ubuntu and
   Windows from the same Fortran sources.
2. Both systems complete a two-rank, one-step MPI run.
3. Both systems produce the same set of VTK files and numeric token counts.
4. Numeric differences remain within `rtol=1e-7` and `atol=1e-9`.
5. The final Windows installer is tested on a clean Windows runner without
   MSYS2 or the compiler on the runtime `PATH`.
6. A physical Windows computer is used for final author acceptance.

## Existing local evidence

Before uploading this branch, a Linux legacy-build/reference run and the
portable CMake build completed all 200 steps. The comparison covered 200 VTK
files and 5,955,191 numeric tokens. The largest absolute difference was
4.547e-13 and the largest relative difference was 1.797e-12, passing the stated
tolerances.

This result is supporting development evidence. GitHub Actions artifacts and
the physical-machine acceptance record will provide the reproducible evidence
used for release and publication.
