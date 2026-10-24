"""Gráficos pastel de Matplotlib y capítulo Datos a partir de resultados de R.

Ejecutar desde cualquier carpeta: python python/graficos_etapa0.py.
Requiere que R/00_datos.R haya producido los CSV. No modifica el Excel.
"""
from pathlib import Path
import hashlib
import json
import platform
import sys

import matplotlib
matplotlib.use("Agg")  # Exportación reproducible: no abre ventanas ni requiere pantalla.
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.ticker import MaxNLocator
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "resultados" / "tablas"
FIGURES = ROOT / "resultados" / "figuras"
FIGURES.mkdir(parents=True, exist_ok=True)
DOCS = ROOT / "docs"
DOCS.mkdir(exist_ok=True)

def read(name):
    return pd.read_csv(TABLES / f"{name}.csv")

base = pd.read_csv(ROOT / "datos" / "base_limpia.csv")
diccionario = read("diccionario_variables")
conjuntos = read("conjuntos_congelados")
variables = conjuntos.loc[conjuntos.conjunto.eq("X_num"), "variable"].tolist()
crudas = [v.removeprefix("log_") for v in variables]
limites = read("atipicos_limites").set_index("variable")
frecuencias = read("frecuencias_X_cat")
correlaciones = read("correlaciones").set_index("variable")
msa = read("msa_por_variable")
piloto = read("piloto_supuestos").iloc[0]

plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10,
    "axes.titlesize": 11, "axes.labelsize": 10, "figure.facecolor": "white",
    "axes.facecolor": "white", "axes.spines.top": False, "axes.spines.right": False,
    "text.color": "#283C49", "axes.labelcolor": "#283C49",
    "xtick.color": "#465761", "ytick.color": "#465761"})
PASTEL = ["#C7DCEB", "#D7CCE8", "#CDE2D3", "#F0D4BE", "#EBCDD5"]
EDGE = "#556874"

def guardar(fig, name):
    fig.savefig(FIGURES / f"{name}.png", dpi=200, bbox_inches="tight", facecolor="white")
    plt.close(fig)

def ejes_panel():
    return plt.subplots(3, 4, figsize=(15, 11), layout="constrained")

def nota(fig, texto):
    fig.supxlabel(texto, fontsize=9, color="#465761")

# Se usan las bisagras calculadas por R; bxp evita diferencias de cuartiles por empates.
fig, axes = ejes_panel()
for i, (ax, v) in enumerate(zip(axes.flat, variables)):
    row = limites.loc[v]
    x = base[v].to_numpy()
    extremos = x[(x < row.limite_inferior) | (x > row.limite_superior)]
    stats = {"med": row.mediana, "q1": row.q1_tukey, "q3": row.q3_tukey,
        "whislo": row.bigote_inferior, "whishi": row.bigote_superior, "fliers": extremos}
    ax.bxp([stats], positions=[1], widths=.45, patch_artist=True, manage_ticks=False,
        boxprops={"facecolor": PASTEL[i // 4], "edgecolor": EDGE},
        medianprops={"color": "#283C49", "linewidth": 1.5},
        whiskerprops={"color": EDGE}, capprops={"color": EDGE},
        flierprops={"marker": ".", "markersize": 3, "alpha": .28,
                    "markeredgecolor": EDGE, "markerfacecolor": EDGE})
    ax.set_title(f"{v}\n{int(row.n_atipicos):,} atípicos".replace(",", "."))
    ax.set_xticks([])
    ax.set_ylabel("log(x + 1)")
    ax.grid(axis="y", color="#E5E9EC", linewidth=.5)
fig.suptitle("Control de atípicos · 12 variables seleccionadas", fontsize=17)
nota(fig, "5.000 flujos · bisagras de Tukey ± 1,5 RIC · escalas independientes · se conservan todos los registros")
guardar(fig, "01_boxplots")

# Histogramas: todos los datos, sin recortar colas; bins FD con tope visual de 80.
def histogramas(lista, nombre, titulo, escala):
    fig, axes = ejes_panel()
    for i, (ax, v) in enumerate(zip(axes.flat, lista)):
        x = base[v].to_numpy()
        q1, q3 = np.quantile(x, [.25, .75])
        ancho = 2 * (q3 - q1) / np.cbrt(len(x))
        n_bins = int(np.clip(np.ceil(np.ptp(x) / ancho), 10, 80)) if ancho > 0 else 20
        ax.hist(x, bins=n_bins, color=PASTEL[i // 4], edgecolor=EDGE, linewidth=.35)
        unidad = diccionario.set_index("nombre").loc[v, "unidad"]
        ax.set_title(v)
        ax.set_xlabel(unidad.replace(" (ventana", "\n(ventana"))
        ax.set_ylabel("Flujos")
        ax.xaxis.set_major_locator(MaxNLocator(nbins=4))
        ax.ticklabel_format(axis="x", style="sci", scilimits=(-3, 4), useMathText=True)
        ax.grid(axis="y", color="#E5E9EC", linewidth=.5)
    fig.suptitle(titulo, fontsize=17)
    nota(fig, f"5.000 flujos · {escala} · rango completo, sin eliminar extremos · intervalos FD limitados a 10–80")
    guardar(fig, nombre)

histogramas(variables, "02_histogramas_log", "Distribuciones de X_num · escala log(x + 1)", "12 variables seleccionadas")
histogramas(crudas, "03_histogramas_crudos", "Distribuciones originales · comparación con la transformación", "12 mediciones originales")

fig, ax = plt.subplots(figsize=(13, 11), layout="constrained")
cmap = LinearSegmentedColormap.from_list("pastel_divergente", ["#9CBAD4", "#FAFAF7", "#DFB0BC"])
im = ax.imshow(correlaciones.to_numpy(), vmin=-1, vmax=1, cmap=cmap)
labels = [v.removeprefix("log_") for v in variables]
ax.set_xticks(range(12), labels, rotation=50, ha="right")
ax.set_yticks(range(12), labels)
for i in range(12):
    for j in range(12):
        ax.text(j, i, f"{correlaciones.iloc[i, j]:.2f}", ha="center", va="center", fontsize=8, color="#283C49")
fig.colorbar(im, ax=ax, shrink=.75, label="Correlación de Pearson (r)")
ax.set_title("Correlaciones entre las 12 variables de X_num", pad=16, fontsize=16)
nota(fig, "5.000 flujos · todas las variables están en escala log(x + 1) · rango de color fijo: −1 a 1")
guardar(fig, "04_correlaciones")

fig, axes = plt.subplots(2, 4, figsize=(17, 9), layout="constrained")
for i, (ax, v) in enumerate(zip(axes.flat, frecuencias.variable.unique())):
    f = frecuencias[frecuencias.variable.eq(v)].sort_values("frecuencia")
    # Mantener el orden natural de las bandas, aunque sus frecuencias sean similares.
    ordenes = {"duracion_banda": ["larga", "media", "corta"],
               "bytes_origen_banda": ["altos", "medios", "bajos"]}
    if v in ordenes:
        f = f.set_index("categoria").loc[ordenes[v]].reset_index()
    ax.barh(f.categoria, f.porcentaje, color=PASTEL[i % len(PASTEL)], edgecolor=EDGE, linewidth=.5)
    ax.set_xlim(0, 100)
    ax.set_xlabel("Porcentaje de flujos")
    ax.set_title(v)
    ax.grid(axis="x", color="#E5E9EC", linewidth=.5)
    for j, row in enumerate(f.itertuples()):
        ax.text(row.porcentaje + 1, j, f"{row.porcentaje:.1f}%".replace(".", ","), va="center", fontsize=9)
axes.flat[-1].axis("off")
fig.suptitle("Frecuencias de X_cat · propuesta operativa para ACM", fontsize=17)
nota(fig, "5.000 flujos · 4 categóricas existentes + 3 numéricas discretizadas · ninguna modalidad por debajo de 5%")
guardar(fig, "05_frecuencias_categoricas")

fig, ax = plt.subplots(figsize=(10, 7), layout="constrained")
f = msa.sort_values("msa")
ax.barh(f.variable, f.msa, color=PASTEL[0], edgecolor=EDGE, linewidth=.5)
ax.axvline(.5, color="#7C5363", linestyle="--", linewidth=1.2, label="Umbral MSA = 0,50")
ax.set_xlim(0, 1)
for i, row in enumerate(f.itertuples()):
    ax.text(row.msa + .01, i, f"{row.msa:.3f}", va="center")
ax.set_xlabel("MSA por variable")
ax.set_title(f"Adecuación por variable · KMO global = {piloto.kmo_global:.3f}", fontsize=15)
ax.legend(loc="lower right")
guardar(fig, "06_msa")

# Validación independiente de R: fórmulas de correlación, KMO/MSA y bisagras de Tukey.
def bisagras_tukey(x):
    x = np.sort(np.asarray(x, dtype=float))
    mitad = len(x) // 2
    return np.median(x[:mitad + len(x) % 2]), np.median(x[mitad:])

R = np.corrcoef(base[variables].to_numpy(), rowvar=False)
np.testing.assert_allclose(R, correlaciones.to_numpy(), rtol=1e-10, atol=1e-10)
inversa = np.linalg.inv(R)
anti = inversa / np.sqrt(np.outer(np.diag(inversa), np.diag(inversa)))
r2 = R ** 2; q2 = anti ** 2
np.fill_diagonal(r2, 0); np.fill_diagonal(q2, 0)
kmo_py = r2.sum() / (r2.sum() + q2.sum())
msa_py = r2.sum(axis=0) / (r2.sum(axis=0) + q2.sum(axis=0))
np.testing.assert_allclose(kmo_py, piloto.kmo_global, rtol=1e-10)
np.testing.assert_allclose(msa_py, msa.set_index("variable").loc[variables, "msa"], rtol=1e-10)
np.testing.assert_allclose(np.linalg.det(R), piloto.determinante, rtol=1e-9)
chi2_py = -(len(base) - 1 - (2 * len(variables) + 5) / 6) * np.log(np.linalg.det(R))
np.testing.assert_allclose(chi2_py, piloto.bartlett_chi2, rtol=1e-9)
flags_py = []
for v in variables:
    q1, q3 = bisagras_tukey(base[v])
    np.testing.assert_allclose([q1, q3], limites.loc[v, ["q1_tukey", "q3_tukey"]].to_numpy(dtype=float))
    flags = (base[v] < q1 - 1.5 * (q3 - q1)) | (base[v] > q3 + 1.5 * (q3 - q1))
    assert flags.sum() == limites.loc[v, "n_atipicos"]
    flags_py.append(flags.to_numpy())
np.testing.assert_array_equal(np.column_stack(flags_py).sum(axis=1), read("atipicos_por_flujo").n_atipicos_revision_12)
assert (frecuencias.groupby("variable").frecuencia.sum() == len(base)).all()
assert base.shape == (5000, 68)
assert not base.drop(columns="id").duplicated().any()
fuente = ROOT / "muestra_estratificada-simulado-de-ataques.xlsx"
manifest = {"archivo": fuente.name, "sha256": hashlib.sha256(fuente.read_bytes()).hexdigest(),
    "filas": len(base), "columnas": len(base.columns), "python": platform.python_version(),
    "pandas": pd.__version__, "numpy": np.__version__, "matplotlib": matplotlib.__version__,
    "validacion_independiente": "Correlación, determinante, KMO, MSA, chi2 Bartlett, Tukey y frecuencias: correctos",
    "advertencia": "La aprobación académica no se infiere de estas pruebas."}
(ROOT / "resultados" / "procedencia_validacion.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

# Capítulo listo para copiar, con tablas y figuras enlazadas a archivos del repositorio.
def num(x, dec=3):
    return f"{float(x):,.{dec}f}".replace(",", "@").replace(".", ",").replace("@", ".")

def mdtabla(df, dec=3):
    def celda(x):
        if pd.isna(x): return "—"
        if isinstance(x, (float, np.floating)): return num(x, dec)
        return str(x).replace("|", "/").replace("\n", " ")
    cab = "| " + " | ".join(str(c) for c in df.columns) + " |"
    sep = "| " + " | ".join("---" for _ in df.columns) + " |"
    return "\n".join([cab, sep] + ["| " + " | ".join(celda(x) for x in row) + " |" for row in df.itertuples(index=False, name=None)])

dimensions = read("dimensiones").iloc[0]
outliers = read("atipicos_resumen")
summary = read("resumen_numerico_seleccion")
freq_attack = read("frecuencias_attack_cat")
cortes = read("cortes_discretizacion")
pares = [(abs(R[i, j]), variables[i], variables[j], R[i, j]) for i in range(12) for j in range(i)]
pares.sort(reverse=True)
texto_pares = "; ".join(f"`{a}`–`{b}` (r = {num(r)})" for _, a, b, r in pares[:3])
doc = f"""# Datos · Etapa 0: exploración y preparación

## Objetivo, pregunta guía e hipótesis

**Objetivo.** Explorar y preparar los flujos de red, identificar patrones de volumen, tiempo y repetición, y establecer una base común para las técnicas multivariadas y la posterior regresión logística.

**Pregunta guía.** ¿Qué patrones del tráfico de red permiten distinguir flujos normales de ataques y estimar su probabilidad mediante regresión logística?

**Hipótesis de trabajo propuestas:**

1. El número de paquetes y los bytes enviados se relacionan positivamente.
2. Existen grupos de flujos con perfiles diferentes de volumen, tiempos y repetición de conexiones.
3. El tipo de tráfico se asocia con el estado de conexión y la presencia de respuesta del destino.

Estas hipótesis se proponen con conocimiento de la exploración previa de la base; no se presentan como hipótesis registradas antes de observar los datos. Su evaluación completa corresponde a las etapas posteriores y una eventual validación independiente.

## Descripción e importación

UNSW-NB15 es un conjunto de tráfico de red generado en el laboratorio de UNSW Canberra, con actividad normal y ataques sintéticos producidos mediante IXIA PerfectStorm. Cada fila representa un flujo de comunicación. La fuente oficial describe nueve clases de ataques además del tráfico normal. [UNSW, descripción oficial](https://research.unsw.edu.au/projects/unsw-nb15-dataset).

Se trabajó con `muestra_estratificada-simulado-de-ataques.xlsx`, hoja `muestra`: **{num(len(base), 0)} flujos y {len(base.columns)} columnas**. La hoja `diccionario` contiene sus definiciones. Según el contexto del proyecto, esta muestra fue obtenida del conjunto de entrenamiento después de la deduplicación y de un muestreo estratificado por `attack_cat`. Esta ejecución parte del Excel recibido; no reconstruye ni verifica de manera independiente ese muestreo anterior.

La importación se realizó en R con `readxl`. Se clasificaron **{int(dimensions.numericas)} variables numéricas y {int(dimensions.categoricas)} categóricas** según su significado, no solamente por su almacenamiento. Identificadores, protocolos, servicios, estados y códigos se trataron como categóricos. “Sin unidad” indica que el valor identifica una categoría o código y no una magnitud física; los conteos y las escalas logarítmicas se detallan en el diccionario.

La variable `label` ya está recodificada en el Excel como `normal` y `ataque`: se observaron **2.408 flujos normales (48,16%) y 2.592 ataques (51,84%)**. En una logística futura podrá codificarse normal = 0 y ataque = 1. Las 68 columnas incluyen variables originales, agrupaciones y transformaciones; no equivalen a 68 predictores independientes.

{mdtabla(freq_attack[['categoria','frecuencia','porcentaje']], 2)}

## Revisión de calidad y decisiones

No se encontraron valores NA ni textos vacíos, ni duplicados completos, identificadores repetidos o perfiles originales duplicados al excluir `id`. No se imputaron valores ni se eliminaron filas.

Se comprobaron valores negativos, no finitos, conteos no enteros, rangos de TTL y ventanas TCP, conteos de contexto superiores a 100, coherencia básica entre paquetes y bytes, indicadores binarios y correspondencia entre `label` y `attack_cat`. Las reglas y sus resultados se registran a continuación; no constituyen una certificación exhaustiva de toda la semántica de red.

{mdtabla(read('calidad_reglas'))}

Se encontró **un caso de `is_ftp_login = 4`, id 97597**, que contradice su definición binaria. Se conserva como código de origen pendiente de revisión, sin recodificarlo ni borrar el flujo. Esta variable queda fuera de X_num y X_cat. Los ceros de variables de respuesta o de tiempos TCP pueden ser estructurales: no se interpretan automáticamente como faltantes. `service = ninguno` también se conserva.

**Atípicos.** Se marcaron valores inferiores a Q1 − 1,5 RIC o superiores a Q3 + 1,5 RIC, con RIC = Q3 − Q1 y Q1/Q3 definidos por las bisagras de Tukey, equivalentes a `fivenum()` de R. Se aplicó el criterio a las 12 variables logarítmicas elegidas. Los cuartiles de la descriptiva usan `quantile(type = 7)` y pueden diferir de las bisagras en datos con empates; las marcas de los boxplots usan siempre Tukey.

La revisión identifica **{int(outliers.iloc[1]['n'])} flujos ({num(outliers.iloc[1].porcentaje,2)}%)** con al menos un valor atípico. La columna previa `n_atipicos` identifica **{int(outliers.iloc[0]['n'])} ({num(outliers.iloc[0].porcentaje,2)}%)**. Se conserva esa columna sin sobrescribirla: representa un control previo cuya definición completa de variables y límites no está documentada. La revisión actual se registra separadamente. Un valor atípico no prueba un ataque y puede reflejar actividad legítima o un artefacto; **se conservan los 5.000 flujos**. Si el RIC es cero, cualquier valor distinto de las bisagras puede quedar señalado.

![Boxplots de las 12 variables](../resultados/figuras/01_boxplots.png)

*Figura 1. Boxplots con límites de Tukey, en escala log(x + 1); escalas verticales independientes. Fuente: elaboración propia con Matplotlib sobre los resultados de R.*

## Descriptiva

Se calcularon tamaño válido, media, desviación estándar muestral, mínimo, cuartiles, mediana, máximo y proporción de ceros para las 47 variables numéricas. La tabla siguiente resume las 12 mediciones originales elegidas; los resultados completos y sus versiones logarítmicas se incluyen en los CSV del repositorio.

{mdtabla(summary[summary.variable.isin(crudas)][['variable','media','desvio','mediana','maximo']], 3)}

![Histogramas originales](../resultados/figuras/03_histogramas_crudos.png)

*Figura 2. Histogramas de las 12 mediciones originales. Se conserva el rango completo, por lo que las colas extremas pueden concentrar visualmente las barras cerca de cero.*

![Histogramas de X_num](../resultados/figuras/02_histogramas_log.png)

*Figura 3. Histogramas de las 12 variables log(x + 1). Los intervalos siguen Freedman–Diaconis con un límite visual de 10 a 80; no se eliminan observaciones.*

En las mediciones originales, la duración media es 1,345 segundos y la mediana 0,297 segundos. Los bytes enviados tienen una media de 16.918,027 y una mediana de 918 bytes. Estas diferencias y las colas de los histogramas muestran que los valores altos afectan a la media, por lo que se interpretan también mediana y cuartiles. Los histogramas permiten comparar la fuerte asimetría de las mediciones originales con su representación logarítmica. La transformación reduce la compresión por valores extremos y conserva los ceros, pero no garantiza normalidad ni elimina todos los valores atípicos.

La matriz de Pearson de X_num muestra asociaciones de volumen, temporización y contexto. Los tres pares con mayor correlación absoluta son: {texto_pares}. Se trata de asociaciones exploratorias, no de relaciones causales ni de una extracción de factores ya realizada.

![Mapa de correlaciones](../resultados/figuras/04_correlaciones.png)

*Figura 4. Correlaciones de Pearson entre las 12 variables transformadas, con escala fija de −1 a 1.*

Se obtuvieron tablas de frecuencias absolutas y porcentuales de las 21 variables clasificadas como categóricas, incluyendo identificadores y códigos. Estas tablas completas no implican que todas sean apropiadas para ACM. Para X_cat se proponen las siguientes modalidades:

{mdtabla(frecuencias, 2)}

![Frecuencias de X_cat](../resultados/figuras/05_frecuencias_categoricas.png)

*Figura 5. Frecuencias de las siete variables propuestas para ACM. Todas las modalidades superan el 5%; no fue necesario volver a agruparlas.*

## Prueba piloto y conjuntos congelados

El piloto se realizó en R con `psych::KMO()` y `psych::cortest.bartlett()`, utilizando la matriz de Pearson de las 12 variables logarítmicas y n = 5.000. El **determinante es {piloto.determinante:.8f}**, superior a 0,00001; el **KMO global es {num(piloto.kmo_global)}**; Bartlett arroja **χ²({int(piloto.bartlett_gl)}) = {num(piloto.bartlett_chi2,2)}, p < 0,001**. El valor p se informa como desigualdad aunque R lo redondee numéricamente a cero. La MSA mínima es {num(piloto.msa_minima)}.

{mdtabla(msa, 3)}

![MSA por variable](../resultados/figuras/06_msa.png)

*Figura 6. MSA por variable y umbral de 0,50.*

Estos indicadores respaldan continuar con ACP y un piloto de AF sin retirar variables del conjunto acordado. No prueban normalidad multivariada, independencia de flujos ni la existencia de un número definitivo de factores. Bartlett es sensible al tamaño de la muestra y sus condiciones inferenciales son aproximadas, en particular porque los conteos de contexto comparten ventanas de conexiones. El determinante se interpreta junto con KMO y MSA, conforme a la consigna. [Documentación KMO](https://personality-project.org/r/psych/help/KMO.html); [Bartlett](https://personality-project.org/r/psych/help/cortest.bartlett.html).

**X_num congelado (decisión previa del grupo):** {', '.join('`'+v+'`' for v in variables)}. Son 12 variables, por encima del mínimo de ocho. Se excluyen `dpkts` y `rate` por la redundancia documentada en el contexto del grupo. Tampoco se incluyen identificadores, TTL, `label`, `attack_cat` ni `tipo_trafico`. La estandarización se aplicará en las técnicas posteriores; los archivos comunes guardan los valores logarítmicos sin estandarizar.

**X_cat congelado para reproducibilidad (propuesta operativa pendiente de revisión grupal):** `tipo_trafico`, `proto_g`, `service_g`, `state_g`, `respuesta_destino`, `duracion_banda` y `bytes_origen_banda`. Las cuatro primeras ya existen; las últimas tres se obtienen de `dpkts`, `dur` y `sbytes` respectivamente, fuera de la hoja original. `respuesta_destino` distingue dpkts = 0 y dpkts > 0. Para duración se usan cortes {num(cortes.iloc[0].corte_1,9)} y {num(cortes.iloc[0].corte_2,9)} segundos; para bytes de origen, {num(cortes.iloc[1].corte_1,6)} y {num(cortes.iloc[1].corte_2,6)} bytes. Los cortes corresponden a los terciles de la muestra (tipo 7), con intervalos cerrados a derecha; los empates pueden producir tamaños distintos de un tercio. Los cortes exactos están guardados para no recalcularlos sobre nuevos datos.

La discretización evita usar la etiqueta de ataque para elegir umbrales. No se incluyen identificadores ni TTL en X_cat. En Etapa 4 se revisará la posible redundancia entre estado y presencia de respuesta, la contribución de protocolos agrupados y el papel activo o suplementario de `tipo_trafico`; cualquier cambio requerirá una versión nueva, no una modificación silenciosa de los archivos congelados. No se han ejecutado ACS, ACM, ACP, AF, clustering ni regresión logística en esta entrega.

## Reproducibilidad y alcance de aprobación

Se fijó `set.seed(42)`. `R/00_datos.R` importa, audita, describe, calcula el piloto, guarda la base común y llama a `python/graficos_etapa0.py`. Todos los gráficos se generaron con Matplotlib, en colores pastel. Se guardaron `datos/base_limpia.rds` y `datos/base_limpia.csv` (5.000 × 68), y `datos/conjuntos_congelados.rds` con los conjuntos y los cortes. La exportación CSV es para intercambio; el RDS conserva los tipos de R. La base original no se altera ni se realiza un nuevo muestreo. Los scripts de las etapas 1 a 4 son plantillas identificadas como pendientes.

Se registraron las versiones de R/Python y los paquetes, la huella del Excel y una comprobación independiente con NumPy de correlaciones, KMO/MSA, Bartlett, bisagras y frecuencias. La base está **preparada para revisión**, con una incidencia FTP documentada fuera de los conjuntos analíticos. La aprobación formal del grupo o la docente queda pendiente; no se afirma que esta automatización la haya otorgado.

## Limitaciones

Los resultados describen una muestra de laboratorio con ataques sintéticos. Según el contexto recibido, se trabaja con perfiles previamente deduplicados y muestreados: las proporciones no son prevalencias operativas de una red real. Las variables de contexto pueden inducir dependencia entre observaciones. Persisten asimetrías, ceros y observaciones extremas aun después de log(x + 1). Las futuras probabilidades logísticas requerirán validación y evaluación de calibración; no se interpretan automáticamente como riesgos reales externos a esta muestra. Las hipótesis y la propuesta X_cat requieren revisión del grupo.

## Anexo: diccionario completo

{mdtabla(diccionario[['nombre','descripcion','unidad','tipo']])}

## Referencias

- Moustafa, N., & Slay, J. (2015). UNSW-NB15: a comprehensive data set for network intrusion detection systems. MilCIS, IEEE. https://doi.org/10.1109/MilCIS.2015.7348942
- Moustafa, N., & Slay, J. (2016). The evaluation of Network Anomaly Detection Systems: Statistical analysis of the UNSW-NB15 dataset and the comparison with the KDD99 dataset. Information Security Journal: A Global Perspective, 25(1–3), 18–31. https://doi.org/10.1080/19393555.2015.1125974
- UNSW. The UNSW-NB15 Dataset. https://research.unsw.edu.au/projects/unsw-nb15-dataset (incluye la lista completa de publicaciones que los autores solicitan citar al utilizar el conjunto).
- Revelle, W. Documentación del paquete psych: KMO y cortest.bartlett, enlaces incluidos en el texto. La versión ejecutada se registra en resultados/sesion_R.txt.
"""
(DOCS / "Datos_informe.md").write_text(doc, encoding="utf-8")
print("Matplotlib: 6 figuras exportadas. Capítulo: docs/Datos_informe.md")
print(manifest["validacion_independiente"])
