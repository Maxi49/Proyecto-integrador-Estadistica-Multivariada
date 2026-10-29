"""Figuras 17 y 18 de la regresión logística. Ejecutar después de R/06_logistica.R."""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.ticker import FuncFormatter, ScalarFormatter
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
T = ROOT / "resultados/tablas"
F = ROOT / "resultados/figuras"
F.mkdir(exist_ok=True)
def leer(n): return pd.read_csv(T / f"log_reg_{n}.csv")

# Mismo estilo que graficos_parte2.py
COL = ["#B9D2E5", "#D1C3E0", "#BCD8C5", "#E6C4A7", "#E5BCC8", "#C7D8D4", "#D8D2B1"]
DARK = "#405361"
CMAP = LinearSegmentedColormap.from_list("suave", ["#FCFCF9", "#94B7D2"])
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

roc = leer("roc_curva")
auc = leer("auc").iloc[0]
conf = leer("confusion")
met = leer("metricas").iloc[0]

# Figura 17: ROC en prueba + matriz de confusión (umbral 0,5)
# Tamaño compacto: en el informe va a 0,6 del ancho de texto (9,6 cm); con esta
# figura de 13,2 cm la letra impresa queda en unos 7,5 pt.
plt.rcParams.update({"font.size": 10.5})
fig, axs = plt.subplots(1, 2, figsize=(5.2, 2.3), layout="constrained")
ax = axs[0]
ax.plot([0, 1], [0, 1], ls="--", color="#AAB2B9", lw=1, label="Azar (AUC = 0,500)")
ax.plot(roc.fpr, roc.tpr, color="#6F9BBC", lw=2.2,
        label=f"Modelo (AUC = {auc.AUC:.3f})".replace(".", ","))
ax.fill_between(roc.fpr, roc.tpr, alpha=.15, color=COL[0])
punto = (1 - met.especificidad, met.sensibilidad)
ax.scatter(*punto, s=30, color="#D9A7B5", edgecolor=DARK, zorder=3, label="Umbral 0,5")
ax.set(xlabel="1 − especificidad", ylabel="Sensibilidad",
       xlim=(0, 1), ylim=(0, 1.01), aspect="equal")
# Sin leyenda (no entra a este tamaño): el AUC va rotulado y el epígrafe del
# informe explica la diagonal de azar y el punto del umbral 0,5.
ax.text(.97, .05, f"AUC = {auc.AUC:.3f}".replace(".", ","), transform=ax.transAxes,
        ha="right", va="bottom", fontsize=10.5, color=DARK, fontweight="bold")
ax.annotate("umbral 0,5", punto, xytext=(8, -12), textcoords="offset points", fontsize=9.5, color=DARK)

ax = axs[1]
m = np.array([[conf.query('real=="normal" and predicho=="normal"').n.iloc[0],
               conf.query('real=="normal" and predicho=="ataque"').n.iloc[0]],
              [conf.query('real=="ataque" and predicho=="normal"').n.iloc[0],
               conf.query('real=="ataque" and predicho=="ataque"').n.iloc[0]]])
pct = m / m.sum(axis=1, keepdims=True)
ax.imshow(pct, cmap=CMAP, vmin=0, vmax=1)
for i in range(2):
    for j in range(2):
        ax.text(j, i, f"{m[i, j]}\n({100 * pct[i, j]:.1f}%)".replace(".", ","), ha="center", va="center",
                fontsize=11, color=DARK, fontweight="bold" if i == j else "normal")
ax.set_xticks([0, 1], ["Normal", "Ataque"])
ax.set_yticks([0, 1], ["Normal", "Ataque"])
ax.set(xlabel="Clase predicha", ylabel="Clase real")
for s in ax.spines.values():
    s.set_visible(False)
ax.tick_params(length=0)
guardar(fig, "17_logistica_roc_confusion")
plt.rcParams.update({"font.size": 13})

# Figura 18: forest plot de OR (escala log) + calibración por deciles
co = leer("coeficientes").set_index("termino")
orx = leer("or_por_desvio").set_index("termino")
nombres = {"PC1": "CP1 (por desvío)", "PC2": "CP2 (por desvío)", "PC3": "CP3 (por desvío)",
           "proto_gudp": "Protocolo: udp (vs tcp)", "proto_gotros": "Protocolo: otros (vs tcp)",
           "service_gdns": "Servicio: dns (vs ninguno)", "service_ghttp": "Servicio: http (vs ninguno)",
           "service_gotros": "Servicio: otros (vs ninguno)",
           "state_gCON_otros": "Estado: CON_otros (vs FIN)", "state_gINT": "Estado: INT (vs FIN)"}
filas = []
for t in nombres:
    if t not in co.index: continue
    if t in orx.index:
        r = orx.loc[t]; filas.append((nombres[t], r.OR_por_desvio, r.OR_desvio_IC95_inf, r.OR_desvio_IC95_sup, t))
    else:
        r = co.loc[t]; filas.append((nombres[t], r.OR, r.OR_IC95_inf, r.OR_IC95_sup, t))
filas = filas[::-1]
fig, axs = plt.subplots(1, 2, figsize=(10.5, 4.6), layout="constrained", gridspec_kw={"width_ratios": [1.25, 1]})
ax = axs[0]
y = np.arange(len(filas))
for i, (n, o, lo, hi, t) in enumerate(filas):
    color = "#6F9BBC" if t.startswith("PC") else "#C9899B"
    ax.plot([lo, hi], [i, i], color=color, lw=2)
    ax.scatter(o, i, color=color, edgecolor=DARK, s=40, zorder=3)
ax.axvline(1, color=DARK, lw=.9, ls="--")
ax.set_xscale("log")
ax.set_xticks([.05, .2, 1, 5, 20, 100, 400], ["0,05", "0,2", "1", "5", "20", "100", "400"])
ax.minorticks_off()
ax.set_yticks(y, [f[0] for f in filas], fontsize=11)
ax.set(xlabel="Odds ratio e IC 95 % (escala log)")

ax = axs[1]
cal = leer("calibracion")
ax.plot([0, 1], [0, 1], ls="--", color="#AAB2B9", lw=1, label="Calibración perfecta")
ax.plot(cal.p_media, cal.prop_observada, "o-", color="#6F9BBC", markeredgecolor=DARK, label="Deciles en prueba")
ax.set(xlabel="Probabilidad media predicha", ylabel="Proporción observada de ataques",
       xlim=(0, 1), ylim=(0, 1.02), aspect="equal")
ax.legend(loc="upper left", fontsize=11, frameon=False)
guardar(fig, "18_logistica_or_calibracion")
print("Figuras 17 y 18 generadas con Matplotlib.")
