# ETAPA 2. Análisis factorial exploratorio y revisión de soluciones impropias (casos Heywood).
# La comparación completa de 3 vs 4 factores x métodos x rotaciones está en R/aux_diagnostico_af.R.
library(psych)
set.seed(42)
conjuntos <- readRDS("resultados/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
R <- cor(X_num)
kmo <- KMO(R)
bartlett <- cortest.bartlett(R, n = nrow(X_num))
stopifnot(det(R) > .00001, kmo$MSA >= .6, min(kmo$MSAi) >= .5, bartlett$p.value < .05)

# 1. Cuántos factores: evidencia gráfica (análisis paralelo) y analítica (Kaiser sobre la
# matriz reducida). El análisis paralelo no se dibuja en R: se exporta para Matplotlib.
options(mc.cores = 1)
paralelo <- fa.parallel(X_num, fa = "both", fm = "minres", n.iter = 100,
  quant = .95, plot = FALSE)
guardar(data.frame(dimension = seq_along(paralelo$fa.values),
  factor_observado = paralelo$fa.values, factor_simulado = paralelo$fa.sim,
  componente_observado = paralelo$pc.values, componente_simulado = paralelo$pc.sim), "af_paralelo")

# Kaiser aplicado a la matriz reducida (comunalidades iniciales SMC en la diagonal): es el
# criterio coherente con el AF, porque trabaja solo con la varianza común.
Rreducida <- R
diag(Rreducida) <- smc(R)
autovalores_reducida <- eigen(Rreducida, symmetric = TRUE, only.values = TRUE)$values
n_kaiser <- sum(autovalores_reducida > 1)

# Se retienen 3 factores aunque el análisis paralelo sugiere 4. Motivos (ver docs/validacion_decisiones.md):
#  - Con n = 5000 el análisis paralelo detecta cualquier estructura por encima del azar; el 4.º
#    autovalor observado (0,127) es 10 veces menor que 1 y el codo cae después del 3.º.
#  - Kaiser sobre la matriz reducida y el ACP (Etapa 1) dan 3, igual que la hipótesis H1.
#  - El 4.º factor solo parte el bloque ct_* en dos: queda con 2 variables fuertes (ct_srv_*),
#    lo que es síntoma de sobreextracción, y esos dos subfactores correlacionan 0,62 en oblimin.
n_paralelo <- paralelo$nfact
n_factores <- n_kaiser
stopifnot(n_factores == 3)

# 2. Caso Heywood. Se contrastan estimadores sobre los mismos 3 factores y la misma rotación.
# Un estimador "falla" si alguna comunalidad llega a 1 o más (unicidad <= 0.005, el límite de ML).
# Los avisos de psych ("ultra-Heywood") son esperables aquí: se informan, no se ocultan.
ajustar <- function(metodo) suppressWarnings(fa(X_num, nfactors = n_factores, fm = metodo,
  rotate = "varimax", scores = "regression", n.obs = nrow(X_num)))
metodos <- c("minres", "pa", "ml", "gls")
fits <- lapply(setNames(metodos, metodos), ajustar)
diagnostico <- do.call(rbind, lapply(metodos, function(m) {
  f <- fits[[m]]
  data.frame(metodo = m, n_factores = n_factores, comunalidad_max = max(f$communality),
    unicidad_min = min(f$uniquenesses), variable_extrema = names(which.min(f$uniquenesses)),
    heywood = any(f$uniquenesses <= .005), rmsr = f$rms)
}))
guardar(diagnostico, "af_diagnostico_minres")
print(diagnostico)

# 3. Estimador final: GLS (mínimos cuadrados generalizados) con varimax.
# minres, pa y ML dan comunalidad ~1 (o mayor) para log_spkts; GLS la estima en torno a 0,87
# y todas las unicidades quedan lejos de cero. Es un remedio estándar ante un Heywood
# (cambiar de estimador) que no obliga a sacar una variable de X_num ni a fijar límites arbitrarios.
af <- fits[["gls"]]
cargas <- unclass(af$loadings)
# Se ordenan los factores por varianza explicada (psych ya los entrega así) y se renombran F1..F3.
colnames(cargas) <- paste0("F", seq_len(n_factores))
colnames(af$scores) <- paste0("Factor", seq_len(n_factores))

# Nombres: cada factor toma el bloque (H1) de las variables que más pesan en él.
bloque_h1 <- c(log_spkts = "Volumen", log_sbytes = "Volumen", log_dbytes = "Volumen",
  log_dur = "Temporización", log_sinpkt = "Temporización", log_sjit = "Temporización",
  log_synack = "Temporización", log_ct_srv_src = "Repetición de conexiones",
  log_ct_srv_dst = "Repetición de conexiones", log_ct_src_ltm = "Repetición de conexiones",
  log_ct_src_dport_ltm = "Repetición de conexiones", log_ct_dst_sport_ltm = "Repetición de conexiones")
asignado <- colnames(cargas)[apply(abs(cargas), 1, which.max)]
nombres_factores <- sapply(colnames(cargas), function(f) {
  b <- unique(bloque_h1[rownames(cargas)[asignado == f]])
  stopifnot(length(b) == 1) # si un factor mezcla bloques, hay que revisar el nombre a mano
  b
})

patron <- cargas
patron[abs(patron) < .4] <- NA # la consigna pide ocultar cargas menores a 0,40
diferencia <- apply(abs(cargas), 1, function(x) { x <- sort(x, decreasing = TRUE); x[1] - x[2] })
n_cargas <- rowSums(abs(cargas) >= .4)
comunalidad <- as.numeric(af$communality)
unicidad <- as.numeric(af$uniquenesses)
guardar(data.frame(variable = rownames(cargas), cargas, comunalidad = comunalidad,
  unicidad = unicidad, diferencia = diferencia, cargas_mayores_040 = n_cargas), "af_cargas_completas")
guardar(data.frame(variable = rownames(cargas), patron, comunalidad = comunalidad,
  unicidad = unicidad), "af_patron")
guardar(data.frame(factor = colnames(cargas), nombre = unname(nombres_factores)), "af_nombres_factores")
guardar(data.frame(factor = colnames(cargas), suma_cargas2 = colSums(cargas^2),
  porcentaje_total = 100 * colSums(cargas^2) / ncol(X_num),
  porcentaje_comun = 100 * colSums(cargas^2) / sum(cargas^2)), "af_varianza")
residuos <- R - tcrossprod(cargas)
rmsr <- sqrt(mean(residuos[lower.tri(residuos)]^2))
guardar(data.frame(metodo = "gls", n_factores = n_factores, n_sugerido_paralelo = n_paralelo,
  n_kaiser_reducida = n_kaiser, rmsr = rmsr, tli = af$TLI, rmsea = af$RMSEA[["RMSEA"]],
  chi2 = unname(af$STATISTIC), gl = af$dof, p_modelo = af$PVAL,
  comunalidad_min = min(comunalidad), unicidad_min = min(unicidad),
  unicidades_limite = sum(unicidad <= .00501),
  cruces_ambiguos = sum(n_cargas > 1 & diferencia < .2)), "af_ajuste")
guardar(data.frame(id = conjuntos$id, af$scores), "af_puntajes")
saveRDS(list(modelo = af, n_factores = n_factores, cargas = cargas, paralelo = paralelo,
  metodo = "gls", nombres = nombres_factores, diagnostico = diagnostico), "resultados/af.rds")
print(af$loadings, cutoff = .4)
print(af$uniquenesses)
