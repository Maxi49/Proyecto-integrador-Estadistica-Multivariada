# ETAPA 4 · Análisis de Correspondencias Simples (ACS) y Múltiples (ACM), con proyección suplementaria del cluster
# Produce: Figura 10 (mapa del ACS) y Figura 11 (mapa del ACM) del informe;
#   tablas: acs_contingencia, acs_asociacion (chi cuadrado, V de Cramér), acs_inercia, acm_autovalores (crudos y ajustados),
#   acm_categorias_contribuciones, acm_categorias_cos2, acm_eta2, acm_suplementarias_coordenadas.
# Figuras: resultados/figuras_informe/fig10_mapa_acs.png, fig11_mapa_acm.png
# Requiere haber corrido antes R/00_datos.R y R/03_cluster.R. Ejecutar desde la carpeta principal del proyecto.
library(ca)
library(FactoMineR)
set.seed(42)
base <- readRDS("resultados/base_con_clusters.rds")
conjuntos <- readRDS("resultados/conjuntos_congelados.rds")
X_cat <- conjuntos$X_cat
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

# Seis variables activas: proto_g, service_g, state_g, respuesta_destino (dpkts = 0) y dos numéricas
# discretizadas en terciles en la Etapa 0 (duracion_banda, bytes_origen_banda). tipo_trafico es suplementaria.
# Sus modalidades superan 5%; no se fusionan categorías adicionales.
frecuencias <- read.csv("resultados/tablas/frecuencias_X_cat.csv")
stopifnot(all(frecuencias$porcentaje >= 5), all(sapply(X_cat, is.factor)))

# ACS: tipo de tráfico y estado agrupado, para estudiar la tercera hipótesis.
tabla <- table(X_cat$tipo_trafico, X_cat$state_g)
acs <- ca::ca(tabla, nd = 2)
chi <- chisq.test(tabla, correct = FALSE)
guardar(data.frame(tipo_trafico = rownames(tabla), unclass(tabla)), "acs_contingencia")
guardar(data.frame(tipo_trafico = rownames(tabla), unclass(100 * prop.table(tabla, 1))), "acs_porcentajes_fila")
guardar(data.frame(dimension = seq_along(acs$sv), autovalor = acs$sv^2,
  porcentaje = 100 * acs$sv^2 / sum(acs$sv^2)), "acs_inercia")
guardar(data.frame(chi2 = unname(chi$statistic), gl = unname(chi$parameter), p = chi$p.value,
  cramer_v = sqrt(unname(chi$statistic) / (sum(tabla) * min(nrow(tabla) - 1, ncol(tabla) - 1))),
  frecuencia_esperada_min = min(chi$expected)), "acs_asociacion")
guardar(data.frame(categoria = rownames(tabla),
  sweep(acs$rowcoord[, 1:2, drop = FALSE], 2, acs$sv[1:2], "*")), "acs_filas")
guardar(data.frame(categoria = colnames(tabla),
  sweep(acs$colcoord[, 1:2, drop = FALSE], 2, acs$sv[1:2], "*")), "acs_columnas")

# El tipo de tráfico, la etiqueta y el cluster son suplementarios: no intervienen en los ejes.
# Así el mapa describe solo cómo es la conexión, y después se ve dónde caen los ataques (H3).
activas <- X_cat[, names(X_cat) != "tipo_trafico"]
datos_acm <- data.frame(activas, tipo_trafico = X_cat$tipo_trafico, label = base$label,
  cluster = base$cluster)
Q <- ncol(activas)
J <- sum(sapply(activas, nlevels))
suplementarias <- (Q + 1):ncol(datos_acm)
acm <- FactoMineR::MCA(datos_acm, quali.sup = suplementarias, ncp = J - Q, graph = FALSE)
ajustado <- ca::mjca(activas, nd = NA, lambda = "adjusted")
indicador <- ca::mjca(activas, nd = NA, lambda = "indicator")
# ca 0.72 entrega valores singulares: al cuadrarlos se obtienen los autovalores.
stopifnot(max(abs(indicador$sv^2 - acm$eig[, 1])) < 1e-8)
autovalores <- data.frame(dimension = seq_len(nrow(acm$eig)), autovalor = acm$eig[, 1],
  porcentaje_crudo = acm$eig[, 2], acumulado_crudo = acm$eig[, 3],
  autovalor_ajustado = 0, porcentaje_ajustado = 0)
n_aj <- length(ajustado$sv)
autovalores$autovalor_ajustado[1:n_aj] <- ajustado$sv^2
autovalores$porcentaje_ajustado[1:n_aj] <- 100 * ajustado$inertia.e
autovalores$acumulado_ajustado <- cumsum(autovalores$porcentaje_ajustado)
guardar(autovalores, "acm_autovalores")
guardar(data.frame(Q = Q, J = J, inercia_cruda = J / Q - 1,
  umbral = 1 / Q, ejes_sobre_umbral = sum(acm$eig[, 1] > 1 / Q),
  inercia_total_ajustada = ajustado$inertia.t,
  porcentaje_plano_ajustado = sum(autovalores$porcentaje_ajustado[1:2])), "acm_resumen")

# Se conservan todos los resultados; el informe interpreta el plano de dos dimensiones.
categorias <- ajustado$levelnames
coord <- data.frame(categoria = categorias, acm$var$coord)
contrib <- data.frame(categoria = categorias, acm$var$contrib)
cos2 <- data.frame(categoria = categorias, acm$var$cos2)
guardar(coord, "acm_categorias_coordenadas")
guardar(contrib, "acm_categorias_contribuciones")
guardar(cos2, "acm_categorias_cos2")
guardar(data.frame(variable = rownames(acm$var$eta2), acm$var$eta2), "acm_eta2")
guardar(data.frame(categoria = rownames(acm$quali.sup$coord), acm$quali.sup$coord), "acm_suplementarias_coordenadas")
guardar(data.frame(categoria = rownames(acm$quali.sup$cos2), acm$quali.sup$cos2), "acm_suplementarias_cos2")
guardar(data.frame(variable = rownames(acm$quali.sup$eta2), acm$quali.sup$eta2), "acm_suplementarias_eta2")
guardar(data.frame(id = base$id, cluster = base$cluster, acm$ind$coord[, 1:2]), "acm_individuos")

# Cruces para interpretar tres asociaciones con frecuencias observadas, sin causalidad.
for (variable in c("respuesta_destino", "duracion_banda", "bytes_origen_banda")) {
  t <- table(X_cat$tipo_trafico, X_cat[[variable]])
  guardar(data.frame(tipo_trafico = rownames(t), unclass(100 * prop.table(t, 1))), paste0("acm_cruce_", variable))
}
saveRDS(list(acs = acs, acm = acm, ajustado = ajustado, dimensiones_interpretadas = 2), "resultados/correspondencias.rds")
print(autovalores)
print(acm$var$eta2[, 1:2])

# FIGURAS DE LA ETAPA 4 (Figuras 10 y 11 del informe).
source("R/estilo_graficos.R", encoding = "UTF-8")   # fuente, paleta, tema y guardar_fig()

# Figura 10. Mapa del ACS: tipo de tráfico (filas) y estado de la conexión (columnas).
fil <- leer_tabla("acs_filas"); fil$rol <- "Tipo de tráfico"
col <- leer_tabla("acs_columnas"); col$rol <- "Estado de la conexión"
col$categoria <- c(CON_otros = "CON y otros", FIN = "FIN (cerrada)", INT = "INT (interrumpida)")[col$categoria]
acs_mapa <- rbind(fil, col)
inercia <- leer_tabla("acs_inercia")$porcentaje
f10 <- ggplot(acs_mapa, aes(Dim1, Dim2, colour = rol)) + geom_hline(yintercept = 0, colour = grilla) + geom_vline(xintercept = 0, colour = grilla) +
  geom_point(aes(shape = rol), size = 2.6) + geom_text_repel(aes(label = categoria), family = familia, size = 2.9,
    colour = tinta, box.padding = .4, show.legend = FALSE) +
  scale_colour_manual(values = c("Tipo de tráfico" = azul, "Estado de la conexión" = naranja)) +
  scale_shape_manual(values = c("Tipo de tráfico" = 16, "Estado de la conexión" = 17)) +
  labs(x = paste0("Dimensión 1 (", format(round(inercia[1], 1), decimal.mark = ","), " %)"), y = paste0("Dimensión 2 (", format(round(inercia[2], 1), decimal.mark = ","), " %)"))
f10 <- f10 + scale_x_continuous(labels = function(x) format(x, decimal.mark = ",")) +
  scale_y_continuous(labels = function(x) format(x, decimal.mark = ",")) +
  coord_equal()  # misma escala en los dos ejes: las distancias del mapa no se deforman
guardar_fig(f10, "fig10_mapa_acs", 8)

# Figura 11. Mapa del ACM: categorías activas en gris, suplementarias en color.
ca_ <- leer_tabla("acm_categorias_coordenadas")[, c("categoria", "Dim.1", "Dim.2")]
ca_$categoria <- c("proto_g:otros" = "protocolo otros", "proto_g:tcp" = "TCP", "proto_g:udp" = "UDP",
  "service_g:dns" = "dns", "service_g:http" = "http", "service_g:ninguno" = "servicio ninguno",
  "service_g:otros" = "servicio otros", "state_g:CON_otros" = "CON y otros", "state_g:FIN" = "FIN",
  "state_g:INT" = "INT", "respuesta_destino:con_respuesta" = "con respuesta",
  "respuesta_destino:sin_respuesta" = "sin respuesta", "duracion_banda:corta" = "duración corta",
  "duracion_banda:media" = "duración media", "duracion_banda:larga" = "duración larga",
  "bytes_origen_banda:bajos" = "bytes bajos", "bytes_origen_banda:medios" = "bytes medios",
  "bytes_origen_banda:altos" = "bytes altos")[ca_$categoria]
stopifnot(!anyNA(ca_$categoria))
ca_$rol <- "Categorías activas"
su <- leer_tabla("acm_suplementarias_coordenadas")[, c("categoria", "Dim.1", "Dim.2")]
su <- su[!su$categoria %in% c("ataque", "normal"), ]
su$rol <- ifelse(su$categoria %in% as.character(1:4), "Grupos del clustering", "Tipo de tráfico (suplementaria)")
su$categoria[su$rol == "Grupos del clustering"] <- c("G1 Cortos", "G2 Largos y lentos", "G3 Completa", "G4 Repetitivos")
su$rol[su$rol == "Grupos del clustering"] <- "Grupos del clustering (suplementaria)"
mapa <- rbind(ca_, su)
mapa$rol <- factor(mapa$rol, levels = c("Categorías activas", "Tipo de tráfico (suplementaria)", "Grupos del clustering (suplementaria)"))
aut <- leer_tabla("acm_autovalores")
# Las coordenadas son las principales del ACM estándar (matriz indicadora). Los porcentajes de los
# ejes son la inercia ajustada de Greenacre, que es la que cita el texto; se declaran junto a la cruda
# (34,9 % y 16,6 %) porque el plano crudo solo explica 51,6 %.
pct <- function(x) format(round(x, 1), decimal.mark = ",")
# Dos paneles con la misma escala en ambos ejes (coord_equal): mapa completo y ampliación de la zona
# donde se aglomeran las categorías, para que las etiquetas no se superpongan.
zoom <- list(x = c(-.85, .45), y = c(-.6, .8))
en_zoom <- mapa$Dim.1 > zoom$x[1] & mapa$Dim.1 < zoom$x[2] & mapa$Dim.2 > zoom$y[1] & mapa$Dim.2 < zoom$y[2]
base_mapa <- function(d, lim = NULL, tam = 2.5) {
  ggplot(d, aes(Dim.1, Dim.2, colour = rol, shape = rol)) + geom_hline(yintercept = 0, colour = grilla) +
    geom_vline(xintercept = 0, colour = grilla) + geom_point(size = 2) +
    geom_text_repel(aes(label = categoria), family = familia, size = tam, show.legend = FALSE, max.overlaps = Inf,
      box.padding = .6, point.padding = .3, min.segment.length = .1, segment.size = .2, force = 8, max.time = 3, seed = 42,
      nudge_x = ifelse(d$categoria == "Otros ataques", .25, 0)) +  # único empuje a mano: el rótulo tocaba el recuadro
    scale_colour_manual(values = c("Categorías activas" = tinta_2, "Tipo de tráfico (suplementaria)" = azul,
      "Grupos del clustering (suplementaria)" = naranja), drop = FALSE) +
    scale_shape_manual(values = c(1, 16, 17), drop = FALSE) +
    scale_x_continuous(labels = function(x) format(x, decimal.mark = ",")) +
    scale_y_continuous(labels = function(x) format(x, decimal.mark = ",")) +
    coord_equal(xlim = lim$x, ylim = lim$y)  # misma escala en los dos ejes: las distancias no se deforman
}
p_total <- base_mapa(mapa[!en_zoom, ]) +
  annotate("rect", xmin = zoom$x[1], xmax = zoom$x[2], ymin = zoom$y[1], ymax = zoom$y[2], fill = NA,
    colour = tinta_2, linetype = "dashed", linewidth = .3) +
  annotate("text", x = zoom$x[1], y = zoom$y[2] + .12, label = "ampliada a la derecha", hjust = 0,
    family = familia, size = 2.3, colour = tinta_2) +
  labs(title = "Mapa completo", x = NULL, y = paste0("Dim 2 (", pct(aut$porcentaje_ajustado[2]), " % ajustada; ",
    pct(aut$porcentaje_crudo[2]), " % cruda)"))
p_zoom <- base_mapa(mapa[en_zoom, ], zoom) +
  labs(title = "Ampliación de la zona central", x = NULL, y = NULL)
f11 <- (p_total + p_zoom) + plot_layout(guides = "collect", widths = c(1, 1.1)) &
  theme(legend.position = "bottom", legend.text = element_text(size = 8), plot.title = element_text(size = 9))
f11 <- f11 + plot_annotation(caption = paste0("Dim 1 (", pct(aut$porcentaje_ajustado[1]), " % de la inercia ajustada; ",
  pct(aut$porcentaje_crudo[1]), " % de la cruda): completa ← → a medias. Porcentajes ajustados según Greenacre."),
  theme = theme(plot.caption = element_text(colour = tinta_2, size = 8, hjust = .5)))
guardar_fig(f11, "fig11_mapa_acm", 12)
cat("Etapa 4: Figuras 10 y 11 guardadas en resultados/figuras_informe/\n")
