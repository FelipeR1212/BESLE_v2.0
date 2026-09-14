#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 STAGE_DIRECTORY" >&2
    exit 2
fi

stage_dir="$1"
if [[ ! -d "$stage_dir" ]]; then
    echo "Stage directory does not exist: $stage_dir" >&2
    exit 2
fi

license_root="$stage_dir/third-party-licenses/msys2"
manifest="$stage_dir/third-party-licenses/MSYS2-RUNTIME-PACKAGES.tsv"
mkdir -p "$license_root"

mapfile -t staged_dlls < <(find "$stage_dir" -maxdepth 1 -type f -iname "*.dll" -print | sort)
if [[ ${#staged_dlls[@]} -eq 0 ]]; then
    echo "No staged MSYS2 DLLs were found." >&2
    exit 1
fi

printf "dll\tpackage\tversion\n" > "$manifest"

for staged_dll in "${staged_dlls[@]}"; do
    dll_name="$(basename "$staged_dll")"
    source_dll="/ucrt64/bin/$dll_name"

    if [[ ! -f "$source_dll" ]]; then
        echo "Cannot locate the source package for $dll_name." >&2
        exit 1
    fi

    owner="$(pacman -Qoq "$source_dll")"
    version="$(pacman -Q "$owner" | awk '{print $2}')"
    printf "%s\t%s\t%s\n" "$dll_name" "$owner" "$version" >> "$manifest"

    while IFS= read -r license_path; do
        [[ -f "$license_path" ]] || continue
        relative="${license_path#/ucrt64/share/licenses/}"
        destination="$license_root/$relative"
        mkdir -p "$(dirname "$destination")"
        cp -f "$license_path" "$destination"
    done < <(
        pacman -Ql "$owner" |
            cut -d " " -f 2- |
            grep '^/ucrt64/share/licenses/' || true
    )
done

msmpi_license="/c/Program Files/Microsoft MPI/License"
if [[ -d "$msmpi_license" ]]; then
    mkdir -p "$stage_dir/third-party-licenses/Microsoft-MPI"
    cp -R "$msmpi_license"/. "$stage_dir/third-party-licenses/Microsoft-MPI/"
else
    printf "\nMicrosoft MPI license files are supplied by the official redistributable installer.\n" \
        > "$stage_dir/third-party-licenses/Microsoft-MPI-LICENSE-NOTE.txt"
fi

sort -u "$manifest" -o "$manifest"
echo "Staged runtime license information in $stage_dir/third-party-licenses"
