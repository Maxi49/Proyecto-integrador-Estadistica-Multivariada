# ETAPA 3 · Análisis de conglomerados (Ward y k-means) sobre las 12 variables log_ estandarizadas
# Produce: Figura 7 (elección de k), Figura 8 (dendrograma de variables) y Figura 9 (perfiles de los grupos) del informe;
#   tablas: cluster_metricas (WSS y silhouette, k = 2..8), cluster_tamanos, cluster_medias_estandarizadas,
#   cluster_cruce_ward_kmeans, cluster_cruce_acp, cluster_comparaciones (ARI).
# Figuras: resultados/figuras_informe/fig07_eleccion_k.png, fig08_dendrograma_variables.png, fig09_perfiles_grupos.png
# Requiere haber corrido antes R/00_datos.R y R/01_acp.R. Ejecutar desde la carpeta principal del proyecto.
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

# El silhouette casi empata entre k = 2, 4 y 6 (0,328; 0,327; 0,333). k = 2 no separa normal de
# ataque y k = 6 deja dos grupos con silhouette menor a 0,15. El codo se quiebra en 4 y esa
# partición se mantiene al repetirla con los puntajes del ACP. Se retiene k = 4 (decisión del grupo, 27/10).
k_elegido <- 4
km <- modelos_km[[as.character(k_elegido)]]
guardar(data.frame(cluster = 1:k_elegido,
  silhouette = summary(silhouette(km$cluster, distancias))$clus.avg.widths), "cluster_silhouette")
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

# FIGURAS DE LA ETAPA 3 (Figuras 7, 8 y 9 del informe).
source("R/estilo_graficos.R", encoding = "UTF-8")   # fuente, paleta, tema y guardar_fig()
corto <- sub("^log_", "", names(X_num))
# Los nombres G1 a G4 de la figura 9 (y del mapa del ACM) se asignan por posición: si cambia la numeración de
# k-means (semilla, versión de R) hay que revisarlos. Tamaños esperados: Tabla 7 del informe.
stopifnot(identical(as.integer(table(base$cluster)), c(1220L, 2444L, 1121L, 215L)))

# Figura 7. Elección de k: dos paneles con su propia escala (no doble eje).
m <- metricas
p_wss <- ggplot(m, aes(k, wss_kmeans)) + geom_line(colour = azul, linewidth = .6) + geom_point(colour = azul, size = 2) +
  geom_point(data = m[m$k == 4, ], colour = azul, size = 3.4) +
  scale_y_continuous(labels = function(x) format(x, big.mark = ".", decimal.mark = ",")) +
  labs(title = "Codo (k-means)", x = "k", y = "Suma de cuadrados dentro de grupos")
ms <- rbind(data.frame(k = m$k, s = m$silhouette_kmeans, metodo = "k-means"), data.frame(k = m$k, s = m$silhouette_ward, metodo = "Ward"))
p_sil <- ggplot(ms, aes(k, s, colour = metodo)) + geom_line(linewidth = .6) + geom_point(size = 2) +
  scale_colour_manual(values = c("k-means" = azul, "Ward" = naranja)) +
  scale_y_continuous(limits = c(.2, .36), labels = function(x) format(x, decimal.mark = ",")) +
  labs(title = "Silhouette promedio", x = "k", y = NULL)
guardar_fig(p_wss + p_sil, "fig07_eleccion_k", 7)

# Figura 8. Dendrograma de variables (Ward), coloreado por bloque.
hv <- jerarquico_vars
hv$labels <- sub(" \\(.*", "", etiquetas[sub("^log_", "", hv$labels)])
png("resultados/figuras_informe/fig08_dendrograma_variables.png", width = 16, height = 8, units = "cm", res = 300, family = familia)
par(mar = c(1, 4.5, .5, .5), cex = .7, col.axis = tinta_2, fg = tinta_2)
plot(hv, hang = -1, main = "", xlab = "", sub = "", ylab = "Altura (Ward)", col = tinta_2, lwd = .8)
rect.hclust(hv, k = 3, border = c(azul, naranja, "#1baf7a"))
dev.off()

# Figura 9. Medias estandarizadas por grupo (mapa de calor divergente).
me <- aggregate(as.data.frame(Z), list(cluster = km$cluster), mean)  # igual a cluster_medias_estandarizadas.csv
nombres_g <- c("G1 Cortos", "G2 Largos y lentos", "G3 Conversación completa", "G4 Repetitivos sin respuesta")
mh <- data.frame(grupo = rep(nombres_g, times = 12), variable = rep(sub("^log_", "", names(me)[-1]), each = 4),
  z = unlist(me[, -1], use.names = FALSE))
mh$variable <- factor(mh$variable, levels = orden, labels = etiquetas[orden])
mh$grupo <- factor(mh$grupo, levels = rev(nombres_g))
f9 <- ggplot(mh, aes(variable, grupo, fill = pmax(pmin(z, 2.5), -2.5))) + geom_tile(colour = "white", linewidth = .6) +
  geom_text(aes(label = formatC(z, format = "f", digits = 1, decimal.mark = ",")), family = familia, size = 2.4, colour = tinta) +
  scale_fill_gradient2(low = azul, mid = neutro, high = rojo, midpoint = 0, limits = c(-2.5, 2.5),
    name = "Desvíos respecto\ndel promedio") +
  labs(x = NULL, y = NULL) + theme(axis.text.x = element_text(angle = 40, hjust = 1), panel.grid = element_blank(),
    legend.position = "right", legend.title = element_text(colour = tinta_2, size = 8))
guardar_fig(f9, "fig09_perfiles_grupos", 9)
cat("Etapa 3: Figuras 7 a 9 guardadas en resultados/figuras_informe/\n")
