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

integracion <- data.frame(
  tecnica = c("ACP", "AF", "Clustering", "ACS", "ACM"),
  estructura = c(paste(acp$n_componentes, "componentes; 74,51% de varianza"),
    paste(af$n_factores, "factores; solución ML con unicidad en el límite"),
    paste("Tres bloques de variables y", km$k, "grupos de observaciones"),
    "Tipo de tráfico por estado; V de Cramér = 0,405",
    "Plano de dos dimensiones; 87,40% de inercia ajustada"),
  interpretacion = c("Ejes mixtos: complejidad frente a repetición; volumen y actividad",
    "Repetición, ritmo y volumen: reproduce los tres bloques",
    "AF reconoce los bloques; ARI Ward/KM = 0,813 y silhouette = 0,333; las CP cambian fronteras",
    "Normal-CON_otros y Exploits-FIN coinciden con asociaciones del ACM",
    "Respuesta/protocolo/estado y oposición entre estados y tipos de servicio")
)
guardar(integracion, "integracion_tecnicas")
print(integracion)
