# Proyecto integrador · Estadística Multivariada

Etapa 0 sobre UNSW-NB15: 5.000 flujos, 68 columnas. R realiza los cálculos y
Python/Matplotlib genera los gráficos pastel. La muestra Excel recibida se conserva.

## Qué revisar y entregar

- [Capítulo Datos, listo para copiar](docs/Datos_informe.md): pregunta, objetivo,
  hipótesis propuestas, calidad, descriptiva, piloto, tablas, seis figuras y diccionario completo.
- [Gráficos PNG](resultados/figuras): se insertan directamente en el informe; no hace falta fotografiar la pantalla.
- [Base compartida CSV](datos/base_limpia.csv): intercambio con la docente.
- [Base compartida RDS](datos/base_limpia.rds): conserva tipos para trabajar en R.
- [Diccionario](resultados/tablas/diccionario_variables.csv) y
  [decisiones de calidad](resultados/tablas/decisiones_calidad.csv).
- [Script de Etapa 0](R/00_datos.R) y [gráficos Matplotlib](python/graficos_etapa0.py).
- [Revisión de decisiones](docs/DECISIONES_ETAPA0.md): distingue acuerdos previos,
  propuesta X_cat y aprobación académica pendiente.

## Preparar el entorno (una sola vez)

Abrir **esta carpeta del repositorio** en VS Code/RStudio y usarla como directorio de trabajo.
En la consola de R:

```r
install.packages(c("readxl", "psych"), repos = "https://cloud.r-project.org")
```

En una terminal PowerShell, desde la raíz del repositorio:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

No se necesita activar el entorno: R detecta automáticamente ese ejecutable.
El depurador de VS Code es opcional para ejecutar el análisis.

## Ejecutar todo

Desde la consola de R:

```r
source("R/00_datos.R", encoding = "UTF-8")
```

También se puede ejecutar con Rscript desde una terminal si está disponible en PATH:

```powershell
Rscript --vanilla R/00_datos.R
```

Para elegir otro intérprete, antes de ejecutar el script usar en R
`Sys.setenv(PYTHON_ETAPA0 = "ruta/al/python.exe")`.
Para repetir solamente cálculos R:

```r
Sys.setenv(ETAPA0_GRAFICOS = "0")
source("R/00_datos.R", encoding = "UTF-8")
Sys.unsetenv("ETAPA0_GRAFICOS")
```

Para regenerar solo las figuras y el capítulo a partir de los CSV:

```powershell
.\.venv\Scripts\python.exe python/graficos_etapa0.py
```

## Estructura y orden

```text
muestra_estratificada-simulado-de-ataques.xlsx  # fuente recibida; no se modifica
Consultar Diccionario de Variables.R        # script interactivo previo, conservado
CONTEXTO_PROYECTO.md                         # contexto previo del grupo; fecha 23/10
R/
  00_datos.R                                # etapa completa y reproducible
  01_acp.R                                  # plantilla pendiente
  02_af.R                                   # plantilla pendiente
  03_cluster.R                              # plantilla pendiente
  04_acm.R                                  # plantilla pendiente
python/graficos_etapa0.py                    # seis figuras + capítulo desde resultados R
datos/                                      # base común, X_cat y conjuntos congelados
resultados/tablas/                          # diccionario, controles, resúmenes y piloto
resultados/figuras/                         # PNG pastel de Matplotlib
resultados/sesion_R.txt                      # versiones de R y paquetes
resultados/procedencia_validacion.json       # huella fuente y validación NumPy
docs/Datos_informe.md                        # texto completo con figuras y anexos
docs/DECISIONES_ETAPA0.md                     # alcance de decisiones y pendientes
requirements.txt                            # dependencias Python
```

Las plantillas 01–04 se detienen con un aviso para evitar confundirlas con técnicas
ya ejecutadas. Los histogramas y boxplots corresponden a X_num y sus mediciones
originales; los CSV incluyen resúmenes de las 47 mediciones y frecuencias de las
21 categóricas. Los 68 campos no son 68 predictores.

## Cómo cargar los conjuntos en las etapas siguientes

```r
base <- readRDS("datos/base_limpia.rds")
conjuntos <- readRDS("datos/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
X_cat <- conjuntos$X_cat
# Al aplicar las técnicas: prcomp(X_num, scale. = TRUE), scale(X_num), etc.
```

X_num contiene las 12 log_ decididas por el grupo. X_cat contiene una propuesta
operativa de siete variables: cuatro originales agrupadas y tres discretizaciones.
Los cortes quedan guardados; no recalcularlos sobre datos de prueba. La revisión
del papel activo/suplementario y de redundancias del ACM corresponde a Etapa 4.

## Lectura metodológica

Se conserva la columna n_atipicos original; el control actual de las 12 log_
se guarda por separado. Tukey y quantile tipo 7 no son idénticos cuando hay empates:
las figuras de atípicos usan los límites de Tukey calculados por R.
No se eliminan extremos ni se imputa el código FTP 4.
La huella del Excel y la verificación independiente permiten detectar cambios.

**La base está preparada para revisión, no declarada aprobada por la docente.**
Las hipótesis y X_cat son propuestas documentadas. No se entrenó una logística
ni se ejecutaron ACP, AF, ACS/ACM o clustering.

Fuente oficial: [UNSW-NB15](https://research.unsw.edu.au/projects/unsw-nb15-dataset).
Consultar las referencias y requisitos de citación de los autores.
