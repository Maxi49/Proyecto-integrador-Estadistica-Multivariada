# ETAPA 6. Síntesis de resultados de las técnicas multivariadas.
set.seed(42)
base <- readRDS("resultados/base_con_clusters.rds")
X <- readRDS("resultados/conjuntos_congelados.rds")$X_num
acp <- readRDS("resultados/acp.rds")
af <- readRDS("resultados/af.rds")
km <- readRDS("resultados/clustering.rds")
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

# Evidencia de la hipótesis de asociaciones, con tamaños del efecto.
asociaciones <- data.frame()
for (variable in c("proto_g", "service_g", "state_g")) {
  t <- table(base$tipo_trafico, base[[variable]])
  prueba <- chisq.test(t, correct = FALSE)
  asociaciones <- rbind(asociaciones, data.frame(variable = variable,
    chi2 = unname(prueba$statistic), gl = unname(prueba$parameter), p = prueba$p.value,
    cramer_v = sqrt(unname(prueba$statistic) / (sum(t) * min(dim(t) - 1)))))
}
guardar(asociaciones, "integracion_asociaciones")

# Todas las cifras de la tabla salen de los objetos y tablas ya calculados (nada escrito a mano).
# Formato argentino: coma decimal.
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")
leer <- function(nombre) read.csv(paste0("resultados/tablas/", nombre, ".csv"), fileEncoding = "UTF-8")
ari <- function(a, b) { # índice de Rand ajustado entre dos particiones
  t <- table(a, b)
  observado <- sum(choose(t, 2))
  esperado <- sum(choose(rowSums(t), 2)) * sum(choose(colSums(t), 2)) / choose(sum(t), 2)
  maximo <- (sum(choose(rowSums(t), 2)) + sum(choose(colSums(t), 2))) / 2
  (observado - esperado) / (maximo - esperado)
}

var_acp <- sum(acp$modelo$sdev[seq_len(acp$n_componentes)]^2) / sum(acp$modelo$sdev^2) * 100
ajuste_af <- leer("af_ajuste")
var_af <- sum(leer("af_varianza")$porcentaje_total)
heywood_final <- ajuste_af$unicidades_limite > 0 || ajuste_af$unicidad_min <= 0
v_cramer <- asociaciones$cramer_v[asociaciones$variable == "state_g"]
inercia_acm <- leer("acm_resumen")$porcentaje_plano_ajustado
cmp <- leer("cluster_comparaciones")
sil <- leer("cluster_metricas")
sil_k <- sil$silhouette_kmeans[sil$k == km$k]
# ¿Los bloques del cluster de variables coinciden con los factores del AF?
bloques_vars <- leer("cluster_variables_bloques")
factor_dominante <- apply(abs(af$cargas), 1, which.max)
ari_bloques_af <- ari(bloques_vars$bloque, factor_dominante[bloques_vars$variable])

integracion <- data.frame(
  tecnica = c("ACP", "AF", "Clustering", "ACS", "ACM"),
  estructura = c(
    paste0(acp$n_componentes, " componentes; ", fmt(var_acp), "% de varianza"),
    paste0(af$n_factores, " factores (", toupper(af$metodo), ", varimax); ", fmt(var_af),
      "% de la varianza total; ", ifelse(heywood_final, "con unicidad en el límite",
      paste0("sin caso Heywood (unicidad mínima ", fmt(ajuste_af$unicidad_min, 3), ")"))),
    paste0("Tres bloques de variables y ", km$k, " grupos de observaciones"),
    paste0("Tipo de tráfico por estado; V de Cramér = ", fmt(v_cramer, 3)),
    paste0("Plano de dos dimensiones; ", fmt(inercia_acm), "% de inercia ajustada")),
  interpretacion = c(
    "Ejes mixtos: magnitud del flujo frente a repetición (CP1), volumen de tráfico (CP2) y ritmo lento (CP3)",
    paste0(paste(af$nombres, collapse = ", "), " (cargas >= 0,40; cruces ambiguos = ",
      ajuste_af$cruces_ambiguos, ")"),
    paste0("El AF reconoce los bloques (ARI bloques de variables vs. factores = ", fmt(ari_bloques_af, 3),
      "); ARI Ward/KM = ", fmt(cmp$ARI_ward_kmeans, 3), ", silhouette = ", fmt(sil_k, 3),
      "; con puntajes de ACP el ARI frente a k-means es ", fmt(cmp$ARI_kmeans_acp, 3), " (las CP cambian fronteras)"),
    "Normal-CON_otros y Exploits-FIN coinciden con asociaciones del ACM",
    "Dim 1: conexión efímera sin respuesta frente a sesión TCP completa; Dim 2: DNS/UDP con estado CON frente a protocolo otros no establecido")
)
guardar(integracion, "integracion_tecnicas")
print(integracion)
