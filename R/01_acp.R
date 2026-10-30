# ETAPA 1 · Análisis de Componentes Principales (ACP) sobre las 12 variables log_
# Produce: Figura 4 (codo con línea de Kaiser) y Figura 5 (biplot CP1-CP2) del informe;
#   tablas: acp_autovalores, acp_correlaciones, acp_contribuciones, acp_cos2, acp_puntajes, acp_extremos.
# Figuras: resultados/figuras_informe/fig04_codo_acp.png, fig05_biplot.png
# Requiere haber corrido antes R/00_datos.R. Ejecutar desde la carpeta principal del proyecto.
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

# FIGURAS DE LA ETAPA 1 (Figuras 4 y 5 del informe).
source("R/estilo_graficos.R", encoding = "UTF-8")   # fuente, paleta, tema y guardar_fig()
corto <- sub("^log_", "", names(X_num))

# Figura 4. Codo del ACP con la línea de Kaiser.
av <- tabla_autovalores
f4 <- ggplot(av, aes(componente, autovalor)) + geom_hline(yintercept = 1, colour = tinta_2, linetype = "dashed", linewidth = .3) +
  geom_line(colour = azul, linewidth = .6) + geom_point(colour = azul, size = 2) +
  geom_point(data = av[1:3, ], colour = azul, size = 3.2) +
  annotate("text", x = 11.8, y = 1.18, label = "Kaiser: autovalor = 1", hjust = 1, family = familia, size = 2.8, colour = tinta_2) +
  scale_x_continuous(breaks = 1:12) + labs(x = "Componente", y = "Autovalor")
guardar_fig(f4, "fig04_codo_acp", 6.5)

# Figura 5. Biplot CP1-CP2: flujos coloreados por tipo de tráfico (todos los puntos, sin recorte),
# flechas de variables, centro (media) de cada tipo y los tres flujos extremos_fig del texto rotulados.
# Las flechas son la correlación de cada variable con la componente multiplicada por `escala`
# (los puntos están en puntajes sin reescalar); el factor se declara al pie de la figura.
pt <- data.frame(puntajes[, 1:2]); names(pt) <- c("CP1", "CP2"); pt$tipo <- base$tipo_trafico
centros <- aggregate(cbind(CP1, CP2) ~ tipo, pt, mean)
carg <- leer_tabla("acp_correlaciones"); carg$etq <- sub(" \\(.*", "", etiquetas[sub("^log_", "", carg$variable)])
escala <- 4.5
carg$x <- escala * carg$PC1; carg$y <- escala * carg$PC2
# Las etiquetas van junto a la punta, del lado hacia donde apunta la flecha, y se separan en vertical.
carg$lado <- ifelse(carg$x < 0, "izq", "der")
# Los tres flujos que describe el texto: el de menor CP1, el de mayor CP2 y el de menor CP2 (se buscan en
# los puntajes en vez de escribir los id a mano; salen 127446, 97189 y 44648).
i_ext <- c(which.min(pt$CP1), which.max(pt$CP2), which.min(pt$CP2))
extremos_fig <- pt[i_ext, ]
extremos_fig$etq <- paste("Flujo", base$id[i_ext])
colores_tipo <- c(Normal = azul, Exploits = naranja, Fuzzers = "#3a9a5b", Reconnaissance = "#8b5cc7",
  "Otros ataques" = rojo)
# Rango con margen para que entren todos los puntos (incluidos los extremos_fig) y sus rótulos.
xlim5 <- range(c(pt$CP1, carg$x)) + c(-1.2, 2.2); ylim5 <- range(c(pt$CP2, carg$y)) + c(-.5, .6)
f5 <- ggplot(pt, aes(CP1, CP2)) + geom_hline(yintercept = 0, colour = grilla) + geom_vline(xintercept = 0, colour = grilla) +
  geom_point(aes(colour = tipo), size = .35, alpha = .25) +
  geom_segment(data = carg, aes(x = 0, y = 0, xend = x, yend = y), colour = tinta,
    linewidth = .4, arrow = arrow(length = unit(1.3, "mm"))) +
  geom_text_repel(data = carg[carg$lado == "izq", ], aes(x, y, label = etq), family = familia, size = 2.5,
    colour = tinta, hjust = 1, nudge_x = -.35, direction = "y", box.padding = .1, min.segment.length = Inf,
    seed = 42, bg.colour = "white", bg.r = .12) +
  geom_text_repel(data = carg[carg$lado == "der", ], aes(x, y, label = etq), family = familia, size = 2.5,
    colour = tinta, hjust = 0, nudge_x = .35, direction = "y", box.padding = .1, min.segment.length = Inf,
    seed = 42, bg.colour = "white", bg.r = .12) +
  geom_point(data = centros, aes(fill = tipo), shape = 21, colour = tinta, size = 3.4, stroke = .5) +
  geom_point(data = extremos_fig, shape = 21, colour = tinta, fill = NA, size = 3.6, stroke = .7) +
  geom_text_repel(data = extremos_fig, aes(label = etq), family = familia, size = 2.7, fontface = "bold",
    colour = tinta, box.padding = .5, seed = 42) +
  scale_colour_manual(values = colores_tipo, guide = guide_legend(override.aes = list(size = 2.5, alpha = 1))) +
  scale_fill_manual(values = colores_tipo, guide = "none") +
  scale_x_continuous(labels = function(x) format(x, decimal.mark = ",")) +
  scale_y_continuous(labels = function(x) format(x, decimal.mark = ",")) +
  coord_equal(xlim = xlim5, ylim = ylim5) +
  labs(x = "CP1 (43,3 %): conexiones repetidas ← → conversaciones largas y cargadas",
    y = "CP2 (16,9 %): más actividad ↑",
    caption = paste0("Puntos: flujos (n = 5.000), sin recorte. Círculos grandes: media de cada tipo de tráfico. ",
      "Flechas: correlación de la variable con la CP × ", format(escala, decimal.mark = ","), "."))
f5 <- f5 + theme(plot.caption = element_text(colour = tinta_2, size = 7, hjust = 0))
guardar_fig(f5, "fig05_biplot", 11.5)
cat("Etapa 1: Figuras 4 y 5 guardadas en resultados/figuras_informe/\n")
