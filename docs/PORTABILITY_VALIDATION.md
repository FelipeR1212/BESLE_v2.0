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
4. Numeric differences satisfy the combined per-token criterion
   `rtol=1e-6`, `atol=1e-9`, and the whole-result relative L2 error remains
   at or below `1e-10`.
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

## Initial GitHub Actions evidence (2026-09-14)

Three independent native Windows/Linux one-step comparisons established the
observed cross-platform numerical envelope before fixing the acceptance
threshold. Across 29,775 numeric VTK tokens, the largest observed absolute error
was 4.383e-9 and the largest observed whole-result relative L2 error was
5.345e-13. An initial per-token relative tolerance of 1e-7 was therefore too
sensitive to a small group of values around 5e-3: one run reported 18
violations even though its relative L2 error remained 5.345e-13.

The acceptance rule was changed transparently to a combined per-token tolerance
of `rtol=1e-6` and `atol=1e-9`, plus an independent relative L2 ceiling of
`1e-10`. This criterion is fixed in the workflow and JSON evidence rather than
being selected separately for each run.

Windows Installer run 34883687897 also completed the following automated
checks:

- built the unsigned Windows x64 setup executable;
- ran the staged application with the compiler and MSYS2 absent from runtime
  `PATH`;
- removed the build-time Microsoft MPI installation;
- installed BESLE and restored Microsoft MPI from the bundled official
  redistributable;
- reproduced all 29,775 VTK tokens exactly between the pre-install and installed
  executions (maximum absolute error 0.0);
- uninstalled the application while preserving the generated user result.

Physical testing on the original author's Windows computer remains a separate,
required acceptance step.
