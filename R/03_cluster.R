# ETAPA 3. Ward y k-means sobre las 12 log_ estandarizadas.
library(cluster)
set.seed(42)
base <- readRDS("resultados/base_limpia.rds")
conjuntos <- readRDS("resultados/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
Z <- scale(X_num)
distancias <- dist(Z, method = "euclidean")
jerarquico <- hclust(distancias, method = "ward.D2")

# Codo: suma de cuadrados dentro de grupos. Silhouette sobre los 5.000 flujos.
metricas <- data.frame()
modelos_km <- list()
for (k in 2:8) {
  set.seed(42)
  km <- kmeans(Z, centers = k, nstart = 25, iter.max = 100)
  ward <- cutree(jerarquico, k)
  wss_ward <- 0
  for (g in 1:k) {
    grupo <- Z[ward == g, , drop = FALSE]
    wss_ward <- wss_ward + sum(sweep(grupo, 2, colMeans(grupo), "-")^2)
  }
  metricas <- rbind(metricas, data.frame(k = k, wss_ward = wss_ward, wss_kmeans = km$tot.withinss,
    silhouette_ward = mean(silhouette(ward, distancias)[, 3]),
    silhouette_kmeans = mean(silhouette(km$cluster, distancias)[, 3])))
  modelos_km[[as.character(k)]] <- km
  cat("Evaluado k =", k, "\n")
}
guardar(metricas, "cluster_metricas")

# Mayor silhouette de k-means entre los candidatos; el informe contrasta con el codo y Ward.
k_elegido <- metricas$k[which.max(metricas$silhouette_kmeans)]
km <- modelos_km[[as.character(k_elegido)]]
ward <- cutree(jerarquico, k_elegido)
guardar(as.data.frame.matrix(table(Ward = ward, Kmeans = km$cluster)), "cluster_cruce_ward_kmeans")

# Comparación de particiones sin depender del número arbitrario de las etiquetas.
ari <- function(a, b) {
  t <- table(a, b)
  observado <- sum(choose(t, 2))
  esperado <- sum(choose(rowSums(t), 2)) * sum(choose(colSums(t), 2)) / choose(sum(t), 2)
  maximo <- (sum(choose(rowSums(t), 2)) + sum(choose(colSums(t), 2))) / 2
  (observado - esperado) / (maximo - esperado)
}

# Los puntajes de ACP conservan la ponderación por sus autovalores: no se reescalan.
acp <- readRDS("resultados/acp.rds")
set.seed(42)
km_acp <- kmeans(acp$puntajes, centers = k_elegido, nstart = 25, iter.max = 100)
ward_acp <- cutree(hclust(dist(acp$puntajes), method = "ward.D2"), k_elegido)
guardar(as.data.frame.matrix(table(Kmeans_log = km$cluster, Kmeans_ACP = km_acp$cluster)), "cluster_cruce_acp")
guardar(as.data.frame.matrix(table(Ward_log = ward, Ward_ACP = ward_acp)), "cluster_cruce_ward_acp")
guardar(data.frame(k = k_elegido, ARI_ward_kmeans = ari(ward, km$cluster),
  ARI_kmeans_acp = ari(km$cluster, km_acp$cluster), ARI_ward_acp = ari(ward, ward_acp)), "cluster_comparaciones")

originales <- sub("^log_", "", names(X_num))
guardar(aggregate(base[originales], list(cluster = km$cluster), mean), "cluster_medias_originales")
guardar(aggregate(as.data.frame(Z), list(cluster = km$cluster), mean), "cluster_medias_estandarizadas")
guardar(data.frame(cluster = 1:k_elegido, n = as.integer(table(km$cluster)),
  porcentaje = 100 * as.integer(table(km$cluster)) / nrow(base)), "cluster_tamanos")
guardar(as.data.frame(table(cluster = km$cluster, tipo_trafico = base$tipo_trafico)), "cluster_contexto")
guardar(aggregate(as.numeric(base$label == "ataque"), list(cluster = km$cluster), mean), "cluster_proporcion_ataques")

# Cluster de variables: distancia euclidiana entre sus columnas estandarizadas, Ward.D2.
jerarquico_vars <- hclust(dist(t(Z)), method = "ward.D2")
guardar(data.frame(variable = names(X_num), bloque = cutree(jerarquico_vars, 3)), "cluster_variables_bloques")
guardar(data.frame(izquierda = jerarquico$merge[, 1], derecha = jerarquico$merge[, 2],
  altura = jerarquico$height), "cluster_dendrograma")
guardar(data.frame(izquierda = jerarquico_vars$merge[, 1], derecha = jerarquico_vars$merge[, 2],
  altura = jerarquico_vars$height), "cluster_dendrograma_variables")
base$cluster <- factor(km$cluster)
base$cluster_ward <- factor(ward)
base$cluster_acp <- factor(km_acp$cluster)
saveRDS(base, "resultados/base_con_clusters.rds")
guardar(data.frame(id = base$id, cluster = km$cluster, cluster_ward = ward,
  cluster_acp = km_acp$cluster), "cluster_asignaciones")
saveRDS(list(k = k_elegido, kmeans = km, jerarquico = jerarquico,
  jerarquico_variables = jerarquico_vars), "resultados/clustering.rds")
print(metricas)
cat("k elegido:", k_elegido, "\n")
