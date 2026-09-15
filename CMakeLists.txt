cmake_minimum_required(VERSION 3.20)

project(BESLE VERSION 2.1.0 LANGUAGES C CXX Fortran)

include(CTest)
include(FetchContent)
include(GNUInstallDirs)

if(POLICY CMP0169)
    cmake_policy(SET CMP0169 OLD)
endif()

option(BESLE_BUILD_MAIN "Build the main MPI BESLE solver" ON)
option(BESLE_BUILD_AUXILIARIES "Build Material, General and Polycrystal tools" ON)
set(BESLE_VORO_SOURCE_DIR "" CACHE PATH "Existing Voro++ source directory")
set(BESLE_TRIANGLE_SOURCE_DIR "" CACHE PATH "Existing Triangle source directory")

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

if(BESLE_BUILD_MAIN OR BESLE_BUILD_AUXILIARIES)
    find_package(BLAS REQUIRED)
    find_package(LAPACK REQUIRED)
endif()

if(BESLE_BUILD_MAIN)
    find_package(MPI REQUIRED COMPONENTS Fortran)
    find_package(OpenMP REQUIRED COMPONENTS Fortran)
    find_package(MUMPS REQUIRED)

    set(BESLE_SOURCES
        BESLE_ROOT/src/Global_variables.f90
        BESLE_ROOT/src/Set_parameters.f90
        BESLE_ROOT/src/Global_functions.f90
        BESLE_ROOT/src/Input.f90
        BESLE_ROOT/src/Failure_Analysis.f90
        BESLE_ROOT/src/Discretization.f90
        BESLE_ROOT/src/BC_Module.f90
        BESLE_ROOT/src/Int_points.f90
        BESLE_ROOT/src/Fourier_Coefficients.f90
        BESLE_ROOT/src/DRM.f90
        BESLE_ROOT/src/Comp_H_G.f90
        BESLE_ROOT/src/Vectors_b.f90
        BESLE_ROOT/src/General_Matrices.f90
        BESLE_ROOT/src/General_Sparce_Vectors.f90
        BESLE_ROOT/src/Module_Solver.f90
        BESLE_ROOT/src/Response_D_T.f90
        BESLE_ROOT/src/Response_S_S.f90
        BESLE_ROOT/src/Homogenization.f90
        BESLE_ROOT/src/Output.f90
        BESLE_ROOT/src/BESLE.f90
    )

    add_executable(BESLE ${BESLE_SOURCES})
    set_target_properties(BESLE PROPERTIES
        Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules/besle"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
    )
    target_link_libraries(BESLE PRIVATE
        MUMPS::DMUMPS
        MPI::MPI_Fortran
        OpenMP::OpenMP_Fortran
        LAPACK::LAPACK
        BLAS::BLAS
    )
    if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
        target_compile_options(BESLE PRIVATE
            -O3
            -ffast-math
            -fimplicit-none
            -fno-range-check
            -fallow-argument-mismatch
        )
    endif()

    if(BUILD_TESTING)
        add_test(
            NAME besle-smoke
            COMMAND
                "${MPIEXEC_EXECUTABLE}"
                "${MPIEXEC_NUMPROC_FLAG}" "2"
                ${MPIEXEC_PREFLAGS}
                "$<TARGET_FILE:BESLE>"
                ${MPIEXEC_POSTFLAGS}
        )
        set_tests_properties(besle-smoke PROPERTIES
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/BESLE_ROOT"
            ENVIRONMENT "BESLE_MAX_STEPS=1;OMP_NUM_THREADS=1"
            TIMEOUT 900
        )
    endif()

    install(TARGETS BESLE RUNTIME DESTINATION ".")
endif()

if(BESLE_BUILD_AUXILIARIES)
    add_executable(BESLE-Material
        BESLE_ROOT/Material/src/Global_variables.f90
        BESLE_ROOT/Material/src/Set_parameters.f90
        BESLE_ROOT/Material/src/Fourier_Coefficient.f90
        BESLE_ROOT/Material/src/Output_data.f90
        BESLE_ROOT/Material/src/F_Coeff.f90
    )
    set_target_properties(BESLE-Material PROPERTIES
        Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules/material"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
    )
    target_link_libraries(BESLE-Material PRIVATE LAPACK::LAPACK BLAS::BLAS)

    add_executable(BESLE-General
        BESLE_ROOT/Mesh/General/src/Global_variables.f90
        BESLE_ROOT/Mesh/General/src/Set_parameters.f90
        BESLE_ROOT/Mesh/General/src/Custom_functions.f90
        BESLE_ROOT/Mesh/General/src/Mesh_BCs.f90
        BESLE_ROOT/Mesh/General/src/Mesh.f90
    )
    set_target_properties(BESLE-General PROPERTIES
        Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules/general"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
    )
    target_link_libraries(BESLE-General PRIVATE LAPACK::LAPACK BLAS::BLAS)

    if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
        foreach(auxiliary_target BESLE-Material BESLE-General)
            target_compile_options(${auxiliary_target} PRIVATE
                -O0
                -fimplicit-none
                -fno-range-check
                -fallow-argument-mismatch
            )
        endforeach()
    endif()

    if(BESLE_VORO_SOURCE_DIR)
        set(voro_SOURCE_DIR "${BESLE_VORO_SOURCE_DIR}")
    else()
        FetchContent_Declare(voro
            GIT_REPOSITORY https://github.com/chr1shr/voro.git
            GIT_TAG 7684cd3d0dd264a3d3ce431fb4ad41a90a36c76d
            GIT_SHALLOW FALSE
        )
        FetchContent_GetProperties(voro)
        if(NOT voro_POPULATED)
            FetchContent_Populate(voro)
        endif()
    endif()

    if(BESLE_TRIANGLE_SOURCE_DIR)
        set(triangle_SOURCE_DIR "${BESLE_TRIANGLE_SOURCE_DIR}")
    else()
        FetchContent_Declare(triangle
            GIT_REPOSITORY https://github.com/PhilipLudington/Triangle.git
            GIT_TAG 6fc5416db5db09fa95a29fd458d2cfa837ac3970
            GIT_SHALLOW FALSE
        )
        FetchContent_GetProperties(triangle)
        if(NOT triangle_POPULATED)
            FetchContent_Populate(triangle)
        endif()
    endif()

    file(GLOB VORO_CORE_SOURCES CONFIGURE_DEPENDS "${voro_SOURCE_DIR}/src/*.cc")
    list(FILTER VORO_CORE_SOURCES EXCLUDE REGEX
        "/(voro\\+\\+|cmd_line|v_base_wl)\\.cc$")
    if(NOT VORO_CORE_SOURCES)
        message(FATAL_ERROR "No Voro++ core sources were found in ${voro_SOURCE_DIR}")
    endif()

    add_library(besle_voro STATIC ${VORO_CORE_SOURCES})
    target_include_directories(besle_voro PUBLIC "${voro_SOURCE_DIR}/src")
    set_target_properties(besle_voro PROPERTIES
        CXX_STANDARD 98
        CXX_STANDARD_REQUIRED YES
        CXX_EXTENSIONS YES
        POSITION_INDEPENDENT_CODE YES
    )

    add_library(besle_triangle STATIC "${triangle_SOURCE_DIR}/triangle.c")
    target_include_directories(besle_triangle PUBLIC "${triangle_SOURCE_DIR}")
    target_compile_definitions(besle_triangle PRIVATE TRILIBRARY)
    if(WIN32)
        target_compile_definitions(besle_triangle PRIVATE NO_TIMER)
    endif()

    add_executable(BESLE-Polycrystal-Structure
        BESLE_ROOT/Mesh/Polycrystal/src/Mesh_Generator.cc
        BESLE_ROOT/Mesh/Polycrystal/src/Set_parameters.cc
        BESLE_ROOT/Mesh/Polycrystal/src/Polycrystalline_Material.cc
        BESLE_ROOT/Mesh/Polycrystal/src/Input_data.cc
        BESLE_ROOT/Mesh/Polycrystal/src/Ouput_data.cc
    )
    target_include_directories(BESLE-Polycrystal-Structure PRIVATE
        BESLE_ROOT/Mesh/Polycrystal/include
        BESLE_ROOT/Mesh/Polycrystal/src
    )
    target_link_libraries(BESLE-Polycrystal-Structure PRIVATE besle_voro)
    set_target_properties(BESLE-Polycrystal-Structure PROPERTIES
        CXX_STANDARD 98
        CXX_STANDARD_REQUIRED YES
        CXX_EXTENSIONS YES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
    )

    add_executable(BESLE-Polycrystal-Mesh
        BESLE_ROOT/Mesh/Polycrystal/src/Main2.c
        BESLE_ROOT/Mesh/Polycrystal/src/Input_data_mesh.c
        BESLE_ROOT/Mesh/Polycrystal/src/2D_Data.c
        BESLE_ROOT/Mesh/Polycrystal/src/transf_coordinates.c
        BESLE_ROOT/Mesh/Polycrystal/src/Output_data.c
    )
    target_include_directories(BESLE-Polycrystal-Mesh PRIVATE
        BESLE_ROOT/Mesh/Polycrystal/src
    )
    target_link_libraries(BESLE-Polycrystal-Mesh PRIVATE besle_triangle)
    if(NOT WIN32)
        target_link_libraries(BESLE-Polycrystal-Mesh PRIVATE m)
    endif()
    set_target_properties(BESLE-Polycrystal-Mesh PROPERTIES
        C_STANDARD 99
        C_STANDARD_REQUIRED YES
        C_EXTENSIONS YES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
    )

    install(TARGETS
        BESLE-Material
        BESLE-General
        BESLE-Polycrystal-Structure
        BESLE-Polycrystal-Mesh
        RUNTIME DESTINATION "."
    )

    if(EXISTS "${voro_SOURCE_DIR}/LICENSE")
        install(FILES "${voro_SOURCE_DIR}/LICENSE"
            DESTINATION "third-party-licenses/Voro++")
    endif()
    if(EXISTS "${triangle_SOURCE_DIR}/README")
        install(FILES "${triangle_SOURCE_DIR}/README"
            DESTINATION "third-party-licenses/Triangle")
    elseif(EXISTS "${triangle_SOURCE_DIR}/README.md")
        install(FILES "${triangle_SOURCE_DIR}/README.md"
            DESTINATION "third-party-licenses/Triangle")
    endif()
endif()

foreach(runtime_dir Body_forces Cracks Material Mesh)
    install(
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/BESLE_ROOT/${runtime_dir}"
        DESTINATION "."
    )
endforeach()

install(FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE"
    "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
    "${CMAKE_CURRENT_SOURCE_DIR}/THIRD_PARTY_NOTICES.md"
    "${CMAKE_CURRENT_SOURCE_DIR}/BESLE_ROOT/VERSION"
    "${CMAKE_CURRENT_SOURCE_DIR}/BESLE_ROOT/BESLE.nml"
    DESTINATION "."
)

if(WIN32)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/packaging")
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/run-besle.ps1.in"
        "${CMAKE_CURRENT_BINARY_DIR}/packaging/run-besle.ps1"
        @ONLY
    )
    install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/run-besle.cmd"
        "${CMAKE_CURRENT_BINARY_DIR}/packaging/run-besle.ps1"
        DESTINATION "."
    )

    if(BESLE_BUILD_AUXILIARIES)
        configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/run-besle-auxiliary.ps1.in"
            "${CMAKE_CURRENT_BINARY_DIR}/packaging/run-besle-auxiliary.ps1"
            @ONLY
        )
        install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/packaging/run-besle-auxiliary.ps1"
            DESTINATION "."
        )
    endif()
endif()
