!====================================================================================!
MODULE Set_parameters
!------------------------------------------------------------------------------------!
USE Global_variables
IMPLICIT NONE

TYPE :: BC_Config_Entry
    CHARACTER(LEN=20) :: direction
    CHARACTER(LEN=20) :: bc_type(4)
    CHARACTER(LEN=20) :: function_type(5)
    REAL(8) :: static_value(5)
    REAL(8) :: linear_max(5)
    REAL(8) :: quadratic_start(5)
    REAL(8) :: quadratic_end(5)
    REAL(8) :: quadratic_a(5)
    REAL(8) :: quadratic_b(5)
    REAL(8) :: quadratic_c(5)
    REAL(8) :: sine_start(5)
    REAL(8) :: sine_end(5)
    REAL(8) :: sine_a(5)
    REAL(8) :: sine_b(5)
    REAL(8) :: sine_c(5)
    REAL(8) :: load_direction(3)
END TYPE BC_Config_Entry

!------------------------------------------------------------------------------------!
CONTAINS

    SUBROUTINE Setup
        TYPE(BC_Config_Entry) :: boundary_conditions(MAX_BOUNDARY_CONDITIONS)
        CHARACTER(LEN=1024) :: config_file, boundary_file
        CHARACTER(LEN=512) :: io_message
        CHARACTER(LEN=20) :: boundary_number
        INTEGER :: config_unit, env_length, env_status, io_status, index
        LOGICAL :: config_exists, explicit_config, input_exists

        NAMELIST /GENERAL_CONFIG/ filename_in, filename_out, BCSfilesPlace_in, &
            AnalysisType, Nsteps, NumBCS, MeshNumPress, boundary_conditions

        CALL Set_historical_defaults(boundary_conditions)

        config_file = ''
        CALL GET_ENVIRONMENT_VARIABLE('BESLE_GENERAL_CONFIG_FILE', &
            VALUE=config_file, LENGTH=env_length, STATUS=env_status, &
            TRIM_NAME=.TRUE.)
        explicit_config = env_status == 0 .AND. env_length > 0

        IF (env_status == -1) THEN
            CALL Configuration_error('La ruta de BESLE_GENERAL_CONFIG_FILE es demasiado larga.')
        ELSE IF (.NOT. explicit_config) THEN
            config_file = 'General.nml'
        END IF

        INQUIRE(FILE=TRIM(config_file), EXIST=config_exists)
        IF (.NOT. config_exists) THEN
            IF (explicit_config) THEN
                CALL Configuration_error('No se encontro el archivo: '//TRIM(config_file))
            END IF
        ELSE
            OPEN(NEWUNIT=config_unit, FILE=TRIM(config_file), STATUS='OLD', &
                ACTION='READ', IOSTAT=io_status, IOMSG=io_message)
            IF (io_status /= 0) THEN
                CALL Configuration_error('No se pudo abrir '//TRIM(config_file)//': '// &
                    TRIM(io_message))
            END IF
            READ(config_unit, NML=GENERAL_CONFIG, IOSTAT=io_status, IOMSG=io_message)
            CLOSE(config_unit)
            IF (io_status /= 0) THEN
                CALL Configuration_error('No se pudo leer '//TRIM(config_file)//': '// &
                    TRIM(io_message))
            END IF
        END IF

        CALL Canonicalize_configuration(boundary_conditions)
        CALL Validate_configuration(boundary_conditions)

        INQUIRE(FILE=TRIM(filename_in), EXIST=input_exists)
        IF (.NOT. input_exists) THEN
            CALL Configuration_error('No se encontro la malla OBJ: '//TRIM(filename_in))
        END IF
        DO index = 1, NumBCS
            WRITE(boundary_number, '(I0)') index
            boundary_file = TRIM(BCSfilesPlace_in)//'BCs_'// &
                TRIM(boundary_number)//'.obj'
            INQUIRE(FILE=TRIM(boundary_file), EXIST=input_exists)
            IF (.NOT. input_exists) THEN
                CALL Configuration_error('No se encontro la condicion de borde: '// &
                    TRIM(boundary_file))
            END IF
        END DO

        CALL Apply_configuration(boundary_conditions)
    END SUBROUTINE Setup

    SUBROUTINE Set_historical_defaults(entries)
        TYPE(BC_Config_Entry), INTENT(OUT) :: entries(:)
        INTEGER :: index

        filename_in = 'Meshes/Obj/mesh.obj'
        filename_out = 'Input_data.dat'
        BCSfilesPlace_in = 'BCs/BCs_Obj/'
        AnalysisType = 'quasi-elastostatic'
        Nsteps = 50
        NumBCS = 2
        MeshNumPress = 4

        DO index = 1, SIZE(entries)
            entries(index)%direction = 'xyz'
            entries(index)%bc_type = 'free'
            entries(index)%function_type = 'linear'
            entries(index)%static_value = 0.d0
            entries(index)%linear_max = 0.d0
            entries(index)%quadratic_start = 0.d0
            entries(index)%quadratic_end = 1.d0
            entries(index)%quadratic_a = 0.d0
            entries(index)%quadratic_b = 0.d0
            entries(index)%quadratic_c = 0.d0
            entries(index)%sine_start = 0.d0
            entries(index)%sine_end = 1.d0
            entries(index)%sine_a = 0.d0
            entries(index)%sine_b = 0.d0
            entries(index)%sine_c = 0.d0
            entries(index)%load_direction = (/1.d0, 0.d0, 0.d0/)
        END DO

        entries(1)%direction = 'xyz'
        entries(1)%bc_type(1:3) = 'displacement'
        entries(2)%direction = 'xyz'
        entries(2)%bc_type(1) = 'traction'
        entries(2)%bc_type(2) = 'free'
        entries(2)%bc_type(3) = 'traction'
        entries(2)%linear_max(1) = 100.d0
        entries(2)%linear_max(3) = 100.d0
    END SUBROUTINE Set_historical_defaults

    SUBROUTINE Canonicalize_configuration(entries)
        TYPE(BC_Config_Entry), INTENT(INOUT) :: entries(:)
        INTEGER :: index, component, path_length

        filename_in = TRIM(ADJUSTL(filename_in))
        filename_out = TRIM(ADJUSTL(filename_out))
        BCSfilesPlace_in = TRIM(ADJUSTL(BCSfilesPlace_in))
        AnalysisType = Lower_case(TRIM(ADJUSTL(AnalysisType)))

        path_length = LEN_TRIM(BCSfilesPlace_in)
        IF (path_length > 0) THEN
            IF (BCSfilesPlace_in(path_length:path_length) /= '/' .AND. &
                IACHAR(BCSfilesPlace_in(path_length:path_length)) /= 92) THEN
                BCSfilesPlace_in = TRIM(BCSfilesPlace_in)//'/'
            END IF
        END IF

        DO index = 1, NumBCS
            entries(index)%direction = Lower_case( &
                TRIM(ADJUSTL(entries(index)%direction)))
            DO component = 1, 4
                entries(index)%bc_type(component) = Lower_case( &
                    TRIM(ADJUSTL(entries(index)%bc_type(component))))
            END DO
            DO component = 1, 5
                entries(index)%function_type(component) = Lower_case( &
                    TRIM(ADJUSTL(entries(index)%function_type(component))))
            END DO
        END DO
    END SUBROUTINE Canonicalize_configuration

    SUBROUTINE Validate_configuration(entries)
        TYPE(BC_Config_Entry), INTENT(IN) :: entries(:)
        INTEGER :: index, component

        IF (LEN_TRIM(filename_in) == 0) THEN
            CALL Configuration_error('filename_in no puede estar vacio.')
        END IF
        IF (LEN_TRIM(filename_out) == 0) THEN
            CALL Configuration_error('filename_out no puede estar vacio.')
        END IF
        IF (LEN_TRIM(BCSfilesPlace_in) == 0) THEN
            CALL Configuration_error('BCSfilesPlace_in no puede estar vacio.')
        END IF
        IF (.NOT. Is_analysis_type(AnalysisType)) THEN
            CALL Configuration_error('AnalysisType debe ser elastostatic, '// &
                'quasi-elastostatic o elastodynamic.')
        END IF
        IF (Nsteps < 1) THEN
            CALL Configuration_error('Nsteps debe ser mayor o igual que 1.')
        END IF
        IF (NumBCS < 0 .OR. NumBCS > MAX_BOUNDARY_CONDITIONS) THEN
            CALL Configuration_error('NumBCS debe estar entre 0 y 1000.')
        END IF
        IF (MeshNumPress < 0 .OR. MeshNumPress > 12) THEN
            CALL Configuration_error('MeshNumPress debe estar entre 0 y 12.')
        END IF

        DO index = 1, NumBCS
            SELECT CASE (TRIM(entries(index)%direction))
            CASE ('xyz')
                DO component = 1, 3
                    IF (.NOT. Is_xyz_bc_type(entries(index)%bc_type(component))) THEN
                        CALL Boundary_error(index, 'bc_type debe ser displacement, '// &
                            'traction o free para xyz.')
                    END IF
                    IF (entries(index)%bc_type(component) /= 'free' .AND. &
                        AnalysisType /= 'elastostatic' .AND. &
                        .NOT. Is_function_type(entries(index)%function_type(component))) THEN
                        CALL Boundary_error(index, 'function_type no es valido para xyz.')
                    END IF
                END DO
            CASE ('normal')
                IF (entries(index)%bc_type(4) /= 'displacement' .AND. &
                    entries(index)%bc_type(4) /= 'traction') THEN
                    CALL Boundary_error(index, 'bc_type(4) debe ser displacement o '// &
                        'traction para normal.')
                END IF
                IF (AnalysisType /= 'elastostatic' .AND. &
                    .NOT. Is_function_type(entries(index)%function_type(4))) THEN
                    CALL Boundary_error(index, 'function_type(4) no es valido para normal.')
                END IF
            CASE ('load')
                IF (NORM2(entries(index)%load_direction) <= 0.d0) THEN
                    CALL Boundary_error(index, 'load_direction no puede ser el vector cero.')
                END IF
                IF (AnalysisType /= 'elastostatic' .AND. &
                    .NOT. Is_function_type(entries(index)%function_type(5))) THEN
                    CALL Boundary_error(index, 'function_type(5) no es valido para load.')
                END IF
            CASE DEFAULT
                CALL Boundary_error(index, 'direction debe ser xyz, normal o load.')
            END SELECT
        END DO
    END SUBROUTINE Validate_configuration

    SUBROUTINE Apply_configuration(entries)
        TYPE(BC_Config_Entry), INTENT(IN) :: entries(:)
        INTEGER :: index

        DO index = 1, NumBCS
            BC(index)%DirType = entries(index)%direction
            BC(index)%BCxType = entries(index)%bc_type(1)
            BC(index)%BCyType = entries(index)%bc_type(2)
            BC(index)%BCzType = entries(index)%bc_type(3)
            BC(index)%BCnType = entries(index)%bc_type(4)
            BC(index)%FuncxType = entries(index)%function_type(1)
            BC(index)%FuncyType = entries(index)%function_type(2)
            BC(index)%FunczType = entries(index)%function_type(3)
            BC(index)%FuncnType = entries(index)%function_type(4)
            BC(index)%FunclType = entries(index)%function_type(5)
            BC(index)%IDtype = 0

            BC(index)%EParam%staticBCxVal = entries(index)%static_value(1)
            BC(index)%EParam%staticBCyVal = entries(index)%static_value(2)
            BC(index)%EParam%staticBCzVal = entries(index)%static_value(3)
            BC(index)%EParam%staticBCnVal = entries(index)%static_value(4)
            BC(index)%EParam%staticBClVal = entries(index)%static_value(5)

            BC(index)%LParam%LinearBCxMaxVal = entries(index)%linear_max(1)
            BC(index)%LParam%LinearBCyMaxVal = entries(index)%linear_max(2)
            BC(index)%LParam%LinearBCzMaxVal = entries(index)%linear_max(3)
            BC(index)%LParam%LinearBCnMaxVal = entries(index)%linear_max(4)
            BC(index)%LParam%LinearBClMaxVal = entries(index)%linear_max(5)

            CALL Apply_quadratic(entries(index), BC(index)%QParam)
            CALL Apply_sine(entries(index), BC(index)%SParam)
            BC(index)%LoadDirection = entries(index)%load_direction
        END DO
    END SUBROUTINE Apply_configuration

    SUBROUTINE Apply_quadratic(entry, parameters)
        TYPE(BC_Config_Entry), INTENT(IN) :: entry
        TYPE(QuadPara), INTENT(OUT) :: parameters

        parameters%QuadSOx = entry%quadratic_start(1)
        parameters%QuadSOy = entry%quadratic_start(2)
        parameters%QuadSOz = entry%quadratic_start(3)
        parameters%QuadSOn = entry%quadratic_start(4)
        parameters%QuadSOl = entry%quadratic_start(5)
        parameters%QuadSfx = entry%quadratic_end(1)
        parameters%QuadSfy = entry%quadratic_end(2)
        parameters%QuadSfz = entry%quadratic_end(3)
        parameters%QuadSfn = entry%quadratic_end(4)
        parameters%QuadSfl = entry%quadratic_end(5)
        parameters%QuadAx = entry%quadratic_a(1)
        parameters%QuadAy = entry%quadratic_a(2)
        parameters%QuadAz = entry%quadratic_a(3)
        parameters%QuadAn = entry%quadratic_a(4)
        parameters%QuadAl = entry%quadratic_a(5)
        parameters%QuadBx = entry%quadratic_b(1)
        parameters%QuadBy = entry%quadratic_b(2)
        parameters%QuadBz = entry%quadratic_b(3)
        parameters%QuadBn = entry%quadratic_b(4)
        parameters%QuadBl = entry%quadratic_b(5)
        parameters%QuadCx = entry%quadratic_c(1)
        parameters%QuadCy = entry%quadratic_c(2)
        parameters%QuadCz = entry%quadratic_c(3)
        parameters%QuadCn = entry%quadratic_c(4)
        parameters%QuadCl = entry%quadratic_c(5)
        parameters%QuadSAux = 0.d0
    END SUBROUTINE Apply_quadratic

    SUBROUTINE Apply_sine(entry, parameters)
        TYPE(BC_Config_Entry), INTENT(IN) :: entry
        TYPE(SinePara), INTENT(OUT) :: parameters

        parameters%SineSOx = entry%sine_start(1)
        parameters%SineSOy = entry%sine_start(2)
        parameters%SineSOz = entry%sine_start(3)
        parameters%SineSOn = entry%sine_start(4)
        parameters%SineSOl = entry%sine_start(5)
        parameters%SineSfx = entry%sine_end(1)
        parameters%SineSfy = entry%sine_end(2)
        parameters%SineSfz = entry%sine_end(3)
        parameters%SineSfn = entry%sine_end(4)
        parameters%SineSfl = entry%sine_end(5)
        parameters%SineAx = entry%sine_a(1)
        parameters%SineAy = entry%sine_a(2)
        parameters%SineAz = entry%sine_a(3)
        parameters%SineAn = entry%sine_a(4)
        parameters%SineAl = entry%sine_a(5)
        parameters%SineBx = entry%sine_b(1)
        parameters%SineBy = entry%sine_b(2)
        parameters%SineBz = entry%sine_b(3)
        parameters%SineBn = entry%sine_b(4)
        parameters%SineBl = entry%sine_b(5)
        parameters%SineCx = entry%sine_c(1)
        parameters%SineCy = entry%sine_c(2)
        parameters%SineCz = entry%sine_c(3)
        parameters%SineCn = entry%sine_c(4)
        parameters%SineCl = entry%sine_c(5)
        parameters%SineSAux = 0.d0
    END SUBROUTINE Apply_sine

    LOGICAL FUNCTION Is_analysis_type(value)
        CHARACTER(LEN=*), INTENT(IN) :: value
        Is_analysis_type = TRIM(value) == 'elastostatic' .OR. &
            TRIM(value) == 'quasi-elastostatic' .OR. &
            TRIM(value) == 'elastodynamic'
    END FUNCTION Is_analysis_type

    LOGICAL FUNCTION Is_xyz_bc_type(value)
        CHARACTER(LEN=*), INTENT(IN) :: value
        Is_xyz_bc_type = TRIM(value) == 'displacement' .OR. &
            TRIM(value) == 'traction' .OR. TRIM(value) == 'free'
    END FUNCTION Is_xyz_bc_type

    LOGICAL FUNCTION Is_function_type(value)
        CHARACTER(LEN=*), INTENT(IN) :: value
        Is_function_type = TRIM(value) == 'linear' .OR. &
            TRIM(value) == 'quadratic' .OR. TRIM(value) == 'sine' .OR. &
            TRIM(value) == 'custom_1' .OR. TRIM(value) == 'custom_2' .OR. &
            TRIM(value) == 'custom_3'
    END FUNCTION Is_function_type

    FUNCTION Lower_case(value) RESULT(lowered)
        CHARACTER(LEN=*), INTENT(IN) :: value
        CHARACTER(LEN=LEN(value)) :: lowered
        INTEGER :: index, code

        lowered = value
        DO index = 1, LEN(value)
            code = IACHAR(value(index:index))
            IF (code >= IACHAR('A') .AND. code <= IACHAR('Z')) THEN
                lowered(index:index) = ACHAR(code + IACHAR('a') - IACHAR('A'))
            END IF
        END DO
    END FUNCTION Lower_case

    SUBROUTINE Boundary_error(index, message)
        INTEGER, INTENT(IN) :: index
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=20) :: number

        WRITE(number, '(I0)') index
        CALL Configuration_error('Condicion de borde '//TRIM(number)//': '//TRIM(message))
    END SUBROUTINE Boundary_error

    SUBROUTINE Configuration_error(message)
        CHARACTER(LEN=*), INTENT(IN) :: message
        WRITE(*,'(A)') 'ERROR DE CONFIGURACION GENERAL: '//TRIM(message)
        ERROR STOP 1
    END SUBROUTINE Configuration_error

END MODULE Set_parameters
!====================================================================================!
