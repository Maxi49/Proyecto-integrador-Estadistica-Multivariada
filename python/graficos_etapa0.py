"""Gráficos pastel de la Etapa 0. Ejecutar después de R/00_datos.R."""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # Exportación reproducible: no abre ventanas ni requiere pantalla.
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.ticker import MaxNLocator, FuncFormatter, ScalarFormatter
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "resultados" / "tablas"
FIGURES = ROOT / "resultados" / "figuras"
FIGURES.mkdir(parents=True, exist_ok=True)

def read(name):
    return pd.read_csv(TABLES / f"{name}.csv")

base = pd.read_excel(ROOT / "muestra_estratificada-simulado-de-ataques.xlsx", sheet_name="muestra")
diccionario = read("diccionario_variables")
conjuntos = read("conjuntos_congelados")
variables = conjuntos.loc[conjuntos.conjunto.eq("X_num"), "variable"].tolist()
crudas = [v.removeprefix("log_") for v in variables]
crudas.insert(2, "dpkts")  # Se describe la respuesta del destino, aunque no entra en X_num.
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

def coma_decimal(fig):
    """Usar coma decimal en los ejes numéricos, como en el resto del informe."""
    for ax in fig.axes:
        for eje in (ax.xaxis, ax.yaxis):
            if isinstance(eje.get_major_formatter(), ScalarFormatter):
                eje.set_major_formatter(FuncFormatter(lambda v, _: f"{v:g}".replace(".", ",")))

def guardar(fig, name):
    coma_decimal(fig)
    fig.savefig(FIGURES / f"{name}.png", dpi=200, bbox_inches="tight", facecolor="white")
    plt.close(fig)

def ejes_panel(cantidad=12):
    filas = (cantidad + 3) // 4
    return plt.subplots(filas, 4, figsize=(15, filas * 3.7), layout="constrained")

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
    fig, axes = ejes_panel(len(lista))
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
    for ax in axes.flat[len(lista):]:
        ax.axis("off")
    fig.suptitle(titulo, fontsize=17)
    nota(fig, f"5.000 flujos · {escala} · rango completo, sin eliminar extremos · intervalos FD limitados a 10–80")
    guardar(fig, nombre)

histogramas(variables, "02_histogramas_log", "Distribuciones de X_num · escala log(x + 1)", "12 variables seleccionadas")
histogramas(crudas, "03_histogramas_crudos", "Distribuciones originales · comparación con la transformación", "13 mediciones originales, incluido dpkts")

fig, ax = plt.subplots(figsize=(13, 11), layout="constrained")
cmap = LinearSegmentedColormap.from_list("pastel_divergente", ["#9CBAD4", "#FAFAF7", "#DFB0BC"])
im = ax.imshow(correlaciones.to_numpy(), vmin=-1, vmax=1, cmap=cmap)
labels = [v.removeprefix("log_") for v in variables]
ax.set_xticks(range(12), labels, rotation=50, ha="right")
ax.set_yticks(range(12), labels)
for i in range(12):
    for j in range(12):
        ax.text(j, i, f"{correlaciones.iloc[i, j]:.2f}".replace(".", ","), ha="center", va="center", fontsize=8, color="#283C49")
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
    ax.text(row.msa + .01, i, f"{row.msa:.3f}".replace(".", ","), va="center")
ax.set_xlabel("MSA por variable")
ax.set_title(f"Adecuación por variable · KMO global = {piloto.kmo_global:.3f}".replace(".", ","), fontsize=15)
ax.legend(loc="lower right")
guardar(fig, "06_msa")


print("Se guardaron las seis figuras en resultados/figuras.")
