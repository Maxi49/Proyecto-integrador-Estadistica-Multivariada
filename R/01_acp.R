# ETAPA 1. ACP sobre las 12 log_, desde la carpeta principal del proyecto.
set.seed(42)
base <- readRDS("resultados/base_limpia.rds")
conjuntos <- readRDS("resultados/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

# Estandarizar evita que las mayores varianzas determinen las componentes.
acp <- prcomp(X_num, scale. = TRUE)
acp_sin_escalar <- prcomp(X_num, scale. = FALSE)
autovalores <- acp$sdev^2
tabla_autovalores <- data.frame(componente = seq_along(autovalores), autovalor = autovalores,
  porcentaje = 100 * autovalores / sum(autovalores),
  acumulado = 100 * cumsum(autovalores) / sum(autovalores))
guardar(tabla_autovalores, "acp_autovalores")
guardar(data.frame(variable = names(X_num), varianza = sapply(X_num, var)), "acp_varianzas")
guardar(data.frame(version = c("estandarizado", "sin_estandarizar"),
  porcentaje_CP1 = c(100 * autovalores[1] / sum(autovalores),
    100 * acp_sin_escalar$sdev[1]^2 / sum(acp_sin_escalar$sdev^2))), "acp_comparacion_escala")

# Kaiser sugiere tres; se contrasta el resultado con el codo y el significado de los ejes.
n_componentes <- sum(autovalores > 1)
correlaciones <- cor(X_num, acp$x)
contribuciones <- 100 * acp$rotation^2
cos2 <- correlaciones^2
guardar(data.frame(variable = rownames(correlaciones), correlaciones[, 1:n_componentes]), "acp_correlaciones")
guardar(data.frame(variable = rownames(contribuciones), contribuciones[, 1:n_componentes]), "acp_contribuciones")
guardar(data.frame(variable = rownames(cos2), cos2[, 1:n_componentes]), "acp_cos2")
puntajes <- acp$x[, 1:n_componentes, drop = FALSE]
guardar(data.frame(id = base$id, tipo_trafico = base$tipo_trafico, puntajes), "acp_puntajes")

# Distancia en el espacio retenido, ajustada por la varianza de cada componente.
distancia <- rowSums(sweep(puntajes, 2, acp$sdev[1:n_componentes], "/")^2)
extremos <- order(distancia, decreasing = TRUE)[1:3]
guardar(data.frame(base[extremos, c("id", "tipo_trafico", "dur", "spkts", "dpkts", "sbytes", "dbytes")],
  puntajes[extremos, , drop = FALSE], distancia = distancia[extremos]), "acp_extremos")
saveRDS(list(modelo = acp, n_componentes = n_componentes, puntajes = puntajes), "resultados/acp.rds")
print(tabla_autovalores)
cat("Componentes retenidas:", n_componentes, "\n")
