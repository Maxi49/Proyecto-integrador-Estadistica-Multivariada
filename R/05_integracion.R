# ETAPAS 5 Y 6. Síntesis de resultados y preparación de la exposición.
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
    "Tiempo, volumen, repetición por puertos y repetición por servicio",
    "AF reconoce los bloques; ARI Ward/KM = 0,813 y silhouette = 0,333; las CP cambian fronteras",
    "Normal-CON_otros y Exploits-FIN coinciden con asociaciones del ACM",
    "Respuesta/protocolo/estado y oposición entre estados y tipos de servicio")
)
guardar(integracion, "integracion_tecnicas")
writeLines(c("GUION PROPUESTO DE EXPOSICION - 18 MINUTOS",
  "0-4 min: Mateo. Pregunta, hipótesis, muestra, calidad y componentes principales.",
  "4-8 min: Ignacio. Factores, diagnóstico Heywood y comparación crítica ACP-AF.",
  "8-13 min: Maximiliano. Elección de k, comparación de métodos y perfiles de los seis grupos.",
  "13-18 min: Lisandro. ACS, ACM, cluster suplementario, hipótesis y limitaciones.",
  "Reservar hasta dos minutos adicionales para el cierre o preguntas, sin exceder 20 minutos.",
  "Puntos que deben poder explicar: por qué estandarizar; qué significa una unicidad negativa;",
  "por qué k=6 no es un óptimo indiscutible; por qué la inercia ajustada no es la cruda;",
  "por qué asociación y clusters no permiten afirmar probabilidades predictivas validadas."),
  "resultados/guion_exposicion.txt", useBytes = TRUE)
print(integracion)
