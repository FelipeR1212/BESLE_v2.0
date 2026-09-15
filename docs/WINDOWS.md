# Windows support (development branch)

This branch adds a native 64-bit Windows build without changing the mathematical
model, input data format, output VTK format, or the existing Linux Makefile.

## Current status

The code is compiled with GNU Fortran in the MSYS2 UCRT64 environment and uses
Microsoft MPI plus the MSYS2 parallel MUMPS package. GitHub Actions builds and
runs the same one-step reference case on Ubuntu and Windows, then compares every
numeric token in the generated VTK files.

This is development documentation. The Windows Installer workflow now produces
an unsigned setup executable and validates its complete install/run/uninstall
cycle. It remains a development artifact until physical Windows acceptance is
recorded.

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

The executable must be launched with its working directory set to the simulation
project, because its input configuration uses relative paths. Parameters are now
read from the external `BESLE.nml` file; see the
[runtime configuration guide](RUNTIME_CONFIGURATION.md).

## Validation-only step limit

`BESLE_MAX_STEPS=1` shortens the published 200-step reference problem for CI.
When the variable is absent, BESLE uses `time_steps` from `BESLE.nml`. If that
file is also absent, it falls back to the historical compiled value.

## Installer behavior

The unsigned installer is built automatically after the native build succeeds.
It installs BESLE under Program Files and creates an optional desktop shortcut.
If Microsoft MPI is missing, the verified Microsoft redistributable is installed
silently.

The launcher deliberately offers only two choices: an optional one-step test to
verify the installation, or creating a simulation folder without running any
calculation. In both cases BESLE creates a separate project under
`Documents\BESLE\2.1.0\runs`, including its editable `BESLE.nml` and the
`run-this-simulation.cmd` execution helper. The create-only choice does not
start MPI and does not generate a log, used-configuration copy, or VTK result.
Editing `BESLE.nml` directly and launching
`run-this-simulation.cmd` runs that project without recompilation. Previous
results are archived under `history`, and uninstalling BESLE does not remove
these user projects.

The same project also contains runtime-editable auxiliary configurations:

- `Material\Material.nml` with `run-material.cmd`;
- `Mesh\General\General.nml` with `run-general.cmd`;
- `Mesh\Polycrystal\Polycrystal.nml` with `run-polycrystal.cmd`.

In each pair, the `.nml` file is the editable configuration and the `.cmd`
file only launches the installed generator. The installer includes the four
required native auxiliary executables and their Voro++ and Triangle runtime
components. Auxiliary outputs, logs, used-configuration copies, and archived
results remain inside the user project and survive uninstall. See the
[runtime configuration guide](RUNTIME_CONFIGURATION.md) for the parameter
scope and limitations.

Because the installer is intentionally unsigned, Windows SmartScreen may display
a warning. The release will include a SHA-256 file so users can verify the exact
download before running it.
