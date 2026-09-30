# BESLE 2.1.0 Release Candidate 1

This pre-release is intended for evaluation of the native Windows port of
BESLE. It is built from and tagged at validated commit
`4a173202c747c853ab83e3cdc8994d68e85e8268`.

## Download and installation

1. Download `BESLE-2.1.0-Windows-x64-Setup.exe`.
2. Optionally download the `.sha256` file and verify the installer checksum.
3. Run the installer on a 64-bit Windows system.
4. If Microsoft Defender SmartScreen appears, select **More info** and then
   **Run anyway**. This release candidate is not digitally signed.
5. Administrator permission and an Internet connection may be required if
   Microsoft MPI is not already installed.

User simulations are stored under `Documents\BESLE\2.1.0\runs` and are not
removed when BESLE is uninstalled or updated.

## Evaluation workflow

- Option 1 performs the optional one-step installation verification.
- Option 2 creates a new simulation folder without running the configured case.
- Edit `BESLE.nml` inside a simulation folder and run
  `run-this-simulation.cmd` to calculate with the saved configuration.
- Previous outputs are preserved under the simulation's `history` folder.
- Open `.vtk` result files with ParaView.

## Included improvements

- Native Windows x64 installer and launcher.
- Runtime simulation configuration through `BESLE.nml`, without recompiling.
- Configurable MPI process count through `mpi_processes`.
- Runtime-configurable Material, General Mesh, and Polycrystal auxiliary tools.
- English-only installer and runtime interface.
- Automatic preservation of previous simulation results.
- Updated contributor banner, including Rahim Si Hadj Mohand and
  Andres F. Ramirez Correa.

## Validation status

- Linux and native Windows builds completed successfully.
- The installed Windows executable reproduced all 29,775 reference VTK values
  exactly in the packaged one-step comparison.
- Runtime configuration changes were applied without rebuilding the executable.
- Two and four MPI processes were validated. Larger counts remain dependent on
  the problem size and available system memory; the eight-process diagnostic
  reached the documented MUMPS memory limit in the test environment.
- Installation, simulation-folder creation, auxiliary tools, reruns, history,
  and uninstall data preservation were exercised automatically.

Validation evidence:

- [Portability CI](https://github.com/FelipeR1212/BESLE_v2.0/actions/runs/35413119756)
- [Windows Installer](https://github.com/FelipeR1212/BESLE_v2.0/actions/runs/35413119800)

## Release-candidate notice

This is a public test build, not the final BESLE 2.1.0 release. Please report
the Windows version, processor count, selected `mpi_processes` value, the
simulation folder's `BESLE.log`, and the steps needed to reproduce any issue.
