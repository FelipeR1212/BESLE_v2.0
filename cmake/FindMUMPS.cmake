include(FindPackageHandleStandardArgs)

find_package(PkgConfig QUIET)

if(PkgConfig_FOUND)
    if(WIN32)
        pkg_check_modules(PC_MUMPS QUIET IMPORTED_TARGET mumps-dmo)
    else()
        pkg_check_modules(PC_MUMPS QUIET IMPORTED_TARGET dmumps)
    endif()
endif()

if(TARGET PkgConfig::PC_MUMPS)
    add_library(MUMPS::DMUMPS ALIAS PkgConfig::PC_MUMPS)
    set(MUMPS_INCLUDE_DIRS "${PC_MUMPS_INCLUDE_DIRS}")
    set(MUMPS_FOUND TRUE)
    return()
endif()

find_path(MUMPS_INCLUDE_DIR
    NAMES dmumps_struc.h
    PATH_SUFFIXES mumps
)

find_library(MUMPS_DMUMPS_LIBRARY
    NAMES dmumps mumps-dmo
)

find_library(MUMPS_COMMON_LIBRARY
    NAMES mumps_common
)

find_library(MUMPS_PORD_LIBRARY
    NAMES pord
)

find_library(MUMPS_SCALAPACK_LIBRARY
    NAMES scalapack-openmpi scalapack-mpich scalapack
)

if(WIN32)
    find_package_handle_standard_args(MUMPS
        REQUIRED_VARS MUMPS_INCLUDE_DIR MUMPS_DMUMPS_LIBRARY
    )
else()
    find_package_handle_standard_args(MUMPS
        REQUIRED_VARS
            MUMPS_INCLUDE_DIR
            MUMPS_DMUMPS_LIBRARY
            MUMPS_COMMON_LIBRARY
    )
endif()

if(MUMPS_FOUND AND NOT TARGET MUMPS::DMUMPS)
    set(_MUMPS_LINK_LIBRARIES "${MUMPS_DMUMPS_LIBRARY}")

    foreach(_optional_library
        MUMPS_COMMON_LIBRARY
        MUMPS_PORD_LIBRARY
        MUMPS_SCALAPACK_LIBRARY
    )
        if(${_optional_library})
            list(APPEND _MUMPS_LINK_LIBRARIES "${${_optional_library}}")
        endif()
    endforeach()

    add_library(MUMPS::DMUMPS INTERFACE IMPORTED)
    set_target_properties(MUMPS::DMUMPS PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${MUMPS_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "${_MUMPS_LINK_LIBRARIES}"
    )
endif()

set(MUMPS_INCLUDE_DIRS "${MUMPS_INCLUDE_DIR}")
mark_as_advanced(
    MUMPS_INCLUDE_DIR
    MUMPS_DMUMPS_LIBRARY
    MUMPS_COMMON_LIBRARY
    MUMPS_PORD_LIBRARY
    MUMPS_SCALAPACK_LIBRARY
)
