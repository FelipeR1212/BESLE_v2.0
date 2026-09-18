!===============================================================================!
! Runtime configuration for BESLE.
!
! Values are initialized with the legacy Set_parameters.f90 defaults and may be
! overridden from BESLE.nml without recompiling the solver. Rank 0 reads and
! validates the file, then broadcasts the effective values to every MPI rank.
!===============================================================================!
MODULE Set_parameters

    USE Global_variables
    USE mpi
    USE, INTRINSIC :: iso_fortran_env, ONLY: error_unit

    IMPLICIT NONE

    PRIVATE
    PUBLIC :: Setup

    ! Launcher setting only: MPI itself determines the actual communicator size.
    INTEGER :: mpi_processes = 2

CONTAINS

    SUBROUTINE Setup(me)

        INTEGER, INTENT(IN) :: me
        INTEGER, PARAMETER :: root = 0
        INTEGER, PARAMETER :: config_unit = 97
        INTEGER :: mpierr, config_status, config_loaded
        INTEGER :: io_status, actual_processes
        LOGICAL :: config_exists, config_required
        CHARACTER(LEN=1024) :: config_file
        CHARACTER(LEN=1024) :: config_message
        CHARACTER(LEN=1024) :: io_message

        NAMELIST /BESLE_CONFIG/ Mesh_file, fileplace_mesh, scale_size_1, &
            Material_coefficients_file, fileplace_material, scale_prop_mat, &
            Transient, Time_steps, Dt, density, load_profile, omega, phase, &
            box_face_2, box_face_4, Results_file, fileplace_results, mpi_processes

        CALL Set_default_parameters

        config_status = 0
        config_loaded = 0
        config_required = .FALSE.
        config_file = 'BESLE.nml'
        config_message = ''
        io_message = ''

        IF (me.EQ.root) THEN
            CALL Resolve_config_file(config_file,config_required,config_status, &
                config_message)

            IF (config_status.EQ.0) THEN
                INQUIRE(FILE=TRIM(config_file),EXIST=config_exists, &
                    IOSTAT=io_status,IOMSG=io_message)

                IF (io_status.NE.0) THEN
                    config_status = 10
                    config_message = 'No se pudo consultar la configuracion: '// &
                        TRIM(io_message)
                ELSEIF (config_exists) THEN
                    OPEN(UNIT=config_unit,FILE=TRIM(config_file),STATUS='OLD', &
                        ACTION='READ',IOSTAT=io_status,IOMSG=io_message)

                    IF (io_status.NE.0) THEN
                        config_status = 11
                        config_message = 'No se pudo abrir la configuracion: '// &
                            TRIM(io_message)
                    ELSE
                        READ(config_unit,NML=BESLE_CONFIG,IOSTAT=io_status, &
                            IOMSG=io_message)
                        CLOSE(config_unit)

                        IF (io_status.NE.0) THEN
                            config_status = 12
                            config_message = 'BESLE.nml contiene un valor invalido: '// &
                                TRIM(io_message)
                        ELSE
                            config_loaded = 1
                            CALL Normalize_paths
                            CALL Validate_parameters(config_status,config_message)
                        END IF
                    END IF
                ELSEIF (config_required) THEN
                    config_status = 14
                    config_message = 'No existe BESLE_CONFIG_FILE: '//TRIM(config_file)
                END IF
            END IF
        END IF

        CALL MPI_BCAST(config_status,1,MPI_INTEGER,root,MPI_COMM_WORLD,mpierr)

        IF (config_status.NE.0) THEN
            IF (me.EQ.root) THEN
                WRITE(error_unit,'(A)') 'ERROR DE CONFIGURACION BESLE: '// &
                    TRIM(config_message)
                FLUSH(error_unit)
            END IF
            CALL MPI_ABORT(MPI_COMM_WORLD,config_status,mpierr)
            RETURN
        END IF

        CALL Broadcast_parameters(root,mpierr)

        IF (me.EQ.root) THEN
            CALL MPI_COMM_SIZE(MPI_COMM_WORLD,actual_processes,mpierr)
            WRITE(*,'(A,I0)') 'Procesos MPI activos: ',actual_processes
            IF (actual_processes.NE.mpi_processes) THEN
                WRITE(*,'(A,I0,A)') 'Aviso: BESLE.nml solicita ',mpi_processes, &
                    ' procesos; se usa la cantidad indicada a mpiexec/mpirun.'
            END IF
            IF (config_loaded.EQ.1) THEN
                WRITE(*,'(A)') 'Configuracion BESLE cargada desde: '//TRIM(config_file)
            ELSE
                WRITE(*,'(A)') 'BESLE.nml no encontrado; se usan los valores heredados.'
            END IF
        END IF

    END SUBROUTINE Setup


    SUBROUTINE Set_default_parameters

        mpi_processes = 2

        ! These expressions intentionally match the published implementation.
        Mesh_file = 'Transient'
        fileplace_mesh = 'Mesh/Box/'
        scale_size_1 = 1e-3

        Material_coefficients_file = 'Material_9'
        fileplace_material = 'Material/Data/Isotropic/'
        scale_prop_mat = 1e6

        Transient = 1
        Time_steps = 200
        Dt = 1e-6
        density = 7850.d0

        load_profile = 'harmonic'
        omega = 0.99*79286.645975178
        phase = 0
        box_face_4 = (/0.d0,0.d0,0.d0,0.d0,0.d0,0.d0/)
        box_face_2 = (/100.d0*(1e6),1.d0,0.d0,1.d0,0.d0,1.d0/)

        Results_file = 'Results'
        fileplace_results = 'Results/'

    END SUBROUTINE Set_default_parameters


    SUBROUTINE Resolve_config_file(config_file,config_required,config_status, &
        config_message)

        CHARACTER(LEN=*), INTENT(INOUT) :: config_file
        LOGICAL, INTENT(OUT) :: config_required
        INTEGER, INTENT(OUT) :: config_status
        CHARACTER(LEN=*), INTENT(OUT) :: config_message
        INTEGER :: env_status, env_length
        CHARACTER(LEN=1024) :: env_value

        config_status = 0
        config_required = .FALSE.
        config_message = ''
        env_value = ''

        CALL GET_ENVIRONMENT_VARIABLE('BESLE_CONFIG_FILE',env_value, &
            LENGTH=env_length,STATUS=env_status)

        IF ((env_status.EQ.0).AND.(env_length.GT.0)) THEN
            config_file = TRIM(env_value)
            config_required = .TRUE.
        ELSEIF (env_status.EQ.-1) THEN
            config_status = 13
            config_message = 'La ruta BESLE_CONFIG_FILE supera 1024 caracteres.'
        ELSE
            config_file = 'BESLE.nml'
        END IF

    END SUBROUTINE Resolve_config_file


    SUBROUTINE Normalize_paths

        CALL Ensure_trailing_separator(fileplace_mesh)
        CALL Ensure_trailing_separator(fileplace_material)
        CALL Ensure_trailing_separator(fileplace_results)

    END SUBROUTINE Normalize_paths


    SUBROUTINE Ensure_trailing_separator(path_value)

        CHARACTER(LEN=*), INTENT(INOUT) :: path_value
        INTEGER :: path_length

        path_length = LEN_TRIM(path_value)
        IF (path_length.EQ.0) RETURN

        IF ((path_value(path_length:path_length).NE.'/').AND. &
            (path_value(path_length:path_length).NE.ACHAR(92))) THEN
            IF (path_length.LT.LEN(path_value)) THEN
                path_value = TRIM(path_value)//'/'
            END IF
        END IF

    END SUBROUTINE Ensure_trailing_separator


    SUBROUTINE Validate_parameters(config_status,config_message)

        INTEGER, INTENT(OUT) :: config_status
        CHARACTER(LEN=*), INTENT(OUT) :: config_message

        config_status = 0
        config_message = ''

        IF (mpi_processes.LT.2) THEN
            config_status = 33
            config_message = 'mpi_processes debe ser un entero mayor o igual a 2.'
        ELSEIF (LEN_TRIM(Mesh_file).EQ.0) THEN
            config_status = 20
            config_message = 'mesh_file no puede estar vacio.'
        ELSEIF (LEN_TRIM(fileplace_mesh).EQ.0) THEN
            config_status = 21
            config_message = 'fileplace_mesh no puede estar vacio.'
        ELSEIF (scale_size_1.LE.0.d0) THEN
            config_status = 22
            config_message = 'scale_size_1 debe ser mayor que cero.'
        ELSEIF (LEN_TRIM(Material_coefficients_file).EQ.0) THEN
            config_status = 23
            config_message = 'material_coefficients_file no puede estar vacio.'
        ELSEIF (LEN_TRIM(fileplace_material).EQ.0) THEN
            config_status = 24
            config_message = 'fileplace_material no puede estar vacio.'
        ELSEIF (scale_prop_mat.LE.0.d0) THEN
            config_status = 25
            config_message = 'scale_prop_mat debe ser mayor que cero.'
        ELSEIF ((Transient.NE.0).AND.(Transient.NE.1)) THEN
            config_status = 26
            config_message = 'transient solo admite 0 o 1.'
        ELSEIF ((Transient.EQ.1).AND.(Time_steps.LE.0)) THEN
            config_status = 27
            config_message = 'time_steps debe ser positivo para un analisis transitorio.'
        ELSEIF ((Transient.EQ.1).AND.(Dt.LE.0.d0)) THEN
            config_status = 28
            config_message = 'dt debe ser positivo para un analisis transitorio.'
        ELSEIF (density.LE.0.d0) THEN
            config_status = 29
            config_message = 'density debe ser mayor que cero.'
        ELSEIF ((TRIM(load_profile).NE.'ramp').AND. &
            (TRIM(load_profile).NE.'Heaviside').AND. &
            (TRIM(load_profile).NE.'harmonic')) THEN
            config_status = 30
            config_message = 'load_profile debe ser ramp, Heaviside o harmonic.'
        ELSEIF (LEN_TRIM(Results_file).EQ.0) THEN
            config_status = 31
            config_message = 'results_file no puede estar vacio.'
        ELSEIF (LEN_TRIM(fileplace_results).EQ.0) THEN
            config_status = 32
            config_message = 'fileplace_results no puede estar vacio.'
        END IF

    END SUBROUTINE Validate_parameters


    SUBROUTINE Broadcast_parameters(root,mpierr)

        INTEGER, INTENT(IN) :: root
        INTEGER, INTENT(OUT) :: mpierr

        CALL MPI_BCAST(mpi_processes,1,MPI_INTEGER,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(Mesh_file,LEN(Mesh_file),MPI_CHARACTER,root, &
            MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(fileplace_mesh,LEN(fileplace_mesh),MPI_CHARACTER,root, &
            MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(scale_size_1,1,MPI_DOUBLE_PRECISION,root, &
            MPI_COMM_WORLD,mpierr)

        CALL MPI_BCAST(Material_coefficients_file, &
            LEN(Material_coefficients_file),MPI_CHARACTER,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(fileplace_material,LEN(fileplace_material),MPI_CHARACTER, &
            root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(scale_prop_mat,1,MPI_DOUBLE_PRECISION,root, &
            MPI_COMM_WORLD,mpierr)

        CALL MPI_BCAST(Transient,1,MPI_INTEGER,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(Time_steps,1,MPI_INTEGER,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(Dt,1,MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(density,1,MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(load_profile,LEN(load_profile),MPI_CHARACTER,root, &
            MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(omega,1,MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(phase,1,MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(box_face_2,SIZE(box_face_2),MPI_DOUBLE_PRECISION,root, &
            MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(box_face_4,SIZE(box_face_4),MPI_DOUBLE_PRECISION,root, &
            MPI_COMM_WORLD,mpierr)

        CALL MPI_BCAST(Results_file,LEN(Results_file),MPI_CHARACTER,root, &
            MPI_COMM_WORLD,mpierr)
        CALL MPI_BCAST(fileplace_results,LEN(fileplace_results),MPI_CHARACTER,root, &
            MPI_COMM_WORLD,mpierr)

    END SUBROUTINE Broadcast_parameters

END MODULE Set_parameters
