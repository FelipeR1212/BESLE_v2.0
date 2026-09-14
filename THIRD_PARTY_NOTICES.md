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

The Microsoft MPI installer is downloaded from Microsoft and its SHA-256 digest
is verified before packaging. When the installed Microsoft MPI distribution
exposes separate license files, the workflow also copies them into
`third-party-licenses/Microsoft-MPI`. These notices do not replace the full
license texts supplied with the respective components.
