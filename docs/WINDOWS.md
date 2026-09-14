# Windows support (development branch)

This branch adds a native 64-bit Windows build without changing the mathematical
model, input data format, output VTK format, or the existing Linux Makefile.

## Current status

The code is compiled with GNU Fortran in the MSYS2 UCRT64 environment and uses
Microsoft MPI plus the MSYS2 parallel MUMPS package. GitHub Actions builds and
runs the same one-step reference case on Ubuntu and Windows, then compares every
numeric token in the generated VTK files.

This is development documentation. A user-facing installer will be generated
only after the native Windows equivalence job passes.

## Developer build

Required Windows build components:

- MSYS2 UCRT64
- GNU Fortran
- CMake and Ninja
- Microsoft MPI runtime and SDK bindings
- parallel MUMPS package

From an MSYS2 UCRT64 terminal:

    pacman -S --needed \
      mingw-w64-ucrt-x86_64-cmake \
      mingw-w64-ucrt-x86_64-gcc-fortran \
      mingw-w64-ucrt-x86_64-msmpi \
      mingw-w64-ucrt-x86_64-mumps \
      mingw-w64-ucrt-x86_64-ninja \
      mingw-w64-ucrt-x86_64-pkgconf

    cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_Fortran_COMPILER=/ucrt64/bin/mpifort.exe \
      -DCMAKE_PREFIX_PATH=/ucrt64

    cmake --build build

The executable must currently be launched with its working directory set to
`BESLE_ROOT`, because the published input configuration uses relative paths.

## Validation-only step limit

`BESLE_MAX_STEPS=1` shortens the published 200-step reference problem for CI.
When the variable is absent, BESLE uses the value compiled in
`Set_parameters.f90`, exactly as before.
