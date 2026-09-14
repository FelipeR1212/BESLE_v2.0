# Configuración de simulaciones sin recompilar

BESLE puede leer los parámetros que antes estaban escritos dentro de
`src/Set_parameters.f90` desde el archivo externo `BESLE.nml`. El ejecutable se
compila una sola vez: después se puede editar el archivo, guardarlo y ejecutar
de nuevo la simulación sin recompilar Fortran.

## Uso en Windows

1. Abra BESLE desde el acceso directo y cree una simulación nueva.
2. Entre a la carpeta del proyecto indicada al terminar la ejecución.
3. Abra `BESLE.nml`, preferiblemente mediante
   `edit-BESLE-parameters.cmd`.
4. Cambie únicamente los valores necesarios y guarde el archivo.
5. Ejecute `run-this-simulation.cmd` dentro de la misma carpeta.

En cada repetición, los resultados y el registro anteriores se trasladan a una
subcarpeta fechada dentro de `history`. La configuración realmente utilizada se
guarda como `BESLE-used.nml`, lo cual permite reproducir y documentar cada caso.

Los proyectos se crean de forma predeterminada en
`Documentos\BESLE\2.1.0\runs`; nunca se modifican los archivos instalados bajo
`Program Files`.

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

## Parámetros disponibles

| Parámetro | Función | Valor de referencia |
|---|---|---:|
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
