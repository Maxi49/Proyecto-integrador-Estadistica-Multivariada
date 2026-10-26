"""Figuras de todas las técnicas. Ejecutar después de R/ejecutar_todo.R."""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.ticker import MaxNLocator, FuncFormatter, ScalarFormatter
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
T = ROOT / "resultados/tablas"
F = ROOT / "resultados/figuras"
F.mkdir(exist_ok=True)
def leer(n): return pd.read_csv(T / f"{n}.csv")
base = pd.read_excel(ROOT / "muestra_estratificada-simulado-de-ataques.xlsx", sheet_name="muestra")
vars_num = leer("conjuntos_congelados").query('conjunto == "X_num"').variable.tolist()
ABR = ["dur", "spkts", "sbytes", "dbytes", "sinpkt", "sjit", "synack", "srv_src", "srv_dst", "src_ltm", "src_dport", "dst_sport"]
COL = ["#B9D2E5", "#D1C3E0", "#BCD8C5", "#E6C4A7", "#E5BCC8", "#C7D8D4", "#D8D2B1"]
TRAFICO = dict(zip(["Normal", "Exploits", "Fuzzers", "Reconnaissance", "Otros ataques"], COL))
DARK = "#405361"
CMAP = LinearSegmentedColormap.from_list("suave", ["#94B7D2", "#FCFCF9", "#D9A7B5"])
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 13,
    "axes.spines.top": False, "axes.spines.right": False, "axes.titlesize": 13,
    "text.color": DARK, "axes.labelcolor": DARK, "figure.facecolor": "white"})

def coma_decimal(fig):
    """Usar coma decimal en los ejes numéricos, como en el resto del informe."""
    for ax in fig.axes:
        for eje in (ax.xaxis, ax.yaxis):
            if isinstance(eje.get_major_formatter(), ScalarFormatter):
                eje.set_major_formatter(FuncFormatter(lambda v, _: f"{v:g}".replace(".", ",")))

def guardar(fig, nombre):
    coma_decimal(fig)
    fig.savefig(F / f"{nombre}.png", dpi=220, bbox_inches="tight", facecolor="white")
    plt.close(fig)

def origen(ax):
    ax.axhline(0, color="#D0D6DB", lw=.7)
    ax.axvline(0, color="#D0D6DB", lw=.7)

def adjust_text(texts, ax, expand=None, arrowprops=None):
    """Colocar etiquetas sin solaparlas, usando solo Matplotlib."""
    ax.set_autoscale_on(False)
    ax.figure.canvas.draw()
    renderer = ax.figure.canvas.get_renderer()
    inv = ax.transData.inverted()
    ocupados = []
    offsets = sorted([(dx,dy) for dx in [0,-20,20,-45,45,-80,80,-130,130,-180,180] for dy in range(-160,161,14)], key=lambda z:z[0]**2+z[1]**2)
    for text in sorted(texts, key=lambda t:t.get_position()[1]):
        original = text.get_position()
        origen = ax.transData.transform(original)
        mejor = None
        for dx,dy in [(0,0)]+offsets:
            text.set_position(inv.transform(origen + [dx,dy]))
            bb = text.get_window_extent(renderer).expanded(1.12,1.3)
            if bb.x0 < ax.bbox.x0 or bb.x1 > ax.bbox.x1 or bb.y0 < ax.bbox.y0 or bb.y1 > ax.bbox.y1: continue
            if any(bb.overlaps(o) for o in ocupados): continue
            mejor = bb; break
        if mejor is None:
            text.set_position(original)
            mejor = text.get_window_extent(renderer)
        ocupados.append(mejor)
        if np.linalg.norm(ax.transData.transform(text.get_position())-origen)>5:
            ax.plot([original[0],text.get_position()[0]],[original[1],text.get_position()[1]],color="#AAB2B9",linewidth=.45)

def dendrogram(link, ax, labels=None, truncate_mode=None, p=25, orientation="top", **kwargs):
    """Dibujar con Matplotlib el árbol Ward ya calculado en R, sin recalcularlo."""
    n = len(link) + 1
    limite = 2 * n - p if truncate_mode else n
    hojas = []
    def ordenar(node):
        if node < n or node < limite:
            hojas.append(node)
        else:
            ordenar(int(link[node - n, 0])); ordenar(int(link[node - n, 1]))
    ordenar(2 * n - 2)
    posiciones = {node: i for i, node in enumerate(hojas)}
    def trazar(node):
        if node in posiciones: return posiciones[node], 0
        row = link[node - n]
        a, ha = trazar(int(row[0])); b, hb = trazar(int(row[1]))
        xx, yy = [a, a, b, b], [ha, row[2], row[2], hb]
        if orientation == "right": ax.plot(yy, xx, color="#8EA9BE", lw=1)
        else: ax.plot(xx, yy, color="#8EA9BE", lw=1)
        return (a + b) / 2, row[2]
    trazar(2 * n - 2)
    nombres = [(labels[node] if labels else str(node + 1)) if node < n else f"({int(link[node - n, 3])})" for node in hojas]
    if orientation == "right": ax.set_yticks(range(len(hojas)), nombres, fontsize=12)
    else: ax.set_xticks(range(len(hojas)), nombres, fontsize=11)

# Resumen gráfico de datos para el informe; las figuras completas de Etapa 0 se conservan.
fig = plt.figure(figsize=(10, 4.2), layout="constrained")
rejilla = fig.add_gridspec(2, 4, width_ratios=[1, 1, 1.25, 1.25])
axs = np.array([[fig.add_subplot(rejilla[0, 0]), fig.add_subplot(rejilla[0, 1])],
    [fig.add_subplot(rejilla[1, :2]), fig.add_subplot(rejilla[:, 2:])]])
for ax, v, unidad in [(axs[0, 0], "dur", "segundos"), (axs[0, 1], "log_dur", "log(segundos + 1)")]:
    ax.hist(base[v], bins=40, color=COL[0], edgecolor=DARK, lw=.3)
    ax.set(title=v, xlabel=unidad, ylabel="Flujos")
lim = leer("atipicos_limites").set_index("variable")
seleccion = ["log_spkts", "log_sbytes", "log_dbytes"]
stats = []
for v in seleccion:
    r = lim.loc[v]; x = base[v]
    stats.append(dict(label=v.removeprefix("log_"), med=r.mediana, q1=r.q1_tukey,
        q3=r.q3_tukey, whislo=r.bigote_inferior, whishi=r.bigote_superior,
        fliers=x[(x < r.limite_inferior) | (x > r.limite_superior)].to_numpy()))
axs[1, 0].bxp(stats, patch_artist=True, boxprops=dict(facecolor=COL[1], edgecolor=DARK),
    medianprops=dict(color=DARK), flierprops=dict(marker=".", markersize=2, alpha=.2))
axs[1, 0].set(title="Atípicos de volumen", ylabel="log(x + 1)")
corr = leer("correlaciones").set_index("variable")
im = axs[1, 1].imshow(corr, cmap=CMAP, vmin=-1, vmax=1)
axs[1, 1].set_xticks(range(12), ABR, rotation=55, ha="right", fontsize=11)
axs[1, 1].set_yticks(range(12), ABR, fontsize=11)
axs[1, 1].set_title("Correlaciones (12 log_)")
fig.colorbar(im, ax=axs[1, 1], shrink=.7)
guardar(fig, "07_datos_resumen")

# ACP: el biplot usa escalas recíprocas, conservando el producto fila-columna.
eig = leer("acp_autovalores")
scores = leer("acp_puntajes")
r = leer("acp_correlaciones").set_index("variable")
fig, axs = plt.subplots(1, 2, figsize=(9, 3.6), layout="constrained", gridspec_kw={"width_ratios": [1, 1.6]})
axs[0].plot(eig.componente, eig.autovalor, "o-", color="#8AABC5", markeredgecolor=DARK)
axs[0].axhline(1, color=DARK, ls="--", lw=.8)
axs[0].set(title="Codo del ACP", xlabel="Componente", ylabel="Autovalor", xticks=range(1, 13))
ax = axs[1]
sx = np.sqrt(eig.autovalor.iloc[:2].to_numpy())
xy = .5 * scores[["PC1", "PC2"]].to_numpy() / sx
for cat, color in TRAFICO.items():
    sel = scores.tipo_trafico.eq(cat)
    ax.scatter(xy[sel, 0], xy[sel, 1], s=6, color=color, alpha=.4, label=cat, rasterized=True)
texts = []
ax.set_xlim(-2.35, 2.35)
ax.set_ylim(-1.5, 2.1)
for i, v in enumerate(vars_num):
    arrow = 2 * r.loc[v, ["PC1", "PC2"]].to_numpy()
    ax.annotate("", xy=arrow, xytext=(0, 0), arrowprops=dict(arrowstyle="->", color=DARK, lw=.8))
    texts.append(ax.text(arrow[0], arrow[1], ABR[i], fontsize=11))
ext = leer("acp_extremos")
for row in ext.itertuples():
    j = scores.index[scores.id.eq(row.id)][0]
    texts.append(ax.text(*xy[j], str(row.id), fontsize=11, fontweight="bold"))
origen(ax)
pct = eig.porcentaje.iloc[:2].round(2).map(lambda v: f"{v:.2f}".replace(".", ","))
ax.set(title="Biplot de individuos y variables", xlabel=f"CP1 ({pct.iloc[0]}%)", ylabel=f"CP2 ({pct.iloc[1]}%)")
fig.legend(*ax.get_legend_handles_labels(), fontsize=10, loc="outside lower center", ncol=5, markerscale=2)
adjust_text(texts, ax=ax, arrowprops=dict(arrowstyle="-", color="#929BA2", lw=.4))
guardar(fig, "08_acp_codo_biplot")

par = leer("af_paralelo")
fig, ax = plt.subplots(figsize=(9, 2.0), layout="constrained")
ax.plot(par.dimension, par.factor_observado, "o-", color="#8AABC5", label="Factores observados")
ax.plot(par.dimension, par.factor_simulado, "s--", color="#B7A4C9", label="Referencia aleatoria")
ax.axvline(3.5, color=DARK, ls=":", lw=1, label="Factores retenidos (3, Kaiser reducido)")
ax.axvline(4.5, color="#929BA2", ls="--", lw=.8, label="Corte del análisis paralelo (4)")
ax.set(xlabel="Número de factor", ylabel="Autovalor reducido", title="Análisis paralelo de factores · 100 repeticiones", xticks=range(1, 13))
ax.set_ylim(-0.8, 6.2)
ax.legend(fontsize=10, ncol=2, loc="upper right")
guardar(fig, "09_af_paralelo")

def linkage_r(nombre, n):
    d = leer(nombre); counts = np.zeros(n - 1); rows = []
    for i, row in enumerate(d.itertuples()):
        a = -int(row.izquierda) - 1 if row.izquierda < 0 else n + int(row.izquierda) - 1
        b = -int(row.derecha) - 1 if row.derecha < 0 else n + int(row.derecha) - 1
        count = (1 if a < n else counts[a - n]) + (1 if b < n else counts[b - n])
        counts[i] = count
        rows.append([a, b, row.altura, count])
    return np.array(rows)

metricas = leer("cluster_metricas")
k = int(leer("cluster_comparaciones").iloc[0].k)
fig, axs = plt.subplots(1, 2, figsize=(10, 2.8), layout="constrained")
for ax, pref, titulo, ylabel in [(axs[0], "wss", "Codo", "Suma de cuadrados interna"),
    (axs[1], "silhouette", "Silhouette promedio", "Silhouette")]:
    ax.plot(metricas.k, metricas[f"{pref}_ward"], "s--", color="#B7A4C9", label="Ward")
    ax.plot(metricas.k, metricas[f"{pref}_kmeans"], "o-", color="#8AABC5", label="K-means")
    ax.axvline(k, color=DARK, lw=.7, ls=":")
    ax.set(title=titulo, xlabel="k", ylabel=ylabel, xticks=range(2, 9))
    ax.legend(fontsize=12)
guardar(fig, "10_cluster_seleccion")

fig, ax = plt.subplots(figsize=(10, 2.6), layout="constrained")
link = linkage_r("cluster_dendrograma", len(base))
dendrogram(link, truncate_mode="lastp", p=15, ax=ax, link_color_func=lambda _: "#8EA9BE", leaf_font_size=8)
ax.axhline((link[-k, 2] + link[-k + 1, 2]) / 2, color=DARK, ls="--", lw=.8)
ax.set(title="Ward.D2 · últimos 15 nodos del árbol de 5.000 flujos", xlabel="Nodos agregados (tamaño entre paréntesis)", ylabel="Altura")
guardar(fig, "11_cluster_dendrograma")

fig, axs = plt.subplots(1, 2, figsize=(10, 3.8), layout="constrained", gridspec_kw={"width_ratios": [1.35, 1]})
perfil = leer("cluster_medias_estandarizadas").set_index("cluster")
im = axs[0].imshow(perfil, cmap=CMAP, vmin=-3, vmax=3, aspect="auto")
axs[0].set_xticks(range(12), ABR, rotation=55, ha="right", fontsize=11)
axs[0].set_yticks(range(k), [f"C{i}" for i in range(1, k + 1)])
axs[0].set_title("Medias z por cluster")
for i in range(k):
    for j in range(12): axs[0].text(j, i, f"{perfil.iloc[i,j]:.1f}".replace(".", ","), ha="center", va="center", fontsize=12)
fig.colorbar(im, ax=axs[0], shrink=.65, label="z (colores saturan en ±3)")
dendrogram(linkage_r("cluster_dendrograma_variables", 12), labels=ABR, orientation="right",
    ax=axs[1], link_color_func=lambda _: "#8EA9BE", leaf_font_size=9)
axs[1].set(title="Ward de variables", xlabel="Distancia")
guardar(fig, "12_cluster_perfiles_variables")

fig, ax = plt.subplots(figsize=(6.4, 2.6), layout="constrained")  # compacta: va a media página
texts = []
coords_acs = []
for name, color, marker in [("acs_filas", COL[0], "o"), ("acs_columnas", COL[4], "s")]:
    d = leer(name)
    coords_acs.append(d.iloc[:, 1:3].to_numpy())
    ax.scatter(d.iloc[:,1], d.iloc[:,2], color=color, edgecolor=DARK, s=50, marker=marker,
        label="Tipo de tráfico" if name.endswith("filas") else "Estado")
    # Con solo ocho puntos, cada etiqueta se ubica con un desplazamiento fijo
    # (en puntos) para que no tape su marcador ni a sus vecinas.
    lugar = {"Otros ataques": (0, 7, "center"), "INT": (0, -13, "center"),
             "Fuzzers": (0, 7, "center"), "Reconnaissance": (0, -13, "center"),
             "FIN": (8, 0, "left"), "Exploits": (8, 0, "left"),
             "Normal": (8, 0, "left"), "CON_otros": (0, -13, "center")}
    for _, row in d.iterrows():
        dx, dy, ha = lugar.get(row.iloc[0], (6, 6, "left"))
        ax.annotate(row.iloc[0], (row.iloc[1], row.iloc[2]), xytext=(dx, dy),
                    textcoords="offset points", ha=ha, va="center", fontsize=11)
coords_acs = np.vstack(coords_acs)
ax.set_xlim(coords_acs[:, 0].min() - .25, coords_acs[:, 0].max() + .25)
ax.set_ylim(coords_acs[:, 1].min() - .2, coords_acs[:, 1].max() + .2)
origen(ax)
ax.set(xlabel="Dimensión 1", ylabel="Dimensión 2", title="ACS · tipo de tráfico y estado")
ax.legend(fontsize=10, loc="upper center", bbox_to_anchor=(0.42, 1), ncol=2)
guardar(fig, "13_acs_mapa")

e = leer("acm_autovalores")
fig, axs = plt.subplots(1, 2, figsize=(10, 2.1), layout="constrained")
axs[0].plot(e.dimension, e.autovalor, "o-", color="#8AABC5")
axs[0].axhline(1/leer("acm_resumen").Q.iloc[0], color=DARK, ls="--", lw=.8)
axs[0].set(title="Autovalores crudos del ACM", xlabel="Dimensión", ylabel="Autovalor")
axs[0].xaxis.set_major_locator(MaxNLocator(integer=True))
axs[1].bar(e.dimension.iloc[:6], e.porcentaje_ajustado.iloc[:6], color=COL[1], edgecolor=DARK, linewidth=.5)
axs[1].set(title="Inercia ajustada (ca::mjca)", xlabel="Dimensión", ylabel="Porcentaje ajustado")
guardar(fig, "14_acm_inercia")

co = leer("acm_categorias_coordenadas")
variables_cat = co.categoria.str.split(":").str[0].unique().tolist()
prefijos = dict(zip(variables_cat, ["Tr", "Pr", "Sv", "Es", "Rp", "Du", "By"]))
marcas = ["o", "s", "^", "D", "v", "P", "X"]
fig, ax = plt.subplots(figsize=(9, 4.9), layout="constrained")
texts = []
for i, var in enumerate(variables_cat):
    d = co[co.categoria.str.startswith(var + ":")]
    ax.scatter(d["Dim.1"], d["Dim.2"], color=COL[i], edgecolor=DARK, linewidth=.6,
        marker=marcas[i], s=45, label=f"{prefijos[var]}: {var}")
    for row in d.itertuples(index=False, name=None):
        lab = row[0].split(":", 1)[1].replace("Otros ataques", "Otros at.").replace("Reconnaissance", "Recon.")
        texts.append(ax.text(row[1], row[2], prefijos[var] + ":" + lab, fontsize=12))
ax.margins(.22)
origen(ax)
ax.set(title="ACM · categorías activas", xlabel="Dimensión 1 · 27,42% cruda", ylabel="Dimensión 2 · 14,03% cruda")
fig.supxlabel("Tr tráfico · Pr protocolo · Sv servicio · Es estado · Rp respuesta · Du duración · By bytes", fontsize=10)
adjust_text(texts, ax=ax, expand=(1.1, 1.2), arrowprops=dict(arrowstyle="-", color="#AAB2B9", lw=.5))
guardar(fig, "15_acm_categorias")

fig, axs = plt.subplots(1, 2, figsize=(10, 3.5), layout="constrained")
ind = leer("acm_individuos")
su = leer("acm_cluster_suplementario")
for i in range(1, k + 1):
    d = ind[ind.cluster.eq(i)]
    axs[0].scatter(d["Dim.1"], d["Dim.2"], s=5, alpha=.15, color=COL[i - 1], rasterized=True)
    r = su[su.cluster.eq(i)].iloc[0]
    axs[0].scatter(r["Dim.1"], r["Dim.2"], color=COL[i - 1], edgecolor=DARK, marker="D", s=65)
    axs[0].annotate(f"C{i}", (r["Dim.1"], r["Dim.2"]), xytext=(5, 4), textcoords="offset points", fontsize=12)
origen(axs[0])
axs[0].set(title="Clusters suplementarios", xlabel="Dimensión 1", ylabel="Dimensión 2")
eta = leer("acm_eta2")
y = np.arange(len(eta))
axs[1].barh(y - .18, eta["Dim.1"], height=.35, color=COL[0], edgecolor=DARK, lw=.4, label="Dim 1")
axs[1].barh(y + .18, eta["Dim.2"], height=.35, color=COL[1], edgecolor=DARK, lw=.4, label="Dim 2")
axs[1].set_yticks(y, eta.variable, fontsize=12)
axs[1].set(xlim=(0, 1), xlabel="eta²", title="Discriminación por variable")
axs[1].legend(fontsize=12)
guardar(fig, "16_acm_clusters_eta")
print("Figuras 07 a 16 generadas con Matplotlib.")
