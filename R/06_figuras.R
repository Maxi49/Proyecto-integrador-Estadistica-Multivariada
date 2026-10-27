# FIGURAS DEL INFORME. Una idea por figura, nombres de variables descriptivos.
# Ejecutar después de 00 a 05. Guarda PNG a 300 ppp en resultados/figuras_informe/.
library(ggplot2)
library(ggrepel)
library(patchwork)
set.seed(42)
base <- readRDS("resultados/base_con_clusters.rds")
conjuntos <- readRDS("resultados/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
acp <- readRDS("resultados/acp.rds")
clustering <- readRDS("resultados/clustering.rds")
tabla <- function(nombre) read.csv(paste0("resultados/tablas/", nombre, ".csv"), fileEncoding = "UTF-8")
dir.create("resultados/figuras_informe", showWarnings = FALSE)
guardar_fig <- function(grafico, nombre, alto = 9) ggsave(paste0("resultados/figuras_informe/", nombre, ".png"),
  grafico, width = 16, height = alto, units = "cm", dpi = 300, bg = "white")

# Paleta: tinta en grises, azul y naranja para identidad, divergente azul-gris-rojo.
tinta <- "#0b0b0b"; tinta_2 <- "#52514e"; grilla <- "#e4e3df"; neutro <- "#f0efec"
azul <- "#2a78d6"; naranja <- "#eb6834"; rojo <- "#e34948"; gris_puntos <- "#c3c2b7"
tema <- theme_minimal(base_size = 9, base_family = "Carlito") +
  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = grilla, linewidth = .3),
    axis.text = element_text(colour = tinta_2), axis.title = element_text(colour = tinta_2),
    plot.title = element_text(colour = tinta, face = "bold", size = 10),
    strip.text = element_text(colour = tinta, face = "bold"), legend.position = "top",
    legend.title = element_blank(), legend.text = element_text(colour = tinta_2))
theme_set(tema)

etiquetas <- c(dur = "Duración (dur)", spkts = "Paquetes enviados (spkts)", sbytes = "Bytes enviados (sbytes)",
  dbytes = "Bytes devueltos (dbytes)", sinpkt = "Tiempo entre paquetes (sinpkt)",
  sjit = "Irregularidad del ritmo (sjit)", synack = "Demora en aceptar (synack)",
  ct_srv_src = "Mismo servicio y origen (ct_srv_src)", ct_srv_dst = "Mismo servicio y destino (ct_srv_dst)",
  ct_src_ltm = "Mismo origen (ct_src_ltm)", ct_src_dport_ltm = "Mismo origen y puerto destino (ct_src_dport_ltm)",
  ct_dst_sport_ltm = "Mismo destino y puerto origen (ct_dst_sport_ltm)")
bloque <- c(spkts = "Volumen", sbytes = "Volumen", dbytes = "Volumen", dur = "Ritmo", sinpkt = "Ritmo",
  sjit = "Ritmo", synack = "Ritmo", ct_srv_src = "Repetición", ct_srv_dst = "Repetición",
  ct_src_ltm = "Repetición", ct_src_dport_ltm = "Repetición", ct_dst_sport_ltm = "Repetición")
orden <- names(bloque)
corto <- sub("^log_", "", names(X_num))

# Figura 1. Boxplots de las 12 variables (log, estandarizadas para compartir eje).
Z <- as.data.frame(scale(X_num)); names(Z) <- corto
largo <- data.frame(variable = rep(corto, each = nrow(Z)), valor = unlist(Z, use.names = FALSE))
largo$variable <- factor(largo$variable, levels = rev(orden), labels = rev(etiquetas[orden]))
largo$bloque <- factor(bloque[as.character(sub(".*\\((.*)\\)$", "\\1", largo$variable))],
  levels = c("Volumen", "Ritmo", "Repetición"))
f1 <- ggplot(largo, aes(valor, variable)) +
  geom_boxplot(width = .55, linewidth = .35, colour = tinta_2, fill = neutro,
    outlier.size = .4, outlier.alpha = .35, outlier.colour = azul) +
  facet_grid(bloque ~ ., scales = "free_y", space = "free_y") +
  labs(x = "Valor estandarizado de log(x + 1)", y = NULL)
guardar_fig(f1, "fig01_boxplots", 11)

# Figura 2. Efecto de la transformación: bytes enviados antes y después del log.
h1 <- ggplot(base, aes(sbytes)) + geom_histogram(bins = 40, fill = azul, colour = "white", linewidth = .2) +
  scale_x_continuous(labels = function(x) paste(format(x / 1e6, decimal.mark = ","), "MB")) +
  labs(title = "Escala original", x = "Bytes enviados por el origen (sbytes)", y = "Flujos")
h2 <- ggplot(base, aes(log1p(sbytes))) + geom_histogram(bins = 40, fill = azul, colour = "white", linewidth = .2) +
  labs(title = "Escala log(x + 1)", x = "log(sbytes + 1)", y = NULL)
f2 <- h1 + h2
guardar_fig(f2, "fig02_histogramas", 6.5)

# Figura 3. Mapa de calor de correlaciones, ordenado por bloque.
R <- cor(X_num); dimnames(R) <- list(corto, corto)
cr <- as.data.frame(as.table(R[orden, orden]))
cr$Var1 <- factor(cr$Var1, levels = orden, labels = etiquetas[orden])
cr$Var2 <- factor(cr$Var2, levels = rev(orden), labels = rev(etiquetas[orden]))
f3 <- ggplot(cr, aes(Var1, Var2, fill = Freq)) + geom_tile(colour = "white", linewidth = .6) +
  geom_text(aes(label = formatC(Freq, format = "f", digits = 2, decimal.mark = ",")),
    family = "Carlito", size = 2.2, colour = tinta) +
  scale_fill_gradient2(low = azul, mid = neutro, high = rojo, midpoint = 0, limits = c(-1, 1), name = "r") +
  labs(x = NULL, y = NULL) + theme(axis.text.x = element_text(angle = 40, hjust = 1), panel.grid = element_blank(),
    legend.position = "right", legend.title = element_text(colour = tinta_2))
guardar_fig(f3, "fig03_correlaciones", 13)

# Figura 4. Codo del ACP con la línea de Kaiser.
av <- tabla("acp_autovalores")
f4 <- ggplot(av, aes(componente, autovalor)) + geom_hline(yintercept = 1, colour = tinta_2, linetype = "dashed", linewidth = .3) +
  geom_line(colour = azul, linewidth = .6) + geom_point(colour = azul, size = 2) +
  geom_point(data = av[1:3, ], colour = azul, size = 3.2) +
  annotate("text", x = 11.8, y = 1.18, label = "Kaiser: autovalor = 1", hjust = 1, family = "Carlito", size = 2.8, colour = tinta_2) +
  scale_x_continuous(breaks = 1:12) + labs(x = "Componente", y = "Autovalor")
guardar_fig(f4, "fig04_codo_acp", 6.5)

# Figura 5. Biplot CP1-CP2: flujos de fondo muy tenues, flechas de variables con nombre en la punta
# y el centro de cada tipo de tráfico. Se recorta la vista a la zona central.
pt <- data.frame(acp$puntajes[, 1:2]); names(pt) <- c("CP1", "CP2"); pt$tipo <- base$tipo_trafico
centros <- aggregate(cbind(CP1, CP2) ~ tipo, pt, mean)
carg <- tabla("acp_correlaciones"); carg$etq <- sub(" \\(.*", "", etiquetas[sub("^log_", "", carg$variable)])
escala <- 3.6
carg$x <- escala * carg$PC1; carg$y <- escala * carg$PC2
f5 <- ggplot(pt, aes(CP1, CP2)) + geom_hline(yintercept = 0, colour = grilla) + geom_vline(xintercept = 0, colour = grilla) +
  geom_point(colour = gris_puntos, size = .3, alpha = .12) +
  geom_segment(data = carg, aes(x = 0, y = 0, xend = x, yend = y), colour = tinta_2,
    linewidth = .35, arrow = arrow(length = unit(1.3, "mm"))) +
  geom_text_repel(data = carg[carg$PC1 < 0, ], aes(x, y, label = etq), family = "Carlito", size = 2.5,
    colour = tinta_2, xlim = c(-Inf, -2.75), hjust = 1, direction = "y", box.padding = .12,
    min.segment.length = 0, segment.colour = gris_puntos, segment.size = .25, seed = 42) +
  geom_text_repel(data = carg[carg$PC1 > 0, ], aes(x, y, label = etq), family = "Carlito", size = 2.5,
    colour = tinta_2, xlim = c(3.2, Inf), hjust = 0, direction = "y", box.padding = .12,
    min.segment.length = 0, segment.colour = gris_puntos, segment.size = .25, seed = 42) +
  geom_point(data = centros, colour = naranja, size = 3.2) +
  geom_label(data = centros, aes(CP1 + c(0, .35, -.45, 0, 0), CP2 + c(-.42, -.32, .32, -.32, -.32), label = tipo),
    family = "Carlito", fontface = "bold", size = 3, colour = tinta, fill = "white", label.size = 0,
    label.padding = unit(.08, "lines")) +
  annotate("text", x = -5.8, y = -2.4, label = "← más conexiones repetidas", hjust = 0, family = "Carlito",
    size = 3, colour = azul, fontface = "bold") +
  annotate("text", x = 5.3, y = -2.4, label = "conversaciones más largas y cargadas →", hjust = 1,
    family = "Carlito", size = 3, colour = azul, fontface = "bold") +
  annotate("text", x = -5.8, y = 3.6, label = "↑ más actividad (paquetes y bytes)", hjust = 0,
    family = "Carlito", size = 3, colour = azul, fontface = "bold") +
  coord_cartesian(xlim = c(-5.8, 5.3), ylim = c(-2.5, 3.7)) +
  labs(x = "CP1 (43,3 % de la varianza)", y = "CP2 (16,9 %)")
guardar_fig(f5, "fig05_biplot", 11)

# Figura 6. Análisis paralelo de factores.
par_af <- tabla("af_paralelo")[1:8, ]
pa <- rbind(data.frame(dimension = par_af$dimension, valor = par_af$factor_observado, serie = "Datos observados"),
  data.frame(dimension = par_af$dimension, valor = par_af$factor_simulado, serie = "Datos al azar (percentil 95)"))
pa$serie <- factor(pa$serie, levels = c("Datos observados", "Datos al azar (percentil 95)"))
f6 <- ggplot(pa, aes(dimension, valor, colour = serie)) + geom_line(linewidth = .6) + geom_point(size = 2) +
  scale_colour_manual(values = c("Datos observados" = azul, "Datos al azar (percentil 95)" = naranja)) +
  scale_x_continuous(breaks = 1:8) + labs(x = "Factor", y = "Autovalor")
guardar_fig(f6, "fig06_paralelo_af", 6.5)

# Figura 7. Elección de k: dos paneles con su propia escala (no doble eje).
m <- tabla("cluster_metricas")
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
hv <- clustering$jerarquico_variables
hv$labels <- sub(" \\(.*", "", etiquetas[sub("^log_", "", hv$labels)])
png("resultados/figuras_informe/fig08_dendrograma_variables.png", width = 16, height = 8, units = "cm", res = 300, family = "Carlito")
par(mar = c(1, 4.5, .5, .5), cex = .7, col.axis = tinta_2, fg = tinta_2)
plot(hv, hang = -1, main = "", xlab = "", sub = "", ylab = "Altura (Ward)", col = tinta_2, lwd = .8)
rect.hclust(hv, k = 3, border = c(azul, naranja, "#1baf7a"))
dev.off()

# Figura 9. Medias estandarizadas por grupo (mapa de calor divergente).
me <- tabla("cluster_medias_estandarizadas")
nombres_g <- c("G1 Cortos", "G2 Largos y lentos", "G3 Conversación completa", "G4 Repetitivos sin respuesta")
mh <- data.frame(grupo = rep(nombres_g, times = 12), variable = rep(sub("^log_", "", names(me)[-1]), each = 4),
  z = unlist(me[, -1], use.names = FALSE))
mh$variable <- factor(mh$variable, levels = orden, labels = etiquetas[orden])
mh$grupo <- factor(mh$grupo, levels = rev(nombres_g))
f9 <- ggplot(mh, aes(variable, grupo, fill = pmax(pmin(z, 2.5), -2.5))) + geom_tile(colour = "white", linewidth = .6) +
  geom_text(aes(label = formatC(z, format = "f", digits = 1, decimal.mark = ",")), family = "Carlito", size = 2.4, colour = tinta) +
  scale_fill_gradient2(low = azul, mid = neutro, high = rojo, midpoint = 0, limits = c(-2.5, 2.5),
    name = "Desvíos respecto\ndel promedio") +
  labs(x = NULL, y = NULL) + theme(axis.text.x = element_text(angle = 40, hjust = 1), panel.grid = element_blank(),
    legend.position = "right", legend.title = element_text(colour = tinta_2, size = 8))
guardar_fig(f9, "fig09_perfiles_grupos", 9)

# Figura 10. Mapa del ACS: tipo de tráfico (filas) y estado de la conexión (columnas).
fil <- tabla("acs_filas"); fil$rol <- "Tipo de tráfico"
col <- tabla("acs_columnas"); col$rol <- "Estado de la conexión"
col$categoria <- c(CON_otros = "CON y otros", FIN = "FIN (cerrada)", INT = "INT (interrumpida)")[col$categoria]
acs <- rbind(fil, col)
inercia <- tabla("acs_inercia")$porcentaje
f10 <- ggplot(acs, aes(Dim1, Dim2, colour = rol)) + geom_hline(yintercept = 0, colour = grilla) + geom_vline(xintercept = 0, colour = grilla) +
  geom_point(aes(shape = rol), size = 2.6) + geom_text_repel(aes(label = categoria), family = "Carlito", size = 2.9,
    colour = tinta, box.padding = .4, show.legend = FALSE) +
  scale_colour_manual(values = c("Tipo de tráfico" = azul, "Estado de la conexión" = naranja)) +
  scale_shape_manual(values = c("Tipo de tráfico" = 16, "Estado de la conexión" = 17)) +
  labs(x = paste0("Dimensión 1 (", format(round(inercia[1], 1), decimal.mark = ","), " %)"), y = paste0("Dimensión 2 (", format(round(inercia[2], 1), decimal.mark = ","), " %)"))
f10 <- f10 + scale_x_continuous(labels = function(x) format(x, decimal.mark = ",")) +
  scale_y_continuous(labels = function(x) format(x, decimal.mark = ","))
guardar_fig(f10, "fig10_mapa_acs", 8)

# Figura 11. Mapa del ACM: categorías activas en gris, suplementarias en color.
ca_ <- tabla("acm_categorias_coordenadas")[, c("categoria", "Dim.1", "Dim.2")]
ca_$categoria <- c("proto_g:otros" = "protocolo otros", "proto_g:tcp" = "TCP", "proto_g:udp" = "UDP",
  "service_g:dns" = "dns", "service_g:http" = "http", "service_g:ninguno" = "sin servicio",
  "service_g:otros" = "servicio otros", "state_g:CON_otros" = "CON y otros", "state_g:FIN" = "FIN",
  "state_g:INT" = "INT", "respuesta_destino:con_respuesta" = "con respuesta",
  "respuesta_destino:sin_respuesta" = "sin respuesta", "duracion_banda:corta" = "duración corta",
  "duracion_banda:media" = "duración media", "duracion_banda:larga" = "duración larga",
  "bytes_origen_banda:bajos" = "bytes bajos", "bytes_origen_banda:medios" = "bytes medios",
  "bytes_origen_banda:altos" = "bytes altos")[ca_$categoria]
stopifnot(!anyNA(ca_$categoria))
ca_$rol <- "Categorías activas"
su <- tabla("acm_suplementarias_coordenadas")[, c("categoria", "Dim.1", "Dim.2")]
su <- su[!su$categoria %in% c("ataque", "normal"), ]
su$rol <- ifelse(su$categoria %in% as.character(1:4), "Grupos del clustering", "Tipo de tráfico (suplementaria)")
su$categoria[su$rol == "Grupos del clustering"] <- c("G1 Cortos", "G2 Largos y lentos", "G3 Completa", "G4 Repetitivos")
su$rol[su$rol == "Grupos del clustering"] <- "Grupos del clustering (suplementaria)"
mapa <- rbind(ca_, su)
mapa$rol <- factor(mapa$rol, levels = c("Categorías activas", "Tipo de tráfico (suplementaria)", "Grupos del clustering (suplementaria)"))
aut <- tabla("acm_autovalores")$porcentaje_ajustado
f11 <- ggplot(mapa, aes(Dim.1, Dim.2, colour = rol, shape = rol)) + geom_hline(yintercept = 0, colour = grilla) +
  geom_vline(xintercept = 0, colour = grilla) + geom_point(size = 2.2) +
  geom_text_repel(aes(label = categoria), family = "Carlito", size = 2.6, show.legend = FALSE, max.overlaps = 30,
    box.padding = .35, min.segment.length = .2) +
  scale_colour_manual(values = c("Categorías activas" = tinta_2, "Tipo de tráfico (suplementaria)" = azul,
    "Grupos del clustering (suplementaria)" = naranja)) +
  scale_shape_manual(values = c(1, 16, 17)) +
  guides(colour = guide_legend(nrow = 1)) +
  labs(x = paste0("Dim 1: conversación completa ← → conversación a medias (", format(round(aut[1], 1), decimal.mark = ","), " %)"),
    y = paste0("Dim 2: consulta que se completa (arriba) frente a envío sin respuesta (", format(round(aut[2], 1), decimal.mark = ","), " %)"))
guardar_fig(f11, "fig11_mapa_acm", 12)
cat("Figuras guardadas en resultados/figuras_informe/\n")
