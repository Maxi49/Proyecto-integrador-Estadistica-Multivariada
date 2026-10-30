# ETAPA 2 · Análisis Factorial (AF) exploratorio y revisión de soluciones impropias
# Produce: Figura 6 (análisis paralelo) del informe; tablas: af_paralelo, af_cargas_completas (cargas, comunalidades,
#   unicidades), af_varianza (% de varianza), af_ajuste (RMSR, RMSEA, TLI) y af_diagnostico_minres (caso Heywood).
# Figura: resultados/figuras_informe/fig06_paralelo_af.png
# Requiere haber corrido antes R/00_datos.R. Ejecutar desde la carpeta principal del proyecto.
# (El diagnóstico comparativo de estimadores está aparte, en R/aux_diagnostico_af.R.)
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
# OJO: fa.parallel devuelve en fa.sim / pc.sim el PROMEDIO de las 100 simulaciones (el argumento quant
# solo afecta a un objeto interno que no se exporta). Por eso la figura 6 rotula "promedio" y no "percentil 95".
# El gráfico (Figura 6) se arma al final de este script a partir de af_paralelo.csv.
options(mc.cores = 1)
paralelo <- suppressWarnings(fa.parallel(X_num, fa = "both", fm = "minres", n.iter = 100,
  plot = FALSE))  # los avisos son de réplicas con casos Heywood en datos al azar; no afectan al resultado
guardar(data.frame(dimension = seq_along(paralelo$fa.values),
  factor_observado = paralelo$fa.values, factor_simulado = paralelo$fa.sim,
  componente_observado = paralelo$pc.values, componente_simulado = paralelo$pc.sim), "af_paralelo")

# El análisis paralelo sugiere 4 factores, pero el cuarto autovalor (0,13) apenas supera al azar
# y solo parte en dos el bloque de repetición. Kaiser y el paralelo de componentes indican 3.
# Se retienen 3 factores por simplicidad e interpretabilidad (decisión del grupo, 27/10).
n_factores <- 3
# Solo diagnóstico: se espera una unicidad negativa (ultra-Heywood), por eso se silencian sus avisos.
minres <- suppressWarnings(fa(X_num, nfactors = n_factores, fm = "minres", rotate = "varimax", scores = "none"))
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
# RMSEA y TLI no dependen del n del mismo modo que el chi cuadrado y completan la evaluación del ajuste.
n <- nrow(X_num); p <- ncol(X_num)
chi2_nulo <- -(n - 1 - (2 * p + 5) / 6) * log(det(R)); gl_nulo <- p * (p - 1) / 2
rmsea <- sqrt(max(unname(af$STATISTIC) - af$dof, 0) / (af$dof * (n - 1)))
tli <- (chi2_nulo / gl_nulo - unname(af$STATISTIC) / af$dof) / (chi2_nulo / gl_nulo - 1)
guardar(data.frame(n_factores = n_factores, rmsr = rmsr, rmsea = rmsea, tli = tli,
  chi2 = unname(af$STATISTIC), gl = af$dof, p_modelo = af$PVAL,
  comunalidad_min = min(1 - af$uniquenesses), unicidad_min = min(af$uniquenesses),
  unicidades_limite = sum(af$uniquenesses <= .00501),
  cruces_ambiguos = sum(n_cargas > 1 & diferencia < .2)), "af_ajuste")
guardar(data.frame(id = conjuntos$id, af$scores), "af_puntajes")
saveRDS(list(modelo = af, n_factores = n_factores, cargas = cargas, paralelo = paralelo), "resultados/af.rds")
print(af$loadings, cutoff = .4)
print(af$uniquenesses)

# FIGURA DE LA ETAPA 2 (Figura 6 del informe).
source("R/estilo_graficos.R", encoding = "UTF-8")   # fuente, paleta, tema y guardar_fig()

# Figura 6. Análisis paralelo de factores.
par_af <- leer_tabla("af_paralelo")[1:8, ]
pa <- rbind(data.frame(dimension = par_af$dimension, valor = par_af$factor_observado, serie = "Datos observados"),
  data.frame(dimension = par_af$dimension, valor = par_af$factor_simulado, serie = "Datos al azar (promedio de 100 simulaciones)"))
pa$serie <- factor(pa$serie, levels = c("Datos observados", "Datos al azar (promedio de 100 simulaciones)"))
f6 <- ggplot(pa, aes(dimension, valor, colour = serie)) + geom_line(linewidth = .6) + geom_point(size = 2) +
  scale_colour_manual(values = c("Datos observados" = azul, "Datos al azar (promedio de 100 simulaciones)" = naranja)) +
  scale_x_continuous(breaks = 1:8) + labs(x = "Factor", y = "Autovalor")
guardar_fig(f6, "fig06_paralelo_af", 6.5)
cat("Etapa 2: Figura 6 guardada en resultados/figuras_informe/\n")
