# ETAPA 2. Análisis factorial exploratorio y revisión de soluciones impropias.
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

# El análisis paralelo compara los autovalores observados con datos aleatorios.
# No se dibuja en R: los resultados se exportan para Matplotlib.
options(mc.cores = 1)
paralelo <- fa.parallel(X_num, fa = "both", fm = "minres", n.iter = 100,
  quant = .95, plot = FALSE)
guardar(data.frame(dimension = seq_along(paralelo$fa.values),
  factor_observado = paralelo$fa.values, factor_simulado = paralelo$fa.sim,
  componente_observado = paralelo$pc.values, componente_simulado = paralelo$pc.sim), "af_paralelo")

# Se retienen los factores sugeridos por el análisis paralelo y se revisa su interpretación.
n_factores <- paralelo$nfact
minres <- fa(X_num, nfactors = n_factores, fm = "minres", rotate = "varimax", scores = "regression")
guardar(data.frame(metodo = "minres", n_factores = n_factores,
  comunalidad_max = max(minres$communality), unicidad_min = min(minres$uniquenesses),
  heywood = any(minres$uniquenesses < 0)), "af_diagnostico_minres")

# Minres produce una unicidad negativa: no se oculta ni se elimina una variable acordada.
# ML con límite positivo permite una solución descriptiva; se informa el parámetro en el límite.
af <- factanal(X_num, factors = n_factores, rotation = "varimax", scores = "regression",
  control = list(lower = .005))
cargas <- unclass(af$loadings)
colnames(cargas) <- paste0("F", seq_len(n_factores))
patron <- cargas
patron[abs(patron) < .4] <- NA
diferencia <- apply(abs(cargas), 1, function(x) { x <- sort(x, decreasing = TRUE); x[1] - x[2] })
n_cargas <- rowSums(abs(cargas) >= .4)
guardar(data.frame(variable = rownames(cargas), cargas, comunalidad = 1 - af$uniquenesses,
  unicidad = af$uniquenesses, diferencia = diferencia, cargas_mayores_040 = n_cargas), "af_cargas_completas")
guardar(data.frame(variable = rownames(cargas), patron, comunalidad = 1 - af$uniquenesses,
  unicidad = af$uniquenesses), "af_patron")
guardar(data.frame(factor = colnames(cargas), suma_cargas2 = colSums(cargas^2),
  porcentaje_total = 100 * colSums(cargas^2) / ncol(X_num),
  porcentaje_comun = 100 * colSums(cargas^2) / sum(cargas^2)), "af_varianza")
residuos <- R - tcrossprod(cargas)
rmsr <- sqrt(mean(residuos[lower.tri(residuos)]^2))
guardar(data.frame(n_factores = n_factores, rmsr = rmsr,
  chi2 = unname(af$STATISTIC), gl = af$dof, p_modelo = af$PVAL,
  comunalidad_min = min(1 - af$uniquenesses), unicidad_min = min(af$uniquenesses),
  unicidades_limite = sum(af$uniquenesses <= .00501),
  cruces_ambiguos = sum(n_cargas > 1 & diferencia < .2)), "af_ajuste")
guardar(data.frame(id = conjuntos$id, af$scores), "af_puntajes")
saveRDS(list(modelo = af, n_factores = n_factores, cargas = cargas, paralelo = paralelo), "resultados/af.rds")
print(af$loadings, cutoff = .4)
print(af$uniquenesses)
