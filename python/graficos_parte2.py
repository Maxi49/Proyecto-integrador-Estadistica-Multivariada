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

def fuente(base):
    """Tamaño de letra base (pt) de la figura: textos, ejes, ticks y leyendas."""
    plt.rcParams.update({"font.size": base, "axes.titlesize": base, "axes.labelsize": base,
        "xtick.labelsize": base, "ytick.labelsize": base, "legend.fontsize": base})

def oscurecer(c, f=.3):
    """Mezcla el color con el gris oscuro del repo para ganar contraste sin cambiar el tono."""
    from matplotlib.colors import to_rgb
    return tuple((1 - f) * np.array(to_rgb(c)) + f * np.array(to_rgb(DARK)))

def origen(ax):
    ax.axhline(0, color="#D0D6DB", lw=.7)
    ax.axvline(0, color="#D0D6DB", lw=.7)

def adjust_text(texts, ax, expand=None, arrowprops=None, puntos=None, pad=7):
    """Colocar etiquetas sin solaparlas (solo Matplotlib).

    Búsqueda por descenso de coordenadas: cada etiqueta prueba posiciones en anillos
    alrededor de su punto y se queda con la de menor costo (solapes con otras etiquetas,
    con marcadores y con líneas guía ajenas, más la distancia al punto).
    `puntos`: coordenadas de datos de obstáculos adicionales (cajas de lado 2*pad px).
    """
    ax.set_autoscale_on(False)
    ax.figure.canvas.draw()
    rend = ax.figure.canvas.get_renderer()
    ab = ax.bbox
    anclas = [np.array(ax.transData.transform(t.get_position())) for t in texts]
    obst = np.array(ax.transData.transform(np.asarray(puntos))) if puntos is not None else np.empty((0, 2))
    ang = np.deg2rad(np.arange(0, 360, 15))
    cands = [(0, 0)] + [(r * np.cos(a), r * np.sin(a)) for r in (12, 20, 30, 42, 56, 72, 92, 115, 140) for a in ang]
    def caja(t, i, dx, dy):
        h = "left" if dx > 3 else "right" if dx < -3 else "center"
        v = "bottom" if dy > 3 else "top" if dy < -3 else "center"
        t.set_ha(h); t.set_va(v)
        t.set_position(ax.transData.inverted().transform(anclas[i] + [dx, dy]))
        return t.get_window_extent(rend).expanded(1.06, 1.12)
    def guia(bb, p):
        q = np.array([min(max(p[0], bb.x0), bb.x1), min(max(p[1], bb.y0), bb.y1)])
        return (p, q) if np.hypot(*(q - p)) > 9 else None
    def cruza(a, b, c, d):
        o = lambda p, q, r: (q[0]-p[0])*(r[1]-p[1]) - (q[1]-p[1])*(r[0]-p[0])
        return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0
    def seg_en_caja(g, bb):
        return any(bb.x0 < x < bb.x1 and bb.y0 < y < bb.y1 for x, y in (g[0] + (g[1] - g[0]) * u for u in np.linspace(0, 1, 14)))
    def solape(a, b):
        w = min(a.x1, b.x1) - max(a.x0, b.x0); h = min(a.y1, b.y1) - max(a.y0, b.y0)
        return w * h if w > 0 and h > 0 else 0
    n = len(texts)
    elec = [(0, 0)] * n
    cajas = [caja(t, i, 0, 0) for i, t in enumerate(texts)]
    def costo(i, c):
        bb = caja(texts[i], i, *c)
        if bb.x0 < ab.x0 or bb.x1 > ab.x1 or bb.y0 < ab.y0 or bb.y1 > ab.y1: return 1e9
        k = 3 * np.hypot(*c)
        for j in range(n):
            if j != i: k += 40 * solape(bb, cajas[j])
        for q in np.vstack([obst, np.array(anclas)]) if len(obst) else np.array(anclas):
            k += 80 * solape(bb, type(bb)([[q[0]-pad, q[1]-pad], [q[0]+pad, q[1]+pad]]))
        g = guia(bb, anclas[i])
        if g is not None:
            for j in range(n):
                if j == i: continue
                if seg_en_caja(g, cajas[j]): k += 1500
                gj = guia(cajas[j], anclas[j])
                if gj is not None and cruza(*g, *gj): k += 1500
            for q in obst:
                if seg_en_caja(g, type(bb)([[q[0]-3, q[1]-3], [q[0]+3, q[1]+3]])): k += 150
        return k
    orden = sorted(range(n), key=lambda i: np.sum(np.hypot(*(np.array(anclas) - anclas[i]).T) < 60), reverse=True)
    for _ in range(5):
        for i in orden:
            mejor = min(cands, key=lambda c: costo(i, c))
            elec[i] = mejor; cajas[i] = caja(texts[i], i, *mejor)
    inv = ax.transData.inverted()
    for i, t in enumerate(texts):
        cajas[i] = caja(t, i, *elec[i])
        g = guia(cajas[i], anclas[i])
        if g is not None:
            (x0, y0), (x1, y1) = inv.transform(g[0]), inv.transform(g[1])
            ax.plot([x0, x1], [y0, y1], color="#7F8A92", linewidth=.5, zorder=1)

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
    if orientation == "right": ax.set_yticks(range(len(hojas)), nombres)
    else: ax.set_xticks(range(len(hojas)), nombres)

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
fuente(10.5)  # figura de 7,0 in -> impresa a 13,6 cm (x0,76): letra impresa ~8 pt
fig, axs = plt.subplots(1, 2, figsize=(7.0, 3.1), layout="constrained", gridspec_kw={"width_ratios": [1, 1.7]})
axs[0].plot(eig.componente, eig.autovalor, "o-", color="#8AABC5", markeredgecolor=DARK)
axs[0].axhline(1, color=DARK, ls="--", lw=.8)
axs[0].set(title="Codo del ACP", xlabel="Componente", ylabel="Autovalor", xticks=[1, 2, 3, 4, 6, 8, 10, 12])
ax = axs[1]
sx = np.sqrt(eig.autovalor.iloc[:2].to_numpy())
xy = .5 * scores[["PC1", "PC2"]].to_numpy() / sx
for cat, color in TRAFICO.items():
    sel = scores.tipo_trafico.eq(cat)
    ax.scatter(xy[sel, 0], xy[sel, 1], s=5, color=oscurecer(color, .3), alpha=.6, linewidths=0, label=cat, rasterized=True)
texts = []
ax.set_xlim(-2.35, 2.35)
ax.set_ylim(-1.5, 2.1)
for i, v in enumerate(vars_num):
    arrow = 2 * r.loc[v, ["PC1", "PC2"]].to_numpy()
    ax.annotate("", xy=arrow, xytext=(0, 0), arrowprops=dict(arrowstyle="->", color=DARK, lw=.8))
    texts.append(ax.text(arrow[0], arrow[1], ABR[i], bbox=dict(boxstyle="round,pad=.1", fc="white", ec="none", alpha=.7), zorder=5))
ext = leer("acp_extremos")
for row in ext.itertuples():
    j = scores.index[scores.id.eq(row.id)][0]
    ax.scatter(*xy[j], s=26, facecolor="none", edgecolor=DARK, linewidth=.9, zorder=4)
    texts.append(ax.text(*xy[j], str(row.id), fontweight="bold", bbox=dict(boxstyle="round,pad=.12", fc="white", ec="none", alpha=.8)))
origen(ax)
pct = eig.porcentaje.iloc[:2].round(2).map(lambda v: f"{v:.2f}".replace(".", ","))
ax.set(title="Biplot de individuos y variables", xlabel=f"CP1 ({pct.iloc[0]}%)", ylabel=f"CP2 ({pct.iloc[1]}%)")
from matplotlib.lines import Line2D
handles = [Line2D([], [], marker="o", ls="", markersize=7, markerfacecolor=oscurecer(c, .3), markeredgecolor=DARK, markeredgewidth=.5) for c in TRAFICO.values()]
fig.legend(handles, list(TRAFICO), loc="outside lower center", ncol=5, columnspacing=1.0, handletextpad=.2)
adjust_text(texts, ax=ax, arrowprops=dict(arrowstyle="-", color="#929BA2", lw=.4),
    puntos=np.vstack([u * 2 * r.loc[v, ["PC1", "PC2"]].to_numpy() for v in vars_num for u in np.linspace(.15, 1, 40)]
        + [xy[scores.index[scores.id.eq(i)][0]][None] for i in ext.id]), pad=3)
guardar(fig, "08_acp_codo_biplot")

par = leer("af_paralelo")
fuente(10)  # 6,5 in -> 13,6 cm (x0,82): ~8,2 pt
fig, ax = plt.subplots(figsize=(6.5, 2.3), layout="constrained")
ax.plot(par.dimension, par.factor_observado, "o-", color="#8AABC5", label="Factores observados")
ax.plot(par.dimension, par.factor_simulado, "s--", color="#B7A4C9", label="Referencia aleatoria")
ax.axvline(3.5, color=DARK, ls=":", lw=1, label="Factores retenidos (3, Kaiser reducido)")
ax.axvline(4.5, color="#929BA2", ls="--", lw=.8, label="Corte del análisis paralelo (4)")
ax.set(xlabel="Número de factor", ylabel="Autovalor reducido", title="Análisis paralelo · 100 repeticiones", xticks=range(1, 13))
ax.set_ylim(-0.8, 7.6)
ax.legend(ncol=2, loc="upper right", columnspacing=1.0, handlelength=1.6)
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
fuente(10.5)  # 6,5 in -> 12,8 cm (x0,775): ~8,1 pt
fig, axs = plt.subplots(1, 2, figsize=(6.5, 2.0), layout="constrained")
for ax, pref, titulo, ylabel in [(axs[0], "wss", "Codo", "Suma de cuadrados interna"),
    (axs[1], "silhouette", "Silhouette promedio", "Silhouette")]:
    ax.plot(metricas.k, metricas[f"{pref}_ward"], "s--", color="#B7A4C9", label="Ward")
    ax.plot(metricas.k, metricas[f"{pref}_kmeans"], "o-", color="#8AABC5", label="K-means")
    ax.axvline(k, color=DARK, lw=.7, ls=":")
    ax.set(title=titulo, xlabel="k", ylabel=ylabel, xticks=range(2, 9))
    ax.legend()
guardar(fig, "10_cluster_seleccion")

fuente(13)
fig, ax = plt.subplots(figsize=(10, 2.6), layout="constrained")
link = linkage_r("cluster_dendrograma", len(base))
dendrogram(link, truncate_mode="lastp", p=15, ax=ax, link_color_func=lambda _: "#8EA9BE", leaf_font_size=8)
ax.axhline((link[-k, 2] + link[-k + 1, 2]) / 2, color=DARK, ls="--", lw=.8)
ax.set(title="Ward.D2 · últimos 15 nodos del árbol de 5.000 flujos", xlabel="Nodos agregados (tamaño entre paréntesis)", ylabel="Altura")
guardar(fig, "11_cluster_dendrograma")

fuente(10.5)  # 7,4 in -> 14,1 cm (x0,75): ~7,9 pt
fig, axs = plt.subplots(1, 2, figsize=(7.4, 2.9), layout="constrained", gridspec_kw={"width_ratios": [1.45, 1]})
perfil = leer("cluster_medias_estandarizadas").set_index("cluster")
im = axs[0].imshow(perfil, cmap=CMAP, vmin=-3, vmax=3, aspect="auto")
axs[0].set_xticks(range(12), ABR, rotation=55, ha="right")
axs[0].set_yticks(range(k), [f"C{i}" for i in range(1, k + 1)])
axs[0].set_title("Medias z por cluster")
for i in range(k):
    for j in range(12): axs[0].text(j, i, f"{perfil.iloc[i,j]:.1f}".replace(".", ","), ha="center", va="center", fontsize=10)
fig.colorbar(im, ax=axs[0], shrink=.65, label="z (colores saturan en ±3)")
dendrogram(linkage_r("cluster_dendrograma_variables", 12), labels=ABR, orientation="right",
    ax=axs[1], link_color_func=lambda _: "#8EA9BE", leaf_font_size=10)
axs[1].set(title="Ward de variables", xlabel="Distancia")
guardar(fig, "12_cluster_perfiles_variables")

fuente(11.5)  # 5,2 in -> 8,8 cm (x0,67): ~7,7 pt
fig, ax = plt.subplots(figsize=(5.2, 2.15), layout="constrained")  # compacta: va a media página
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
                    textcoords="offset points", ha=ha, va="center")
coords_acs = np.vstack(coords_acs)
ax.set_xlim(coords_acs[:, 0].min() - .25, coords_acs[:, 0].max() + .25)
ax.set_ylim(coords_acs[:, 1].min() - .2, coords_acs[:, 1].max() + .2)
origen(ax)
ax.set(xlabel="Dimensión 1", ylabel="Dimensión 2", title="ACS · tipo de tráfico y estado")
ax.legend(loc="upper center", bbox_to_anchor=(0.42, 1), ncol=2, columnspacing=1.0, handletextpad=.2)
guardar(fig, "13_acs_mapa")

e = leer("acm_autovalores")
fuente(10)  # 6,5 in -> ~13,6 cm (x0,82): ~8,2 pt
fig, axs = plt.subplots(1, 2, figsize=(6.5, 1.9), layout="constrained")
axs[0].plot(e.dimension, e.autovalor, "o-", color="#8AABC5")
axs[0].axhline(1/leer("acm_resumen").Q.iloc[0], color=DARK, ls="--", lw=.8)
axs[0].set(title="Autovalores crudos", xlabel="Dimensión", ylabel="Autovalor")
axs[0].xaxis.set_major_locator(MaxNLocator(integer=True))
axs[1].bar(e.dimension.iloc[:6], e.porcentaje_ajustado.iloc[:6], color=COL[1], edgecolor=DARK, linewidth=.5)
axs[1].set(title="Inercia ajustada", xlabel="Dimensión", ylabel="Porcentaje")
guardar(fig, "14_acm_inercia")

co = leer("acm_categorias_coordenadas")
variables_cat = co.categoria.str.split(":").str[0].unique().tolist()
prefijos = dict(zip(variables_cat, ["Tr", "Pr", "Sv", "Es", "Rp", "Du", "By"]))
marcas = ["o", "s", "^", "D", "v", "P", "X"]
fuente(11.5)  # 6,5 in -> 10,9 cm (x0,66): ~7,6 pt
fig, ax = plt.subplots(figsize=(6.5, 3.9), layout="constrained")
texts = []
for i, var in enumerate(variables_cat):
    d = co[co.categoria.str.startswith(var + ":")]
    ax.scatter(d["Dim.1"], d["Dim.2"], color=COL[i], edgecolor=DARK, linewidth=.6,
        marker=marcas[i], s=45, label=f"{prefijos[var]}: {var}")
    for row in d.itertuples(index=False, name=None):
        lab = row[0].split(":", 1)[1].replace("Otros ataques", "Otros at.").replace("Reconnaissance", "Recon.")
        texts.append(ax.text(row[1], row[2], prefijos[var] + ":" + lab))
ax.margins(.22)
origen(ax)
ax.set(title="ACM · categorías activas", xlabel="Dimensión 1 · 27,42% cruda", ylabel="Dimensión 2 · 14,03% cruda")
fig.supxlabel("Tr tráfico · Pr protocolo · Sv servicio · Es estado · Rp respuesta · Du duración · By bytes", fontsize=11.5)
adjust_text(texts, ax=ax, expand=(1.1, 1.2), arrowprops=dict(arrowstyle="-", color="#AAB2B9", lw=.5),
    puntos=co[["Dim.1", "Dim.2"]].to_numpy(), pad=6)
guardar(fig, "15_acm_categorias")

fuente(10)  # 6,5 in -> ~13,6 cm (x0,82): ~8,2 pt
fig, axs = plt.subplots(1, 2, figsize=(6.5, 2.6), layout="constrained")
ind = leer("acm_individuos")
su = leer("acm_cluster_suplementario")
for i in range(1, k + 1):
    d = ind[ind.cluster.eq(i)]
    axs[0].scatter(d["Dim.1"], d["Dim.2"], s=5, alpha=.15, color=COL[i - 1], rasterized=True)
    r = su[su.cluster.eq(i)].iloc[0]
    axs[0].scatter(r["Dim.1"], r["Dim.2"], color=COL[i - 1], edgecolor=DARK, marker="D", s=65)
    axs[0].annotate(f"C{i}", (r["Dim.1"], r["Dim.2"]), xytext=(5, 4), textcoords="offset points")
origen(axs[0])
axs[0].set(title="Clusters suplementarios", xlabel="Dimensión 1", ylabel="Dimensión 2")
eta = leer("acm_eta2")
y = np.arange(len(eta))
axs[1].barh(y - .18, eta["Dim.1"], height=.35, color=COL[0], edgecolor=DARK, lw=.4, label="Dim 1")
axs[1].barh(y + .18, eta["Dim.2"], height=.35, color=COL[1], edgecolor=DARK, lw=.4, label="Dim 2")
axs[1].set_yticks(y, eta.variable)
axs[1].set(xlim=(0, 1), xlabel="eta²", title="Discriminación por variable")
axs[1].legend()
guardar(fig, "16_acm_clusters_eta")
print("Figuras 07 a 16 generadas con Matplotlib.")
