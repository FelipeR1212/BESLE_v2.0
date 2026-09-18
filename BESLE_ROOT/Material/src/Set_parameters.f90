!====================================================================================!
MODULE Set_parameters
!------------------------------------------------------------------------------------!
USE Global_variables
IMPLICIT NONE
!------------------------------------------------------------------------------------!
CONTAINS

    SUBROUTINE Setup
        CHARACTER(LEN=1024) :: config_file, input_file
        CHARACTER(LEN=512) :: io_message
        INTEGER :: config_unit, env_length, env_status, io_status
        LOGICAL :: config_exists, explicit_config, input_exists

        NAMELIST /MATERIAL_CONFIG/ fileplace, file_name, Material, Lattice, &
            n_materials, E, nu, C11, C12, C13, C14, C15, C16, C22, C23, &
            C24, C25, C26, C33, C34, C35, C36, C44, C45, C46, C55, C56, &
            C66, z_x_z, x_y_z, theta_x, theta_y, theta_z

        CALL Set_historical_defaults

        config_file = ''
        CALL GET_ENVIRONMENT_VARIABLE('BESLE_MATERIAL_CONFIG_FILE', &
            VALUE=config_file, LENGTH=env_length, STATUS=env_status, &
            TRIM_NAME=.TRUE.)
        explicit_config = env_status == 0 .AND. env_length > 0

        IF (env_status == -1) THEN
            CALL Configuration_error('The BESLE_MATERIAL_CONFIG_FILE path is too long.')
        ELSE IF (.NOT. explicit_config) THEN
            config_file = 'Material.nml'
        END IF

        INQUIRE(FILE=TRIM(config_file), EXIST=config_exists)
        IF (.NOT. config_exists) THEN
            IF (explicit_config) THEN
                CALL Configuration_error('File not found: '//TRIM(config_file))
            END IF
        ELSE
            OPEN(NEWUNIT=config_unit, FILE=TRIM(config_file), STATUS='OLD', &
                ACTION='READ', IOSTAT=io_status, IOMSG=io_message)
            IF (io_status /= 0) THEN
                CALL Configuration_error('Could not open '//TRIM(config_file)//': '// &
                    TRIM(io_message))
            END IF

            READ(config_unit, NML=MATERIAL_CONFIG, IOSTAT=io_status, IOMSG=io_message)
            CLOSE(config_unit)
            IF (io_status /= 0) THEN
                CALL Configuration_error('Could not read '//TRIM(config_file)//': '// &
                    TRIM(io_message))
            END IF
        END IF

        CALL Canonicalize_configuration
        CALL Validate_configuration

        IF (Needs_input_file()) THEN
            input_file = TRIM(fileplace)//TRIM(file_name)
            INQUIRE(FILE=TRIM(input_file), EXIST=input_exists)
            IF (.NOT. input_exists) THEN
                CALL Configuration_error('Input file not found: '// &
                    TRIM(input_file))
            END IF
        END IF
    END SUBROUTINE Setup

    SUBROUTINE Set_historical_defaults
        fileplace = 'Data/Isotropic/'
        file_name = 'Material_9.dat'
        Material = 'Isotropic'
        Lattice = ''
        n_materials = 1

        E = 200000.d0
        nu = 0.d0

        C11 = 0.d0; C12 = 0.d0; C13 = 0.d0
        C14 = 0.d0; C15 = 0.d0; C16 = 0.d0
        C22 = 0.d0; C23 = 0.d0; C24 = 0.d0
        C25 = 0.d0; C26 = 0.d0; C33 = 0.d0
        C34 = 0.d0; C35 = 0.d0; C36 = 0.d0
        C44 = 0.d0; C45 = 0.d0; C46 = 0.d0
        C55 = 0.d0; C56 = 0.d0; C66 = 0.d0

        z_x_z = 0
        x_y_z = 1
        theta_x = 0.d0
        theta_y = 0.d0
        theta_z = 0.d0
    END SUBROUTINE Set_historical_defaults

    SUBROUTINE Canonicalize_configuration
        CHARACTER(LEN=300) :: normalized
        INTEGER :: path_length

        normalized = Lower_case(TRIM(ADJUSTL(Material)))
        SELECT CASE (TRIM(normalized))
        CASE ('isotropic')
            Material = 'Isotropic'
        CASE ('anisotropic')
            Material = 'Anisotropic'
        CASE ('multiple_iso')
            Material = 'Multiple_iso'
        CASE ('multiple_aniso')
            Material = 'Multiple_aniso'
        CASE DEFAULT
            CALL Configuration_error('material must be Isotropic, Anisotropic, '// &
                'Multiple_iso or Multiple_aniso.')
        END SELECT

        normalized = Lower_case(TRIM(ADJUSTL(Lattice)))
        SELECT CASE (TRIM(normalized))
        CASE ('cubic', 'hcp', 'trigonal', 'full')
            Lattice = TRIM(normalized)
        CASE ('')
            Lattice = ''
        CASE DEFAULT
            CALL Configuration_error('lattice must be cubic, hcp, trigonal or full.')
        END SELECT

        fileplace = TRIM(ADJUSTL(fileplace))
        file_name = TRIM(ADJUSTL(file_name))
        path_length = LEN_TRIM(fileplace)
        IF (path_length > 0) THEN
            IF (fileplace(path_length:path_length) /= '/' .AND. &
                IACHAR(fileplace(path_length:path_length)) /= 92) THEN
                fileplace = TRIM(fileplace)//'/'
            END IF
        END IF
    END SUBROUTINE Canonicalize_configuration

    SUBROUTINE Validate_configuration
        IF (LEN_TRIM(fileplace) == 0) THEN
            CALL Configuration_error('fileplace must not be empty.')
        END IF
        IF (LEN_TRIM(file_name) == 0) THEN
            CALL Configuration_error('file_name must not be empty.')
        END IF
        IF (n_materials < 1) THEN
            CALL Configuration_error('n_materials must be at least 1.')
        END IF
        IF (Material == 'Isotropic') THEN
            IF (n_materials /= 1) THEN
                CALL Configuration_error('Isotropic requires exactly one material.')
            END IF
            IF (E <= 0.d0) THEN
                CALL Configuration_error('E must be greater than zero.')
            END IF
            IF (nu <= -1.d0 .OR. nu >= 0.5d0) THEN
                CALL Configuration_error('nu must be greater than -1 and less than 0.5.')
            END IF
        END IF
        IF (Material == 'Anisotropic') THEN
            IF (LEN_TRIM(Lattice) == 0) THEN
                CALL Configuration_error('lattice is required for Anisotropic.')
            END IF
            IF (z_x_z /= 0 .AND. z_x_z /= 1) THEN
                CALL Configuration_error('z_x_z must be 0 or 1.')
            END IF
            IF (x_y_z /= 0 .AND. x_y_z /= 1) THEN
                CALL Configuration_error('x_y_z must be 0 or 1.')
            END IF
            IF (z_x_z + x_y_z /= 1) THEN
                CALL Configuration_error('Select exactly one rotation convention: z_x_z or x_y_z.')
            END IF
            IF (n_materials == 1 .AND. C11 <= 0.d0) THEN
                CALL Configuration_error('C11 must be greater than zero for Anisotropic.')
            END IF
        END IF
    END SUBROUTINE Validate_configuration

    LOGICAL FUNCTION Needs_input_file()
        Needs_input_file = Material == 'Multiple_iso' .OR. &
            Material == 'Multiple_aniso' .OR. &
            (Material == 'Anisotropic' .AND. n_materials > 1)
    END FUNCTION Needs_input_file

    FUNCTION Lower_case(value) RESULT(lowered)
        CHARACTER(LEN=*), INTENT(IN) :: value
        CHARACTER(LEN=LEN(value)) :: lowered
        INTEGER :: i, code

        lowered = value
        DO i = 1, LEN(value)
            code = IACHAR(value(i:i))
            IF (code >= IACHAR('A') .AND. code <= IACHAR('Z')) THEN
                lowered(i:i) = ACHAR(code + IACHAR('a') - IACHAR('A'))
            END IF
        END DO
    END FUNCTION Lower_case

    SUBROUTINE Configuration_error(message)
        CHARACTER(LEN=*), INTENT(IN) :: message
        WRITE(*,'(A)') 'MATERIAL CONFIGURATION ERROR: '//TRIM(message)
        ERROR STOP 1
    END SUBROUTINE Configuration_error

END MODULE Set_parameters
!====================================================================================!
