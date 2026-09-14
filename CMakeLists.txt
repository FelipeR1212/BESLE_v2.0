cmake_minimum_required(VERSION 3.20)

project(BESLE VERSION 2.1.0 LANGUAGES Fortran)

include(CTest)
include(GNUInstallDirs)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(MPI REQUIRED COMPONENTS Fortran)
find_package(OpenMP REQUIRED COMPONENTS Fortran)
find_package(BLAS REQUIRED)
find_package(LAPACK REQUIRED)
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
    Fortran_MODULE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/modules"
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
    DESTINATION "."
)

if(WIN32)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/packaging")
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/run-besle.ps1.in"
        "${CMAKE_CURRENT_BINARY_DIR}/packaging/run-besle.ps1"
        @ONLY
    )
    install(
        FILES
            "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/run-besle.cmd"
            "${CMAKE_CURRENT_BINARY_DIR}/packaging/run-besle.ps1"
        DESTINATION "."
    )
endif()
