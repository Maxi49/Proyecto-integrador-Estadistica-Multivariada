# ESTILO COMÚN DE LAS FIGURAS DEL INFORME (no es una etapa de análisis).
# Cada script de etapa lo carga con source("R/estilo_graficos.R", encoding = "UTF-8") antes de graficar.
# Define: fuente, paleta, tema, etiquetas de las 12 variables, bloques y la función guardar_fig().
# Las figuras se guardan en resultados/figuras_informe/ (16 cm de ancho, 300 ppp, coma decimal).
library(ggplot2)
library(ggrepel)
library(patchwork)

# Carlito es la fuente del informe (métrica de Calibri); si no está instalada se usa la sans por defecto.
familia <- if ("Carlito" %in% systemfonts::system_fonts()$family) "Carlito" else "sans"

dir.create("resultados/figuras_informe", recursive = TRUE, showWarnings = FALSE)
guardar_fig <- function(grafico, nombre, alto = 9) ggsave(paste0("resultados/figuras_informe/", nombre, ".png"),
  grafico, width = 16, height = alto, units = "cm", dpi = 300, bg = "white")

# Lee una tabla CSV que escribió alguna etapa en resultados/tablas/.
leer_tabla <- function(nombre) read.csv(paste0("resultados/tablas/", nombre, ".csv"), fileEncoding = "UTF-8")

# Paleta: tinta en grises, azul y naranja para identidad, divergente azul-gris-rojo.
tinta <- "#0b0b0b"; tinta_2 <- "#52514e"; grilla <- "#e4e3df"; neutro <- "#f0efec"
azul <- "#2a78d6"; naranja <- "#eb6834"; rojo <- "#e34948"; gris_puntos <- "#c3c2b7"
tema <- theme_minimal(base_size = 9, base_family = familia) +
  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = grilla, linewidth = .3),
    axis.text = element_text(colour = tinta_2), axis.title = element_text(colour = tinta_2),
    plot.title = element_text(colour = tinta, face = "bold", size = 10),
    strip.text = element_text(colour = tinta, face = "bold"), legend.position = "top",
    legend.title = element_blank(), legend.text = element_text(colour = tinta_2))
theme_set(tema)

# Nombres descriptivos de las 12 variables y bloque conceptual de cada una (volumen, ritmo, repetición).
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
