# AUXILIAR (no forma parte de ejecutar_todo.R). Diagnóstico del caso Heywood en el AF.
# Ejecutar desde la raíz del repo:  Rscript R/aux_diagnostico_af.R
# Compara 3 vs 4 factores x (minres, ml, pa) x (varimax, oblimin) y guarda
# resultados/tablas/af_diagnostico_comparativo.csv y af_diagnostico_autovalores.csv.
# Sirve de evidencia para justificar cuántos factores retiene R/02_af.R.
library(psych)
set.seed(42)
X <- readRDS("resultados/conjuntos_congelados.rds")$X_num
R <- cor(X)
p <- ncol(X)

# Bloques esperados por H1 (docs/etapa0_pregunta_hipotesis.md); solo para chequear interpretabilidad.
bloque_h1 <- c(log_spkts = "vol", log_sbytes = "vol", log_dbytes = "vol",
  log_dur = "tmp", log_sinpkt = "tmp", log_sjit = "tmp", log_synack = "tmp",
  log_ct_srv_src = "ctx", log_ct_srv_dst = "ctx", log_ct_src_ltm = "ctx",
  log_ct_src_dport_ltm = "ctx", log_ct_dst_sport_ltm = "ctx")

# 1. Autovalores: ¿es sustantivo el 4.º factor?
# Matriz reducida = R con la diagonal reemplazada por las comunalidades iniciales (SMC).
smc_ <- smc(R)
Rred <- R; diag(Rred) <- smc_
av_red <- eigen(Rred, symmetric = TRUE, only.values = TRUE)$values
av_cor <- eigen(R, symmetric = TRUE, only.values = TRUE)$values
set.seed(42)
pa <- suppressWarnings(fa.parallel(X, fa = "both", fm = "minres", n.iter = 100,
  quant = .95, plot = FALSE))
# Con n = 5000 el análisis paralelo detecta casi cualquier cosa por encima del azar:
# se agrega la varianza que aporta cada autovalor (autovalor reducido / suma de positivos).
aut <- data.frame(factor = 1:p, autovalor_R = av_cor, autovalor_reducida_smc = av_red,
  pct_var_total = 100 * av_cor / p,
  pct_var_comun = 100 * pmax(av_red, 0) / sum(pmax(av_red, 0)),
  fa_observado = pa$fa.values, fa_simulado = pa$fa.sim)
write.csv(aut, "resultados/tablas/af_diagnostico_autovalores.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\n== Autovalores (los 6 primeros) ==\n"); print(round(aut[1:6, ], 3), row.names = FALSE)
cat("Sugerencia del análisis paralelo (minres):", pa$nfact, "factores.\n")
cat("Kaiser sobre la matriz reducida (autovalor > 1):", sum(av_red > 1), "factores.\n")
cat("Autovalores reducidos > 0:", sum(av_red > 0), "\n")

# 2. Comparativo de soluciones
filas <- list()
for (k in 3:4) for (m in c("minres", "ml", "pa", "gls")) for (rot in c("varimax", "oblimin")) {
  aviso <- character()
  f <- withCallingHandlers(
    tryCatch(fa(X, nfactors = k, fm = m, rotate = rot, n.obs = nrow(X)), error = function(e) NULL),
    warning = function(w) { aviso <<- c(aviso, conditionMessage(w)); invokeRestart("muffleWarning") })
  if (is.null(f)) next
  L <- unclass(f$loadings)
  com <- f$communality
  uni <- f$uniquenesses
  ord <- t(apply(abs(L), 1, sort, decreasing = TRUE))
  dif <- ord[, 1] - ord[, 2]
  n04 <- rowSums(abs(L) >= .4)
  # Interpretabilidad: cada variable al factor de mayor carga; ¿cada factor agrupa un solo bloque H1?
  asig <- apply(abs(L), 1, which.max)
  # Cuántos bloques de H1 quedan recuperados exactamente (un factor = un bloque completo).
  grupos <- split(rownames(L), asig)
  puros <- sum(sapply(grupos, function(v) {
    b <- unique(bloque_h1[v]); length(b) == 1 && length(v) == sum(bloque_h1 == b) }))
  prop <- f$Vaccounted
  filas[[length(filas) + 1]] <- data.frame(
    n_factores = k, metodo = m, rotacion = rot,
    heywood = any(com >= 1 | uni <= .005),
    comunalidad_max = max(com), unicidad_min = min(uni),
    rmsr = f$rms, tli = f$TLI, rmsea = f$RMSEA[1],
    pct_var_acum = 100 * tail(prop["Cumulative Var", ], 1),
    sin_carga_040 = sum(n04 == 0),
    cruces_dif_menor_020 = sum(n04 > 1 & dif < .2),
    bloques_H1_recuperados = puros,
    avisos = length(aviso))
}
comp <- do.call(rbind, filas)
write.csv(comp, "resultados/tablas/af_diagnostico_comparativo.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\n== Comparativo (varimax y oblimin) ==\n")
print(format(comp, digits = 3), row.names = FALSE)

# 3. Estructura de la solución de 3 y 4 factores con minres/varimax (la del análisis paralelo)
for (k in 3:4) {
  f <- suppressWarnings(fa(X, nfactors = k, fm = "minres", rotate = "varimax"))
  cat("\n== minres + varimax,", k, "factores (cargas < 0,40 ocultas) ==\n")
  print(f$loadings, cutoff = .4, digits = 2)
  cat("Comunalidades:\n"); print(round(f$communality, 3))
}
# En 4 factores, ¿cuánto aporta el 4.º y qué hace? Correlación entre variables ct_* de cada puerto/servicio:
cat("\nCorrelaciones dentro del bloque ct_*:\n"); print(round(R[grep("ct_", rownames(R)), grep("ct_", colnames(R))], 2))
cat("\nCorrelación log_spkts con log_sbytes:", round(R["log_spkts", "log_sbytes"], 3),
    "| con log_dbytes:", round(R["log_spkts", "log_dbytes"], 3), "\n")

# 4. Factores correlacionados (oblimin, ML): ¿los dos subfactores ct_* del 4.º factor son separables?
f4o <- suppressWarnings(fa(X, nfactors = 4, fm = "ml", rotate = "oblimin"))
cat("\nCorrelación entre factores (ML, oblimin, 4 factores); los dos subfactores ct_* son los de mayor correlación:\n")
print(round(f4o$Phi, 2))

# 5. Sensibilidad (SOLO informativa; X_num no se modifica): ¿desaparece el Heywood sin log_spkts?
Xs <- X[, names(X) != "log_spkts"]
cat("\nSensibilidad sin log_spkts, 3 factores varimax:\n")
for (m in c("minres", "ml", "pa", "gls")) {
  f <- suppressWarnings(fa(Xs, nfactors = 3, fm = m, rotate = "varimax"))
  cat(sprintf("  %-7s comunalidad max = %.3f | unicidad min = %.3f | RMSR = %.3f\n", m,
              max(f$communality), min(f$uniquenesses), f$rms))
}
