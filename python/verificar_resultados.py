"""Comprobación independiente de los resultados de R con NumPy y pandas."""
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
T = ROOT / "resultados/tablas"
def leer(n): return pd.read_csv(T / f"{n}.csv")
base = pd.read_excel(ROOT / "muestra_estratificada-simulado-de-ataques.xlsx", sheet_name="muestra")
assert base.shape == (5000, 68)
variables = leer("conjuntos_congelados").query('conjunto == "X_num"').variable.tolist()
x = base[variables].to_numpy()
z = (x - x.mean(axis=0)) / x.std(axis=0, ddof=1)
R = np.corrcoef(x, rowvar=False)
eig = np.linalg.eigvalsh(R)[::-1]
np.testing.assert_allclose(eig, leer("acp_autovalores").autovalor, atol=1e-12)
np.testing.assert_allclose(R, leer("correlaciones").iloc[:, 1:], atol=1e-12)
inversa = np.linalg.inv(R)
anti = inversa / np.sqrt(np.outer(inversa.diagonal(), inversa.diagonal()))
r2 = R**2; q2 = anti**2
np.fill_diagonal(r2, 0); np.fill_diagonal(q2, 0)
np.testing.assert_allclose(r2.sum() / (r2.sum() + q2.sum()), leer("piloto_supuestos").kmo_global.iloc[0])

asignaciones = leer("cluster_asignaciones")
np.testing.assert_array_equal(asignaciones.id, base.id)
wss = 0
for g in sorted(asignaciones.cluster.unique()):
    grupo = z[asignaciones.cluster.eq(g)]
    wss += ((grupo - grupo.mean(axis=0))**2).sum()
np.testing.assert_allclose(wss, leer("cluster_metricas").query('k == 6').wss_kmeans.iloc[0])
assert leer("cluster_tamanos").n.sum() == 5000
af = leer("af_cargas_completas")
# factanal calcula unicidades por optimización; se admite su tolerancia numérica.
np.testing.assert_allclose((af[["F1", "F2", "F3", "F4"]]**2).sum(axis=1), af.comunalidad, atol=1e-4)
assert (af.unicidad > 0).all()
assert leer("af_diagnostico_minres").heywood.iloc[0]

# Rehacer el ACM indicador y el ajuste de Greenacre sin FactoMineR ni ca.
q = base[["tipo_trafico", "proto_g", "service_g", "state_g"]].copy()
q["respuesta_destino"] = np.where(base.dpkts.eq(0), "sin_respuesta", "con_respuesta")
c = leer("cortes_discretizacion").set_index("variable")
q["duracion_banda"] = pd.cut(base.dur, [-np.inf, c.loc["dur", "corte_1"], c.loc["dur", "corte_2"], np.inf], labels=["corta", "media", "larga"])
q["bytes_origen_banda"] = pd.cut(base.sbytes, [-np.inf, 564, 1580, np.inf], labels=["bajos", "medios", "altos"])
A = pd.get_dummies(q, dtype=float).to_numpy()
n, Q, J = len(q), len(q.columns), A.shape[1]
P = A / (n * Q)
cm = P.sum(axis=0)
S = (P - cm / n) / np.sqrt(cm / n)
lamb = np.linalg.svd(S, compute_uv=False)[:J - Q]**2
acm = leer("acm_autovalores")
np.testing.assert_allclose(lamb, acm.autovalor, atol=1e-11)
ajustados = np.where(lamb > 1 / Q, (Q / (Q - 1) * (lamb - 1 / Q))**2, 0)
total = Q / (Q - 1) * (np.sum(lamb**2) - (J - Q) / Q**2)
np.testing.assert_allclose(ajustados, acm.autovalor_ajustado, atol=1e-11)
np.testing.assert_allclose(100 * ajustados / total, acm.porcentaje_ajustado, atol=1e-10)
t = leer("acs_contingencia").iloc[:, 1:].to_numpy()
esperados = np.outer(t.sum(axis=1), t.sum(axis=0)) / t.sum()
np.testing.assert_allclose(((t - esperados)**2 / esperados).sum(), leer("acs_asociacion").chi2.iloc[0])
assert (leer("frecuencias_X_cat").groupby("variable").frecuencia.sum() == 5000).all()
print("Verificación correcta: ACP, KMO, WSS, AF, ACS y ACM con ajuste de inercia.")
