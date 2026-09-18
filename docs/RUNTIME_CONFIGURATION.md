# Configuración de simulaciones sin recompilar

BESLE puede leer los parámetros que antes estaban escritos dentro de
`src/Set_parameters.f90` desde el archivo externo `BESLE.nml`. El ejecutable se
compila una sola vez: después se puede editar el archivo, guardarlo y ejecutar
de nuevo la simulación sin recompilar Fortran.

## Uso en Windows

1. Abra BESLE desde el acceso directo.
2. Elija `2. Omitir la prueba y crear la carpeta de simulación`.
3. Entre a la carpeta del proyecto indicada por el lanzador. En este punto no
   se ha ejecutado ningún cálculo ni se han generado archivos VTK.
4. Abra directamente `BESLE.nml` con el Bloc de notas o con otro editor de
   texto plano.
5. Cambie únicamente los valores necesarios y guarde el archivo.
6. Ejecute `run-this-simulation.cmd` dentro de la misma carpeta.

La opción 1 del lanzador es únicamente una prueba opcional de un paso para la
primera instalación o para verificar posteriormente que BESLE y Microsoft MPI
funcionan. El lanzador nunca inicia automáticamente el caso predeterminado de
200 pasos.

En cada repetición, los resultados y el registro anteriores se trasladan a una
subcarpeta fechada dentro de `history`. La configuración realmente utilizada se
guarda como `BESLE-used.nml`, lo cual permite reproducir y documentar cada caso.

Los proyectos se crean de forma predeterminada en
`Documentos\BESLE\2.1.0\runs`; nunca se modifican los archivos instalados bajo
`Program Files`.

### Cantidad de procesos MPI

La simulación principal permite elegir la cantidad de procesos en el mismo
`BESLE.nml`, dentro de `&BESLE_CONFIG`:

```fortran
    mpi_processes = 4
```

Guarde el archivo y ejecute `run-this-simulation.cmd`. El lanzador de Windows
lee ese valor antes de iniciar `mpiexec`. No se añaden opciones al menú ni
archivos de configuración adicionales. El valor inicial es `2`; si un proyecto
anterior no contiene esta línea, también se usan `2` procesos.

El valor debe ser un entero mayor o igual a `2`, escrito una sola vez. Un valor
inválido se rechaza antes de iniciar MPI o trasladar los resultados anteriores
a `history`. `BESLE.log` registra la cantidad realmente activa. Cada proceso
mantiene las bibliotecas numéricas limitadas a un hilo; procesos MPI, núcleos
físicos y pasos temporales no son la misma cosa. Una cantidad mayor no garantiza
un cálculo más rápido: también depende del tamaño del problema y de la memoria
y CPU disponibles. Este parámetro no cambia el paralelismo de los generadores
auxiliares.

## Herramientas auxiliares en Windows

La carpeta de simulación también incluye los generadores auxiliares de
materiales, malla general y malla policristalina. Cada herramienta usa dos
archivos con responsabilidades diferentes:

| Carpeta | Archivo editable | Archivo para ejecutar |
|---|---|---|
| `Material` | `Material.nml` | `run-material.cmd` |
| `Mesh\General` | `General.nml` | `run-general.cmd` |
| `Mesh\Polycrystal` | `Polycrystal.nml` | `run-polycrystal.cmd` |

El archivo `.nml` es la única fuente de parámetros y debe conservarse. El
archivo `.cmd` no contiene una segunda configuración ni abre un editor: solo
lee el `.nml` de su misma carpeta y ejecuta el generador instalado. Por tanto,
el flujo es siempre el mismo:

1. Abra directamente el archivo `.nml` con el Bloc de notas.
2. Cambie y guarde los valores necesarios.
3. Ejecute el archivo `.cmd` de la misma fila de la tabla.

No se modifica ni se recompila ningún `.f90`, `.c` o `.cc`. Después de cada
ejecución se guarda una copia de la configuración efectiva como
`Material-used.nml`, `General-used.nml` o `Polycrystal-used.nml`, junto con el
registro correspondiente. Si ya había resultados, se conservan bajo
`history` antes de producir los nuevos.

### Material

`Material.nml` permite seleccionar las rutas de salida, el tipo y la red del
material, la cantidad de materiales, `E`, `nu`, los 21 coeficientes
independientes de la matriz elástica y los ángulos de rotación. La
configuración incluida reproduce el archivo histórico
`Data\Isotropic\Material_9.dat`.

### General

`General.nml` controla los archivos de entrada y salida, el tipo de análisis,
el número de pasos, la precisión y hasta 1000 condiciones de frontera. Para
cada condición se pueden definir dirección, tipo, función y parámetros
estáticos, lineales, cuadráticos o sinusoidales. Las expresiones internas de
las funciones personalizadas `custom_1`, `custom_2` y `custom_3` siguen siendo
código Fortran; cambiar sus fórmulas, a diferencia de seleccionar y
parametrizar las funciones disponibles, sí requiere recompilar.

### Polycrystal

`Polycrystal.nml` permite cambiar la cantidad de granos en `x`, `y` y `z`, las
dimensiones máximas, el modo regular o aleatorio de los centros y la densidad
de triangulación `dm`. `run-polycrystal.cmd` ejecuta en orden la generación de
la estructura y de la malla, y deja `Export\Mesh.dat` y `Export\Mesh.vtk`.

Los valores predeterminados de los tres archivos `.nml` reproducen exactamente
las salidas de los códigos auxiliares publicados. Una configuración inválida
se detiene antes de generar una salida nueva.

## Uso en Linux

Después de compilar BESLE por el procedimiento habitual, edite
`BESLE_ROOT/BESLE.nml` y ejecute desde `BESLE_ROOT`:

```bash
mpirun -np 2 ./BESLE
```

Con la compilación CMake, el ejecutable normalmente está en
`../build/bin/BESLE`. También se puede indicar otro archivo sin moverlo:

```bash
BESLE_CONFIG_FILE=/ruta/al/caso/BESLE.nml mpirun -np 2 ../build/bin/BESLE
```

Si `BESLE_CONFIG_FILE` se define explícitamente, el archivo debe existir. Si no
se define y `BESLE.nml` no está presente, BESLE conserva los valores históricos
compilados para mantener compatibilidad con ejecuciones antiguas.

En Linux y en ejecuciones manuales, el número de procesos se elige antes de
iniciar BESLE, mediante `mpirun -np N` o `mpiexec -n N`. Para un archivo con
`mpi_processes = 4`, utilice, por ejemplo, `mpirun -np 4 ./BESLE`. El solver no
puede crear procesos retroactivamente: si la cantidad lanzada difiere de la
configuración, muestra un aviso y conserva la cantidad indicada al comando MPI.

## Parámetros disponibles

| Parámetro | Función | Valor de referencia |
|---|---|---:|
| `mpi_processes` | Procesos MPI solicitados al lanzador Windows (mínimo 2) | `2` |
| `mesh_file` | Nombre del archivo de malla, sin `.dat` | `'Transient'` |
| `fileplace_mesh` | Carpeta de la malla | `'Mesh/Box/'` |
| `scale_size_1` | Factor de escala geométrica | `1.0000000474974513d-3` |
| `material_coefficients_file` | Archivo de coeficientes, sin `.dat` | `'Material_9'` |
| `fileplace_material` | Carpeta del material | `'Material/Data/Isotropic/'` |
| `scale_prop_mat` | Factor de escala de propiedades | `1.0d6` |
| `transient` | Activa (`1`) o desactiva (`0`) el análisis transitorio | `1` |
| `time_steps` | Número total de pasos | `200` |
| `dt` | Tamaño del paso temporal | `9.9999999747524271d-7` |
| `density` | Densidad del material | `7850.0d0` |
| `load_profile` | Perfil de carga | `'harmonic'` |
| `omega` | Frecuencia angular del perfil armónico | `78493.78125d0` |
| `phase` | Fase del perfil armónico | `0.0d0` |
| `box_face_2` | Condiciones de frontera de la cara 2 | Véase `BESLE.nml` |
| `box_face_4` | Condiciones de frontera de la cara 4 | Véase `BESLE.nml` |
| `results_file` | Prefijo de los archivos VTK | `'Results'` |
| `fileplace_results` | Carpeta de salida | `'Results/'` |

Los vectores `box_face_2` y `box_face_4` contienen seis entradas alternadas:
`valor_x, tipo_x, valor_y, tipo_y, valor_z, tipo_z`. Un tipo igual a `1`
representa tracción y `0` representa desplazamiento impuesto. Estos campos
deben modificarse con conocimiento del modelo y de sus unidades.

Los perfiles aceptados actualmente son exactamente `ramp`, `Heaviside` y
`harmonic`. Los factores de escala y la densidad deben ser positivos; para un
análisis transitorio, `time_steps` y `dt` también deben ser positivos. Si el
archivo tiene un error de sintaxis o no supera estas validaciones, BESLE detiene
todos los procesos MPI antes de iniciar el cálculo y muestra un mensaje.

## Formato y reproducibilidad

`BESLE.nml` usa el formato estándar Fortran NAMELIST. Los números reales pueden
escribirse con exponente `d`, por ejemplo `5.0d7`. No elimine la línea inicial
`&BESLE_CONFIG` ni la barra `/` final.

Los valores de referencia contienen más cifras que las mostradas usualmente.
Esto es intencional: reproducen exactamente las conversiones numéricas de la
implementación publicada. Para un estudio científico, conserve junto con cada
resultado el archivo `BESLE-used.nml`, la versión del software y el número de
procesos MPI.
