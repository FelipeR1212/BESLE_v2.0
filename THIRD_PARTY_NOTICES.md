# Third-party notices

BESLE itself is distributed under the GNU General Public License v3.0; see
`LICENSE`.

The Windows package contains unmodified runtime components required to execute
the compiled scientific code. The build workflow generates
`third-party-licenses/MSYS2-RUNTIME-PACKAGES.tsv` with the exact DLL, package,
and version mapping. License files shipped by those packages are copied into
`third-party-licenses/msys2`.

The principal components include:

- MUMPS, distributed under CECILL-C.
- ScaLAPACK and OpenBLAS, under their respective BSD-style licenses.
- GNU Fortran runtime libraries, distributed under the GCC runtime terms and
  applicable runtime-library exception.
- Microsoft MPI Runtime, bundled as Microsoft's unmodified standalone
  redistributable installer.
- Voro++, used by the polycrystalline-structure generator and distributed
  under its three-clause redistribution terms. Its complete `LICENSE` file is
  installed under `third-party-licenses/Voro++`.
- Triangle 1.6 by Jonathan Richard Shewchuk, used as a callable library by the
  polycrystalline-mesh generator. Triangle permits private, research, and
  institutional use and redistribution without compensation under the
  conditions stated in its notice; commercial-system distribution requires a
  direct arrangement with its author. The complete upstream `README` notice is
  installed under `third-party-licenses/Triangle`. For native 64-bit Windows,
  the public CMake build makes mechanical prototype and pointer-width
  substitutions (`uintptr_t`) required by the LLP64 data model; it does not
  alter Triangle's meshing algorithm.

The Microsoft MPI installer is downloaded from Microsoft and its SHA-256 digest
is verified before packaging. When the installed Microsoft MPI distribution
exposes separate license files, the workflow also copies them into
`third-party-licenses/Microsoft-MPI`. These notices do not replace the full
license texts supplied with the respective components.
