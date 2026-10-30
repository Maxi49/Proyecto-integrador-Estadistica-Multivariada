# =====================================================================================================
#  PROYECTO INTEGRADOR · ANÁLISIS MULTIVARIADO DE FLUJOS DE RED (BASE UNSW-NB15)
# =====================================================================================================
#  Materia : Estadística Multivariada · Universidad Católica de Córdoba (UCC)
#  Docente : Prof. Silvana Malpassi
#  Autores : Maximiliano Gimenez, Lisandro Monti, Ignacio Marinelli, Mateo Camelino
#
#  CÓMO EJECUTARLO
#    1) Poner en UNA misma carpeta este archivo y el Excel "muestra_estratificada-simulado-de-ataques.xlsx".
#    2) Desde una consola:        Rscript Proyecto_Integrador_UNSW-NB15.R
#       Desde RStudio:            abrir el archivo (Reopen with Encoding > UTF-8) y apretar "Source",
#                                 o bien  source("Proyecto_Integrador_UNSW-NB15.R", encoding = "UTF-8")
#    Tarda menos de un minuto; la primera vez puede demorar más porque instala los paquetes que falten (requiere internet).
#
#  QUÉ PRODUCE
#    - En la consola: las salidas numéricas que aparecen en el informe, cada una con un encabezado del
#      tipo  "== Tabla 3 del informe: autovalores y varianza explicada ==".
#    - salidas/figuras/figura01_...png a figura11_...png : las 11 figuras del informe.
#    - salidas/tablas/*.csv : las tablas principales (copia de lo impreso en consola).
#
#  ESTRUCTURA (cada etapa se puede leer y correr por separado en RStudio: ver el menú de secciones)
#    ETAPA 0 · Exploración y preparación (calidad, descriptiva, supuestos)       -> Figuras 1, 2 y 3
#    ETAPA 1 · Análisis de Componentes Principales (ACP)                           -> Figuras 4 y 5
#    ETAPA 2 · Análisis Factorial (AF) y diagnóstico de estimadores                -> Figura 6
#    ETAPA 3 · Análisis de conglomerados (Ward y k-means)                          -> Figuras 7, 8 y 9
#    ETAPA 4 · Análisis de Correspondencias Simples (ACS) y Múltiples (ACM)        -> Figuras 10 y 11
#    ETAPA 6 · Integración de resultados (tabla síntesis)
#  Semilla fija (set.seed(42)): la corrida es reproducible y da siempre las mismas cifras.
# =====================================================================================================


# BLOQUE 0 · Paquetes, semilla, rutas y utilidades ----------------------------------------------------

# Paquetes necesarios. Los que falten se instalan automáticamente desde CRAN.
paquetes <- c("readxl",       # leer el Excel
              "psych",        # KMO, Bartlett, análisis paralelo, AF
              "GPArotation",  # rotaciones oblicuas (diagnóstico del AF)
              "cluster",      # silhouette
              "ca",           # análisis de correspondencias simples y múltiples (ajuste de Greenacre)
              "FactoMineR",   # ACM con variables suplementarias
              "ggplot2", "ggrepel", "patchwork",  # figuras
              "systemfonts")  # detectar la fuente Carlito de las figuras
faltan <- paquetes[!sapply(paquetes, requireNamespace, quietly = TRUE)]
if (length(faltan) > 0) {
  cat("Instalando paquetes que faltan:", paste(faltan, collapse = ", "), "\n")
  install.packages(faltan, repos = "https://cloud.r-project.org")
}
invisible(lapply(paquetes, library, character.only = TRUE))

options(width = 150, digits = 7)   # ancho de consola para que las tablas no se partan

# Semilla: se vuelve a fijar al comienzo de cada etapa (igual que en los scripts por etapa del repositorio).
set.seed(42)

# Ubicar la carpeta donde está este archivo. Funciona con Rscript (--file=), con source() y con RStudio;
# si no se puede detectar, se usa el directorio de trabajo.
carpeta_del_script <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", args[grep("^--file=", args)])
  if (length(f) > 0) return(dirname(normalizePath(f[1], mustWork = FALSE)))
  for (i in rev(seq_len(sys.nframe()))) {           # source("archivo.R")
    of <- sys.frame(i)$ofile
    if (!is.null(of)) return(dirname(normalizePath(of, mustWork = FALSE)))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {  # RStudio (ejecución por partes)
    ruta <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
    if (nzchar(ruta)) return(dirname(ruta))
  }
  getwd()
}
nombre_excel <- "muestra_estratificada-simulado-de-ataques.xlsx"
carpeta <- carpeta_del_script()
if (!file.exists(file.path(carpeta, nombre_excel))) carpeta <- getwd()
ruta_excel <- file.path(carpeta, nombre_excel)
if (!file.exists(ruta_excel))
  stop("No se encuentra '", nombre_excel, "'. Ponerlo en la misma carpeta que este script (", carpeta, ").")

# Carpetas de salida.
dir_figuras <- file.path(carpeta, "salidas", "figuras")
dir_tablas  <- file.path(carpeta, "salidas", "tablas")
dir.create(dir_figuras, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_tablas,  recursive = TRUE, showWarnings = FALSE)

# Utilidades de salida: encabezado de consola, guardado de tablas (CSV) y de figuras (PNG).
# Lee de vuelta una tabla CSV guardada (las figuras 10 y 11 parten de las tablas guardadas, igual que en el repositorio).
leer_tabla <- function(nombre) read.csv(file.path(dir_tablas, paste0(nombre, ".csv")), fileEncoding = "UTF-8")
encabezado <- function(texto) cat("\n== ", texto, " ==\n", sep = "")
guardar_tabla <- function(x, nombre) {
  write.csv(x, file.path(dir_tablas, paste0(nombre, ".csv")), row.names = FALSE, fileEncoding = "UTF-8", na = "")
  invisible(x)
}
# Figuras del informe: 16 cm de ancho, 300 ppp, fondo blanco.
guardar_fig <- function(grafico, archivo, alto = 9) ggsave(file.path(dir_figuras, archivo), grafico,
  width = 16, height = alto, units = "cm", dpi = 300, bg = "white")

# Estilo común de las figuras. Carlito es la fuente del informe; si no está instalada se usa la sans por defecto.
familia <- if ("Carlito" %in% systemfonts::system_fonts()$family) "Carlito" else "sans"
tinta <- "#0b0b0b"; tinta_2 <- "#52514e"; grilla <- "#e4e3df"; neutro <- "#f0efec"
azul <- "#2a78d6"; naranja <- "#eb6834"; rojo <- "#e34948"
theme_set(theme_minimal(base_size = 9, base_family = familia) +
  theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = grilla, linewidth = .3),
    axis.text = element_text(colour = tinta_2), axis.title = element_text(colour = tinta_2),
    plot.title = element_text(colour = tinta, face = "bold", size = 10),
    strip.text = element_text(colour = tinta, face = "bold"), legend.position = "top",
    legend.title = element_blank(), legend.text = element_text(colour = tinta_2)))

# Nombres descriptivos de las 12 variables y bloque conceptual (volumen, ritmo, repetición) de cada una.
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

cat("Proyecto Integrador UNSW-NB15 · Estadística Multivariada (UCC)\n")
cat("Carpeta de trabajo:", carpeta, "\n")
cat("R", R.version$major, ".", R.version$minor, " | fuente de las figuras: ", familia, "\n", sep = "")


# ETAPA 0 · Exploración y preparación ----------------------------------------------------------------
# Produce: Figura 1 (boxplots), Figura 2 (histogramas antes/después del log), Figura 3 (correlaciones);
#          Tablas 1 y 2 del informe, calidad de datos, atípicos y supuestos (determinante, KMO, Bartlett, MSA).
set.seed(42)

## 0.1 Lectura de la base y diccionario ----
# La hoja "muestra" tiene los 5.000 flujos; la hoja "diccionario" describe cada columna.
base <- read_excel(ruta_excel, sheet = "muestra")
info <- read_excel(ruta_excel, sheet = "diccionario")
info <- info[match(names(base), info$variable), ]
stopifnot(!anyNA(info$variable), !anyDuplicated(info$variable))
base_original <- base
diccionario <- data.frame(nombre = info$variable, descripcion = info$descripcion, unidad = info$unidad,
  tipo = ifelse(info$tipo %in% c("continua", "conteo"), "numérica", "categórica"))
encabezado("Dimensión de la base (flujos x columnas) y tipo de variable")
print(dim(base))
print(table(diccionario$tipo))
guardar_tabla(diccionario, "diccionario_variables")

# Las 12 variables numéricas del análisis: logaritmo de (x + 1) de variables muy asimétricas.
variables_num <- c("log_dur", "log_spkts", "log_sbytes", "log_dbytes", "log_sinpkt", "log_sjit",
  "log_synack", "log_ct_srv_src", "log_ct_srv_dst", "log_ct_src_ltm", "log_ct_src_dport_ltm", "log_ct_dst_sport_ltm")
X_num <- as.data.frame(base[variables_num])
stopifnot(all(is.finite(as.matrix(X_num))))
corto <- sub("^log_", "", names(X_num))

## 0.2 Calidad de los datos ----
# Se revisan faltantes, duplicados y valores incompatibles con la definición de cada variable. No se
# corrige ni se elimina nada: los controles solo documentan el estado de la base.
faltantes <- data.frame(variable = names(base), NA_encontrados = colSums(is.na(base)))
faltantes$textos_vacios <- sapply(base, function(x) sum(trimws(as.character(x)) == "", na.rm = TRUE))
columnas_perfil <- setdiff(names(base)[1:45], "id")
columnas_numericas <- names(base)[sapply(base, is.numeric)]
conteos <- info$variable[info$tipo == "conteo"]
valores <- as.matrix(base[columnas_numericas])
calidad <- data.frame(
  control = c("Valores NA", "Textos vacíos", "Filas duplicadas", "ID repetidos",
    "Perfiles originales duplicados sin id", "Celdas negativas", "Celdas no finitas sin NA",
    "Conteos no enteros", "TTL fuera de 0 a 255", "Ventana TCP fuera de 0 a 65535",
    "dur = 0 con spkts > 1 (revisar precisión)", "sbytes < spkts",
    "Indicadores usa_http/is_sm_ips_ports fuera de 0/1", "is_ftp_login fuera de 0/1",
    "label fuera de normal/ataque", "label y attack_cat inconsistentes"),
  cantidad = c(sum(is.na(base)), sum(faltantes$textos_vacios), sum(duplicated(base)),
    sum(duplicated(base$id)), sum(duplicated(base[columnas_perfil])),
    sum(valores < 0, na.rm = TRUE), sum(!is.finite(valores) & !is.na(valores)),
    sum(sapply(base[conteos], function(x) sum(abs(x - round(x)) > 1e-8, na.rm = TRUE))),
    sum(base$sttl < 0 | base$sttl > 255 | base$dttl < 0 | base$dttl > 255, na.rm = TRUE),
    sum(base$swin < 0 | base$swin > 65535 | base$dwin < 0 | base$dwin > 65535, na.rm = TRUE),
    sum(base$dur == 0 & base$spkts > 1), sum(base$sbytes < base$spkts),
    sum(!base$usa_http %in% c(0, 1)) + sum(!base$is_sm_ips_ports %in% c(0, 1)),
    sum(!base$is_ftp_login %in% c(0, 1)), sum(!base$label %in% c("normal", "ataque")),
    sum((base$attack_cat == "Normal") != (base$label == "normal"))))
ftp_revision <- base[!base$is_ftp_login %in% c(0, 1), c("id", "is_ftp_login", "ct_ftp_cmd")]
guardar_tabla(faltantes, "faltantes"); guardar_tabla(calidad, "calidad"); guardar_tabla(ftp_revision, "ftp_revision")
encabezado("Calidad de los datos (controles; cantidad = casos que no cumplen)")
print(calidad)
cat("\nFlujo con código FTP fuera de 0/1 (se conserva):\n"); print(as.data.frame(ftp_revision))

## 0.3 Valores atípicos (criterio de Tukey) ----
# Se usan las bisagras de Tukey (fivenum). Los atípicos NO se eliminan: un valor extremo no demuestra error.
atipicos <- matrix(FALSE, nrow = nrow(base), ncol = length(variables_num))
limites <- data.frame()
for (i in seq_along(variables_num)) {
  variable <- variables_num[i]
  x <- X_num[[variable]]
  cinco <- fivenum(x)
  q1 <- cinco[2]; q3 <- cinco[4]; ric <- q3 - q1
  inferior <- q1 - 1.5 * ric; superior <- q3 + 1.5 * ric
  atipicos[, i] <- x < inferior | x > superior
  limites <- rbind(limites, data.frame(variable = variable, q1_tukey = q1, mediana = cinco[3], q3_tukey = q3,
    limite_inferior = inferior, limite_superior = superior,
    bigote_inferior = min(x[x >= inferior & x <= superior]),
    bigote_superior = max(x[x >= inferior & x <= superior]), n_atipicos = sum(atipicos[, i])))
}
guardar_tabla(limites, "atipicos_limites")
encabezado("Atípicos por variable (límites de Tukey sobre log(x + 1))")
print(limites[, c("variable", "q1_tukey", "q3_tukey", "limite_inferior", "limite_superior", "n_atipicos")],
      digits = 3, row.names = FALSE)
cat("\nFlujos con al menos un atípico en las 12 variables:", sum(rowSums(atipicos) > 0),
    sprintf("(%.1f %% de %d)\n", 100 * mean(rowSums(atipicos) > 0), nrow(base)))

## 0.4 Descriptiva ----
# Tabla 1 del informe: resumen de las 12 variables del análisis (en log). El CSV incluye las 47 numéricas.
numericas <- diccionario$nombre[diccionario$tipo == "numérica"]
resumen <- data.frame()
for (variable in numericas) {
  x <- base[[variable]]
  q <- quantile(x, c(0, .25, .5, .75, 1), na.rm = TRUE, names = FALSE, type = 7)
  resumen <- rbind(resumen, data.frame(variable = variable, media = mean(x, na.rm = TRUE), desvio = sd(x, na.rm = TRUE),
    minimo = q[1], q1 = q[2], mediana = q[3], q3 = q[4], maximo = q[5], ceros = sum(x == 0, na.rm = TRUE)))
}
guardar_tabla(resumen, "resumen_numerico")
encabezado("Tabla 1 del informe: variables numéricas del análisis (12 log_)")
print(resumen[resumen$variable %in% variables_num, ], digits = 4, row.names = FALSE)
cat("\n(Ceros: dbytes, synack y sjit tienen ceros estructurales; ver columna 'ceros'.)\n")

categoricas <- diccionario$nombre[diccionario$tipo == "categórica"]
frecuencias <- data.frame()
for (variable in categoricas) {
  tabla_f <- table(base[[variable]], useNA = "ifany")
  frecuencias <- rbind(frecuencias, data.frame(variable = variable, categoria = names(tabla_f),
    frecuencia = as.integer(tabla_f), porcentaje = 100 * as.integer(tabla_f) / nrow(base)))
}
guardar_tabla(frecuencias, "frecuencias_categoricas")
encabezado("Composición de la muestra: tipo de tráfico y etiqueta")
print(frecuencias[frecuencias$variable %in% c("tipo_trafico", "label"), ], row.names = FALSE)

# Tabla 2 del informe: correlación de Pearson de cada variable log_ con ser ataque (1) o normal (0).
ataque <- as.numeric(base$label == "ataque")
cor_ataque <- data.frame(variable = variables_num, r = sapply(X_num, function(x) cor(x, ataque)),
  p = sapply(X_num, function(x) cor.test(x, ataque)$p.value), row.names = NULL)
guardar_tabla(cor_ataque, "correlacion_con_ataque")
encabezado("Tabla 2 del informe: correlación de cada variable con ser ataque")
print(cor_ataque[order(cor_ataque$r), ], digits = 3, row.names = FALSE)

## 0.5 Supuestos del análisis multivariado ----
# Correlaciones, determinante, KMO (adecuación muestral), MSA por variable y test de Bartlett (esfericidad).
correlaciones <- cor(X_num, method = "pearson")
kmo <- KMO(correlaciones)
bartlett <- cortest.bartlett(correlaciones, n = nrow(X_num))
msa <- data.frame(variable = names(kmo$MSAi), msa = as.numeric(kmo$MSAi))
piloto <- data.frame(determinante = det(correlaciones), kmo_global = kmo$MSA, msa_minima = min(kmo$MSAi),
  bartlett_chi2 = bartlett$chisq, bartlett_gl = bartlett$df, bartlett_p = bartlett$p.value)
guardar_tabla(data.frame(variable = rownames(correlaciones), correlaciones), "correlaciones")
guardar_tabla(msa, "msa_por_variable"); guardar_tabla(piloto, "piloto_supuestos")
encabezado("Supuestos (texto de la Etapa 0): determinante, KMO, Bartlett")
cat(sprintf("Determinante de la matriz de correlaciones: %.6f (= %.3e)\n", piloto$determinante, piloto$determinante))
cat(sprintf("KMO global: %.3f | MSA mínima: %.3f (%s)\n", kmo$MSA, min(kmo$MSAi), names(which.min(kmo$MSAi))))
cat(sprintf("Bartlett: chi2 = %.1f, gl = %d, p = %s\n", bartlett$chisq, bartlett$df,
            ifelse(bartlett$p.value < .001, "< 0,001", format(bartlett$p.value))))
encabezado("MSA por variable")
print(round(setNames(msa$msa, msa$variable), 3))
stopifnot(kmo$MSA >= .6, min(kmo$MSAi) >= .5, det(correlaciones) > 1e-5, bartlett$p.value < .05)

## 0.6 Variables categóricas del ACS/ACM (X_cat) ----
# Cuatro categóricas existentes + tres numéricas discretizadas en terciles (los cortes no usan la etiqueta de ataque).
cortes_dur <- unname(quantile(base$dur, c(1/3, 2/3), type = 7))
cortes_bytes <- unname(quantile(base$sbytes, c(1/3, 2/3), type = 7))
X_cat <- as.data.frame(base[c("tipo_trafico", "proto_g", "service_g", "state_g")])
X_cat$respuesta_destino <- ifelse(base$dpkts == 0, "sin_respuesta", "con_respuesta")
X_cat$duracion_banda <- cut(base$dur, c(-Inf, cortes_dur, Inf), labels = c("corta", "media", "larga"))
X_cat$bytes_origen_banda <- cut(base$sbytes, c(-Inf, cortes_bytes, Inf), labels = c("bajos", "medios", "altos"))
X_cat[] <- lapply(X_cat, factor)
frecuencias_cat <- data.frame()
for (variable in names(X_cat)) {
  tabla_f <- table(X_cat[[variable]])
  frecuencias_cat <- rbind(frecuencias_cat, data.frame(variable = variable, categoria = names(tabla_f),
    frecuencia = as.integer(tabla_f), porcentaje = 100 * as.integer(tabla_f) / nrow(base)))
}
stopifnot(!anyNA(X_cat), all(frecuencias_cat$porcentaje >= 5))   # ninguna categoría con menos de 5 %
guardar_tabla(frecuencias_cat, "frecuencias_X_cat")
encabezado("Tabla 9 del informe: variables categóricas y categorías finales")
print(frecuencias_cat, digits = 4, row.names = FALSE)
cat(sprintf("\nCortes en terciles: dur = %.4f y %.4f | sbytes = %.0f y %.0f\n",
            cortes_dur[1], cortes_dur[2], cortes_bytes[1], cortes_bytes[2]))
stopifnot(identical(base, base_original))   # la base original no se modificó

## 0.7 Figuras de la Etapa 0 ----
# Figura 1. Boxplots de las 12 variables (log, estandarizadas para compartir eje). Las cajas y los atípicos
# usan las bisagras de Tukey (fivenum), igual que la tabla de atípicos de 0.3.
Zbox <- as.data.frame(scale(X_num)); names(Zbox) <- corto
res_caja <- do.call(rbind, lapply(corto, function(v) {
  x <- Zbox[[v]]; f <- fivenum(x); ric <- f[4] - f[2]
  inf <- f[2] - 1.5 * ric; sup <- f[4] + 1.5 * ric
  data.frame(nombre = v, minimo = min(x[x >= inf]), q1 = f[2], mediana = f[3], q3 = f[4], maximo = max(x[x <= sup]),
    inf = inf, sup = sup)
}))
fuera <- do.call(rbind, lapply(corto, function(v) {
  r <- res_caja[res_caja$nombre == v, ]; x <- Zbox[[v]]; o <- x[x < r$inf | x > r$sup]
  if (length(o)) data.frame(nombre = v, valor = o)
}))
stopifnot(sum(rowSums(sapply(corto, function(v) {
  r <- res_caja[res_caja$nombre == v, ]; Zbox[[v]] < r$inf | Zbox[[v]] > r$sup
})) > 0) == 1715)
etiquetar <- function(d) {
  d$variable <- factor(d$nombre, levels = rev(orden), labels = rev(etiquetas[orden]))
  d$bloque <- factor(bloque[d$nombre], levels = c("Volumen", "Ritmo", "Repetición")); d
}
res_caja <- etiquetar(res_caja); fuera <- etiquetar(fuera)
f1 <- ggplot(res_caja, aes(y = variable)) +
  geom_point(data = fuera, aes(x = valor), colour = azul, size = .4, alpha = .35) +
  geom_boxplot(aes(xmin = minimo, xlower = q1, xmiddle = mediana, xupper = q3, xmax = maximo),
    stat = "identity", orientation = "y", width = .55, linewidth = .35, colour = tinta_2, fill = neutro) +
  facet_grid(bloque ~ ., scales = "free_y", space = "free_y") +
  labs(x = "Valor estandarizado de log(x + 1)", y = NULL)
guardar_fig(f1, "figura01_etapa0_boxplots.png", 11)

# Figura 2. Efecto de la transformación: bytes enviados antes y después del log.
h1 <- ggplot(base, aes(sbytes)) + geom_histogram(bins = 40, fill = azul, colour = "white", linewidth = .2) +
  scale_x_continuous(labels = function(x) paste(format(x / 1e6, decimal.mark = ","), "MB")) +
  labs(title = "Escala original", x = "Bytes enviados por el origen (sbytes)", y = "Flujos")
h2 <- ggplot(base, aes(log1p(sbytes))) + geom_histogram(bins = 40, fill = azul, colour = "white", linewidth = .2) +
  labs(title = "Escala log(x + 1)", x = "log(sbytes + 1)", y = NULL)
guardar_fig(h1 + h2, "figura02_etapa0_histogramas.png", 6.5)

# Figura 3. Mapa de calor de correlaciones, ordenado por bloque.
R <- correlaciones; dimnames(R) <- list(corto, corto)
cr <- as.data.frame(as.table(R[orden, orden]))
cr$Var1 <- factor(cr$Var1, levels = orden, labels = etiquetas[orden])
cr$Var2 <- factor(cr$Var2, levels = rev(orden), labels = rev(etiquetas[orden]))
f3 <- ggplot(cr, aes(Var1, Var2, fill = Freq)) + geom_tile(colour = "white", linewidth = .6) +
  geom_text(aes(label = formatC(Freq, format = "f", digits = 2, decimal.mark = ",")),
    family = familia, size = 2.2, colour = tinta) +
  scale_fill_gradient2(low = azul, mid = neutro, high = rojo, midpoint = 0, limits = c(-1, 1), name = "r") +
  labs(x = NULL, y = NULL) + theme(axis.text.x = element_text(angle = 40, hjust = 1), panel.grid = element_blank(),
    legend.position = "right", legend.title = element_text(colour = tinta_2))
guardar_fig(f3, "figura03_etapa0_correlaciones.png", 13)
cat("\nEtapa 0 terminada: Figuras 1 a 3 guardadas.\n")


# ETAPA 1 · Análisis de Componentes Principales (ACP) -------------------------------------------------
# Produce: Figura 4 (codo con línea de Kaiser), Figura 5 (biplot CP1-CP2);
#          Tablas 3 y 4 del informe (autovalores; correlaciones, contribuciones y cos2).
set.seed(42)

## 1.1 Modelo ----
# Se estandarizan las variables (scale. = TRUE) para que las de mayor varianza no dominen las componentes.
acp <- prcomp(X_num, scale. = TRUE)
acp_sin_escalar <- prcomp(X_num, scale. = FALSE)
autovalores_acp <- acp$sdev^2
tabla_autovalores <- data.frame(componente = seq_along(autovalores_acp), autovalor = autovalores_acp,
  porcentaje = 100 * autovalores_acp / sum(autovalores_acp),
  acumulado = 100 * cumsum(autovalores_acp) / sum(autovalores_acp))
guardar_tabla(tabla_autovalores, "acp_autovalores")
encabezado("Tabla 3 del informe: autovalores y varianza explicada (ACP)")
print(tabla_autovalores, digits = 4, row.names = FALSE)
cat(sprintf("\nSin estandarizar, la CP1 explicaría %.1f %% (con estandarizar: %.1f %%): por eso se estandariza.\n",
            100 * acp_sin_escalar$sdev[1]^2 / sum(acp_sin_escalar$sdev^2), tabla_autovalores$porcentaje[1]))

## 1.2 Cuántas componentes retener ----
# Criterio de Kaiser (autovalor > 1), contrastado con el codo (Figura 4) y con el significado de los ejes.
n_componentes <- sum(autovalores_acp > 1)
cat("Componentes retenidas (autovalor > 1):", n_componentes, "\n")

## 1.3 Correlaciones, contribuciones y cos2 ----
correlaciones_acp <- cor(X_num, acp$x)     # correlación variable-componente (cargas del ACP estandarizado)
contribuciones_acp <- 100 * acp$rotation^2  # contribución (%) de cada variable a cada componente
cos2_acp <- correlaciones_acp^2             # calidad de representación
nombres_cp <- paste0("PC", seq_len(n_componentes))
guardar_tabla(data.frame(variable = rownames(correlaciones_acp), correlaciones_acp[, 1:n_componentes]), "acp_correlaciones")
guardar_tabla(data.frame(variable = rownames(contribuciones_acp), contribuciones_acp[, 1:n_componentes]), "acp_contribuciones")
guardar_tabla(data.frame(variable = rownames(cos2_acp), cos2_acp[, 1:n_componentes]), "acp_cos2")
encabezado("Tabla 4 del informe: correlación de cada variable con las componentes")
print(round(correlaciones_acp[, 1:n_componentes], 3))
encabezado("Contribuciones (%) de cada variable a las componentes")
print(round(contribuciones_acp[, 1:n_componentes], 2))
encabezado("Tabla 4 del informe: cos2 (calidad de representación)")
print(round(cos2_acp[, 1:n_componentes], 3))
cat("\ncos2 acumulado en las componentes retenidas, por variable:\n")
print(round(rowSums(cos2_acp[, 1:n_componentes]), 3))

# Puntajes y flujos extremos (distancia ajustada por la varianza de cada componente).
puntajes <- acp$x[, 1:n_componentes, drop = FALSE]
distancia <- rowSums(sweep(puntajes, 2, acp$sdev[1:n_componentes], "/")^2)
extremos <- order(distancia, decreasing = TRUE)[1:3]
guardar_tabla(data.frame(base[extremos, c("id", "tipo_trafico", "dur", "spkts", "dpkts", "sbytes", "dbytes")],
  puntajes[extremos, , drop = FALSE], distancia = distancia[extremos]), "acp_extremos")

## 1.4 Figuras de la Etapa 1 ----
# Figura 4. Codo del ACP con la línea de Kaiser.
av <- tabla_autovalores
f4 <- ggplot(av, aes(componente, autovalor)) + geom_hline(yintercept = 1, colour = tinta_2, linetype = "dashed", linewidth = .3) +
  geom_line(colour = azul, linewidth = .6) + geom_point(colour = azul, size = 2) +
  geom_point(data = av[1:3, ], colour = azul, size = 3.2) +
  annotate("text", x = 11.8, y = 1.18, label = "Kaiser: autovalor = 1", hjust = 1, family = familia, size = 2.8, colour = tinta_2) +
  scale_x_continuous(breaks = 1:12) + labs(x = "Componente", y = "Autovalor")
guardar_fig(f4, "figura04_etapa1_codo_acp.png", 6.5)

# Figura 5. Biplot CP1-CP2: flujos coloreados por tipo de tráfico (todos los puntos, sin recorte), flechas de
# variables, centro (media) de cada tipo y los tres flujos extremos del texto rotulados. Las flechas son la
# correlación de cada variable con la componente multiplicada por `escala` (se declara al pie de la figura).
pt <- data.frame(puntajes[, 1:2]); names(pt) <- c("CP1", "CP2"); pt$tipo <- base$tipo_trafico
centros <- aggregate(cbind(CP1, CP2) ~ tipo, pt, mean)
carg <- data.frame(variable = rownames(correlaciones_acp), correlaciones_acp[, 1:n_componentes])
carg$etq <- sub(" \\(.*", "", etiquetas[sub("^log_", "", carg$variable)])
escala <- 4.5
carg$x <- escala * carg$PC1; carg$y <- escala * carg$PC2
carg$lado <- ifelse(carg$x < 0, "izq", "der")   # la etiqueta va del lado hacia donde apunta la flecha
# Los tres flujos que describe el texto: menor CP1, mayor CP2 y menor CP2 (salen 127446, 97189 y 44648).
i_ext <- c(which.min(pt$CP1), which.max(pt$CP2), which.min(pt$CP2))
extremos_fig <- pt[i_ext, ]
extremos_fig$etq <- paste("Flujo", base$id[i_ext])
colores_tipo <- c(Normal = azul, Exploits = naranja, Fuzzers = "#3a9a5b", Reconnaissance = "#8b5cc7", "Otros ataques" = rojo)
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
guardar_fig(f5, "figura05_etapa1_biplot.png", 11.5)
cat("\nEtapa 1 terminada: Figuras 4 y 5 guardadas.\n")


# ETAPA 2 · Análisis Factorial (AF) y diagnóstico de estimadores --------------------------------------
# Produce: Figura 6 (análisis paralelo); Tabla 5 (matriz de patrón, comunalidades, unicidades), ajuste (RMSEA, TLI)
#          y Tabla 6 (comparación ACP-AF); diagnóstico comparativo de estimadores (minres, ml, pa, gls).
set.seed(42)

## 2.1 Supuestos y número de factores ----
R_af <- cor(X_num)
kmo_af <- KMO(R_af)
bartlett_af <- cortest.bartlett(R_af, n = nrow(X_num))
stopifnot(det(R_af) > .00001, kmo_af$MSA >= .6, min(kmo_af$MSAi) >= .5, bartlett_af$p.value < .05)

# Análisis paralelo: compara los autovalores observados con los de datos aleatorios. fa.parallel devuelve en
# fa.sim / pc.sim el PROMEDIO de las 100 simulaciones (por eso la Figura 6 dice "promedio" y no "percentil 95").
options(mc.cores = 1)
paralelo <- suppressWarnings(fa.parallel(X_num, fa = "both", fm = "minres", n.iter = 100, plot = FALSE))
tabla_paralelo <- data.frame(dimension = seq_along(paralelo$fa.values),
  factor_observado = paralelo$fa.values, factor_simulado = paralelo$fa.sim,
  componente_observado = paralelo$pc.values, componente_simulado = paralelo$pc.sim)
guardar_tabla(tabla_paralelo, "af_paralelo")
encabezado("Análisis paralelo (Figura 6 del informe): autovalores observados vs. datos al azar")
print(round(tabla_paralelo[1:6, ], 3), row.names = FALSE)
cat("El análisis paralelo sugiere", paralelo$nfact, "factores; Kaiser y el paralelo de componentes indican 3.\n")

# Se retienen 3 factores: el cuarto autovalor (0,13) apenas supera al azar y solo parte en dos el bloque de
# repetición. Se prioriza la simplicidad y la interpretabilidad (decisión del grupo).
n_factores <- 3

## 2.2 Solución impropia con minres (caso Heywood) ----
minres <- suppressWarnings(fa(X_num, nfactors = n_factores, fm = "minres", rotate = "varimax", scores = "none"))
diag_minres <- data.frame(metodo = "minres", n_factores = n_factores, comunalidad_max = max(minres$communality),
  unicidad_min = min(minres$uniquenesses), heywood = any(minres$uniquenesses < 0))
guardar_tabla(diag_minres, "af_diagnostico_minres")
encabezado("Diagnóstico minres: ¿hay unicidades negativas (caso Heywood)?")
print(diag_minres, row.names = FALSE)

## 2.3 Estimación final: máxima verosimilitud con varimax ----
# Minres produce una unicidad negativa en log_spkts; ML con unicidad mínima 0,005 permite una solución
# descriptiva y se informa que ese parámetro queda en el límite.
af <- factanal(X_num, factors = n_factores, rotation = "varimax", scores = "regression",
  control = list(lower = .005))
cargas <- unclass(af$loadings)
colnames(cargas) <- paste0("F", seq_len(n_factores))
patron <- cargas
patron[abs(patron) < .4] <- NA   # se ocultan cargas menores que 0,40
diferencia <- apply(abs(cargas), 1, function(x) { x <- sort(x, decreasing = TRUE); x[1] - x[2] })
n_cargas <- rowSums(abs(cargas) >= .4)
guardar_tabla(data.frame(variable = rownames(cargas), cargas, comunalidad = 1 - af$uniquenesses,
  unicidad = af$uniquenesses, diferencia = diferencia, cargas_mayores_040 = n_cargas), "af_cargas_completas")
guardar_tabla(data.frame(variable = rownames(cargas), patron, comunalidad = 1 - af$uniquenesses,
  unicidad = af$uniquenesses), "af_patron")
encabezado("Tabla 5 del informe: matriz de patrón (cargas >= 0,40), comunalidades (h2) y unicidades (u2)")
print(data.frame(round(patron, 2), h2 = round(1 - af$uniquenesses, 3), u2 = round(af$uniquenesses, 3)), na.print = "")
encabezado("Cargas completas (sin ocultar)")
print(round(cargas, 3))

varianza_af <- data.frame(factor = colnames(cargas), suma_cargas2 = colSums(cargas^2),
  porcentaje_total = 100 * colSums(cargas^2) / ncol(X_num), porcentaje_comun = 100 * colSums(cargas^2) / sum(cargas^2))
guardar_tabla(varianza_af, "af_varianza")
encabezado("Varianza explicada por cada factor (Tabla 6 del informe: comparación ACP-AF)")
print(varianza_af, digits = 4, row.names = FALSE)
cat(sprintf("Varianza total explicada por los 3 factores (AF): %.1f %%\n", sum(varianza_af$porcentaje_total)))
cat(sprintf("Varianza acumulada de las 3 primeras componentes (ACP): %.1f %%\n", tabla_autovalores$acumulado[3]))

## 2.4 Bondad de ajuste ----
# RMSR sobre los residuos; RMSEA y TLI no dependen del n del mismo modo que el chi cuadrado.
residuos <- R_af - tcrossprod(cargas)
rmsr <- sqrt(mean(residuos[lower.tri(residuos)]^2))
n <- nrow(X_num); p <- ncol(X_num)
chi2_nulo <- -(n - 1 - (2 * p + 5) / 6) * log(det(R_af)); gl_nulo <- p * (p - 1) / 2
rmsea <- sqrt(max(unname(af$STATISTIC) - af$dof, 0) / (af$dof * (n - 1)))
tli <- (chi2_nulo / gl_nulo - unname(af$STATISTIC) / af$dof) / (chi2_nulo / gl_nulo - 1)
ajuste_af <- data.frame(n_factores = n_factores, rmsr = rmsr, rmsea = rmsea, tli = tli,
  chi2 = unname(af$STATISTIC), gl = af$dof, p_modelo = af$PVAL, comunalidad_min = min(1 - af$uniquenesses),
  unicidad_min = min(af$uniquenesses), unicidades_limite = sum(af$uniquenesses <= .00501),
  cruces_ambiguos = sum(n_cargas > 1 & diferencia < .2))
guardar_tabla(ajuste_af, "af_ajuste")
encabezado("Ajuste del AF (texto de la Etapa 2): chi2, RMSR, RMSEA, TLI")
print(round(unlist(ajuste_af), 4))

## 2.5 Diagnóstico comparativo de estimadores (anexo del AF) ----
# Compara 3 vs 4 factores x (minres, ml, pa, gls) x (varimax, oblimin) para justificar la elección de 3 factores y
# del estimador ML. Bloques esperados por la hipótesis 1: volumen, tiempo/ritmo, contexto (repetición).
bloque_h1 <- c(log_spkts = "vol", log_sbytes = "vol", log_dbytes = "vol",
  log_dur = "tmp", log_sinpkt = "tmp", log_sjit = "tmp", log_synack = "tmp",
  log_ct_srv_src = "ctx", log_ct_srv_dst = "ctx", log_ct_src_ltm = "ctx",
  log_ct_src_dport_ltm = "ctx", log_ct_dst_sport_ltm = "ctx")
filas <- list()
for (k in 3:4) for (m in c("minres", "ml", "pa", "gls")) for (rot in c("varimax", "oblimin")) {
  aviso <- character()
  f <- withCallingHandlers(
    tryCatch(fa(X_num, nfactors = k, fm = m, rotate = rot, n.obs = nrow(X_num)), error = function(e) NULL),
    warning = function(w) { aviso <<- c(aviso, conditionMessage(w)); invokeRestart("muffleWarning") })
  if (is.null(f)) next
  L <- unclass(f$loadings); com <- f$communality; uni <- f$uniquenesses
  ord <- t(apply(abs(L), 1, sort, decreasing = TRUE)); dif <- ord[, 1] - ord[, 2]
  n04 <- rowSums(abs(L) >= .4)
  asig <- apply(abs(L), 1, which.max)          # cada variable se asigna al factor de mayor carga
  grupos <- split(rownames(L), asig)
  puros <- sum(sapply(grupos, function(v) {    # ¿cada factor agrupa exactamente un bloque completo de la H1?
    b <- unique(bloque_h1[v]); length(b) == 1 && length(v) == sum(bloque_h1 == b) }))
  prop <- f$Vaccounted
  filas[[length(filas) + 1]] <- data.frame(n_factores = k, metodo = m, rotacion = rot,
    heywood = any(com >= 1 | uni <= .005), comunalidad_max = max(com), unicidad_min = min(uni),
    rmsr = f$rms, tli = f$TLI, rmsea = f$RMSEA[1], pct_var_acum = 100 * tail(prop["Cumulative Var", ], 1),
    sin_carga_040 = sum(n04 == 0), cruces_dif_menor_020 = sum(n04 > 1 & dif < .2),
    bloques_H1_recuperados = puros, avisos = length(aviso))
}
comparativo_af <- do.call(rbind, filas)
guardar_tabla(comparativo_af, "af_diagnostico_comparativo")
encabezado("Diagnóstico de estimadores del AF (3 y 4 factores; minres, ml, pa, gls; varimax y oblimin)")
print(format(comparativo_af, digits = 3), row.names = FALSE)

## 2.6 Figura de la Etapa 2 ----
# Figura 6. Análisis paralelo de factores.
par_af <- tabla_paralelo[1:8, ]
pa <- rbind(data.frame(dimension = par_af$dimension, valor = par_af$factor_observado, serie = "Datos observados"),
  data.frame(dimension = par_af$dimension, valor = par_af$factor_simulado, serie = "Datos al azar (promedio de 100 simulaciones)"))
pa$serie <- factor(pa$serie, levels = c("Datos observados", "Datos al azar (promedio de 100 simulaciones)"))
f6 <- ggplot(pa, aes(dimension, valor, colour = serie)) + geom_line(linewidth = .6) + geom_point(size = 2) +
  scale_colour_manual(values = c("Datos observados" = azul, "Datos al azar (promedio de 100 simulaciones)" = naranja)) +
  scale_x_continuous(breaks = 1:8) + labs(x = "Factor", y = "Autovalor")
guardar_fig(f6, "figura06_etapa2_paralelo_af.png", 6.5)
cat("\nEtapa 2 terminada: Figura 6 guardada.\n")


# ETAPA 3 · Análisis de conglomerados (Ward y k-means) ------------------------------------------------
# Produce: Figura 7 (elección de k), Figura 8 (dendrograma de variables), Figura 9 (perfiles de los grupos);
#          Tabla C1 (WSS y silhouette), Tablas 7 y 8 (perfil y composición de los grupos), cruces y ARI.
set.seed(42)

## 3.1 Distancias y jerárquico de Ward ----
Z <- scale(X_num)                                  # variables estandarizadas
distancias <- dist(Z, method = "euclidean")
jerarquico <- hclust(distancias, method = "ward.D2")

## 3.2 Elección de k: codo (WSS) y silhouette para k = 2..8 ----
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
}
guardar_tabla(metricas, "cluster_metricas")
encabezado("Tabla C1 del informe: suma de cuadrados dentro de grupos y silhouette según k")
print(metricas, digits = 4, row.names = FALSE)

# El silhouette casi empata entre k = 2, 4 y 6 (0,328; 0,327; 0,333). k = 2 no separa normal de ataque y k = 6
# deja dos grupos con silhouette menor a 0,15. El codo se quiebra en 4 y esa partición se mantiene al repetirla
# con los puntajes del ACP. Se retiene k = 4 (decisión del grupo).
k_elegido <- 4
km <- modelos_km[[as.character(k_elegido)]]
ward <- cutree(jerarquico, k_elegido)
guardar_tabla(data.frame(cluster = 1:k_elegido,
  silhouette = summary(silhouette(km$cluster, distancias))$clus.avg.widths), "cluster_silhouette")

## 3.3 Comparación de particiones: Ward vs k-means vs ACP ----
# El ARI (índice de Rand ajustado) compara particiones sin depender de la numeración de las etiquetas.
ari <- function(a, b) {
  t <- table(a, b)
  observado <- sum(choose(t, 2))
  esperado <- sum(choose(rowSums(t), 2)) * sum(choose(colSums(t), 2)) / choose(sum(t), 2)
  maximo <- (sum(choose(rowSums(t), 2)) + sum(choose(colSums(t), 2))) / 2
  (observado - esperado) / (maximo - esperado)
}
# Los puntajes del ACP conservan la ponderación por sus autovalores: no se reescalan.
set.seed(42)
km_acp <- kmeans(puntajes, centers = k_elegido, nstart = 25, iter.max = 100)
ward_acp <- cutree(hclust(dist(puntajes), method = "ward.D2"), k_elegido)
cruce_wk <- as.data.frame.matrix(table(Ward = ward, Kmeans = km$cluster))
cruce_km_acp <- as.data.frame.matrix(table(Kmeans_log = km$cluster, Kmeans_ACP = km_acp$cluster))
cruce_w_acp <- as.data.frame.matrix(table(Ward_log = ward, Ward_ACP = ward_acp))
comparaciones <- data.frame(k = k_elegido, ARI_ward_kmeans = ari(ward, km$cluster),
  ARI_kmeans_acp = ari(km$cluster, km_acp$cluster), ARI_ward_acp = ari(ward, ward_acp))
guardar_tabla(cruce_wk, "cluster_cruce_ward_kmeans"); guardar_tabla(cruce_km_acp, "cluster_cruce_acp")
guardar_tabla(cruce_w_acp, "cluster_cruce_ward_acp"); guardar_tabla(comparaciones, "cluster_comparaciones")
encabezado("Tabla cruzada Ward (filas) vs k-means (columnas), k = 4")
print(table(Ward = ward, Kmeans = km$cluster))
encabezado("Tabla cruzada k-means sobre las 12 variables vs k-means sobre puntajes del ACP")
print(table(Kmeans_log = km$cluster, Kmeans_ACP = km_acp$cluster))
encabezado("Tabla cruzada Ward sobre las 12 variables vs Ward sobre puntajes del ACP")
print(table(Ward_log = ward, Ward_ACP = ward_acp))
encabezado("Índice de Rand ajustado (ARI)")
print(round(comparaciones, 3), row.names = FALSE)

## 3.4 Perfil de los grupos de k-means ----
originales <- sub("^log_", "", names(X_num))
medias_originales <- aggregate(base[originales], list(cluster = km$cluster), mean)
medias_estandarizadas <- aggregate(as.data.frame(Z), list(cluster = km$cluster), mean)
tamanos <- data.frame(cluster = 1:k_elegido, n = as.integer(table(km$cluster)),
  porcentaje = 100 * as.integer(table(km$cluster)) / nrow(base))
prop_ataques <- aggregate(as.numeric(base$label == "ataque"), list(cluster = km$cluster), mean)
contexto <- as.data.frame(table(cluster = km$cluster, tipo_trafico = base$tipo_trafico))
guardar_tabla(medias_originales, "cluster_medias_originales")
guardar_tabla(medias_estandarizadas, "cluster_medias_estandarizadas")
guardar_tabla(tamanos, "cluster_tamanos"); guardar_tabla(prop_ataques, "cluster_proporcion_ataques")
guardar_tabla(contexto, "cluster_contexto")
encabezado("Tabla 7 del informe: tamaño de cada grupo y % de ataques")
print(data.frame(tamanos, pct_ataques = 100 * prop_ataques$x), digits = 4, row.names = FALSE)
encabezado("Tabla 7 del informe: promedios en unidades originales por grupo")
print(medias_originales, digits = 4, row.names = FALSE)
encabezado("Perfil estandarizado de los grupos (Figura 9 del informe)")
print(round(medias_estandarizadas, 2), row.names = FALSE)
encabezado("Tabla 8 del informe: composición de cada grupo según tipo de tráfico (% por fila)")
print(round(100 * prop.table(table(Grupo = km$cluster, Tipo = base$tipo_trafico), 1), 1))

## 3.5 Conglomerados de variables ----
# Distancia euclidiana entre las columnas estandarizadas, Ward.D2: da los tres bloques (volumen, ritmo, repetición).
jerarquico_vars <- hclust(dist(t(Z)), method = "ward.D2")
bloques_vars <- data.frame(variable = names(X_num), bloque = cutree(jerarquico_vars, 3))
guardar_tabla(bloques_vars, "cluster_variables_bloques")
encabezado("Bloques de variables (corte del dendrograma en 3 grupos)")
print(bloques_vars, row.names = FALSE)

# Se agregan las asignaciones a la base para las etapas siguientes (la hoja original no se modifica).
base$cluster <- factor(km$cluster)
base$cluster_ward <- factor(ward)
base$cluster_acp <- factor(km_acp$cluster)
guardar_tabla(data.frame(id = base$id, cluster = km$cluster, cluster_ward = ward, cluster_acp = km_acp$cluster),
              "cluster_asignaciones")

## 3.6 Figuras de la Etapa 3 ----
# Los nombres G1 a G4 se asignan por posición: si cambia la numeración de k-means (semilla, versión de R) hay
# que revisarlos. Tamaños esperados: Tabla 7 del informe.
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
guardar_fig(p_wss + p_sil, "figura07_etapa3_eleccion_k.png", 7)

# Figura 8. Dendrograma de variables (Ward), con los tres bloques recuadrados.
hv <- jerarquico_vars
hv$labels <- sub(" \\(.*", "", etiquetas[sub("^log_", "", hv$labels)])
png(file.path(dir_figuras, "figura08_etapa3_dendrograma_variables.png"), width = 16, height = 8, units = "cm", res = 300, family = familia)
par(mar = c(1, 4.5, .5, .5), cex = .7, col.axis = tinta_2, fg = tinta_2)
plot(hv, hang = -1, main = "", xlab = "", sub = "", ylab = "Altura (Ward)", col = tinta_2, lwd = .8)
rect.hclust(hv, k = 3, border = c(azul, naranja, "#1baf7a"))
invisible(dev.off())

# Figura 9. Medias estandarizadas por grupo (mapa de calor divergente).
me <- medias_estandarizadas
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
guardar_fig(f9, "figura09_etapa3_perfiles_grupos.png", 9)
cat("\nEtapa 3 terminada: Figuras 7 a 9 guardadas.\n")


# ETAPA 4 · Análisis de Correspondencias Simples (ACS) y Múltiples (ACM) ------------------------------
# Produce: Figura 10 (mapa del ACS), Figura 11 (mapa del ACM); Tabla 10 (estado según tipo de tráfico),
#          chi cuadrado y V de Cramér, inercias, y Tabla 11 (contribuciones) con cos2, eta2 y suplementarias.
set.seed(42)

## 4.1 ACS: tipo de tráfico por estado de la conexión ----
tabla_acs <- table(X_cat$tipo_trafico, X_cat$state_g)
acs <- ca::ca(tabla_acs, nd = 2)
chi <- chisq.test(tabla_acs, correct = FALSE)
v_cramer <- sqrt(unname(chi$statistic) / (sum(tabla_acs) * min(nrow(tabla_acs) - 1, ncol(tabla_acs) - 1)))
inercia_acs <- data.frame(dimension = seq_along(acs$sv), autovalor = acs$sv^2, porcentaje = 100 * acs$sv^2 / sum(acs$sv^2))
asociacion_acs <- data.frame(chi2 = unname(chi$statistic), gl = unname(chi$parameter), p = chi$p.value,
  cramer_v = v_cramer, frecuencia_esperada_min = min(chi$expected))
guardar_tabla(data.frame(tipo_trafico = rownames(tabla_acs), unclass(tabla_acs)), "acs_contingencia")
guardar_tabla(data.frame(tipo_trafico = rownames(tabla_acs), unclass(100 * prop.table(tabla_acs, 1))), "acs_porcentajes_fila")
guardar_tabla(inercia_acs, "acs_inercia"); guardar_tabla(asociacion_acs, "acs_asociacion")
acs_filas <- data.frame(categoria = rownames(tabla_acs), sweep(acs$rowcoord[, 1:2, drop = FALSE], 2, acs$sv[1:2], "*"))
acs_columnas <- data.frame(categoria = colnames(tabla_acs), sweep(acs$colcoord[, 1:2, drop = FALSE], 2, acs$sv[1:2], "*"))
guardar_tabla(acs_filas, "acs_filas"); guardar_tabla(acs_columnas, "acs_columnas")
encabezado("Tabla de contingencia del ACS: tipo de tráfico x estado de la conexión (frecuencias)")
print(addmargins(tabla_acs))
encabezado("Tabla 10 del informe: estado de la conexión según tipo de tráfico (% por fila)")
print(round(100 * prop.table(tabla_acs, 1), 1))
encabezado("Asociación del ACS: chi cuadrado y V de Cramér")
cat(sprintf("chi2 = %.1f, gl = %d, p %s | V de Cramér = %.3f | frecuencia esperada mínima = %.1f\n",
  chi$statistic, chi$parameter, ifelse(chi$p.value < .001, "< 0,001", paste("=", format(chi$p.value))),
  v_cramer, min(chi$expected)))
encabezado("Inercia (autovalores) de cada dimensión del ACS")
print(round(inercia_acs, 4), row.names = FALSE)
encabezado("Coordenadas principales del ACS (Figura 10 del informe)")
coord_acs <- rbind(acs_filas[-1], acs_columnas[-1]); rownames(coord_acs) <- c(acs_filas$categoria, acs_columnas$categoria)
print(round(coord_acs, 3))

## 4.2 ACM: seis variables activas ----
# Activas: proto_g, service_g, state_g, respuesta_destino (dpkts = 0) y dos numéricas en terciles (duracion_banda,
# bytes_origen_banda). El tipo de tráfico, la etiqueta y el cluster son SUPLEMENTARIOS: no intervienen en los ejes,
# así el mapa describe solo cómo es la conexión y después se ve dónde caen los ataques.
activas <- X_cat[, names(X_cat) != "tipo_trafico"]
datos_acm <- data.frame(activas, tipo_trafico = X_cat$tipo_trafico, label = base$label, cluster = base$cluster)
Q <- ncol(activas)
J <- sum(sapply(activas, nlevels))
suplementarias <- (Q + 1):ncol(datos_acm)
acm <- FactoMineR::MCA(datos_acm, quali.sup = suplementarias, ncp = J - Q, graph = FALSE)
ajustado <- ca::mjca(activas, nd = NA, lambda = "adjusted")     # inercia ajustada de Greenacre
indicador <- ca::mjca(activas, nd = NA, lambda = "indicator")
stopifnot(max(abs(indicador$sv^2 - acm$eig[, 1])) < 1e-8)       # ca entrega valores singulares: al cuadrarlos, autovalores

autovalores_acm <- data.frame(dimension = seq_len(nrow(acm$eig)), autovalor = acm$eig[, 1],
  porcentaje_crudo = acm$eig[, 2], acumulado_crudo = acm$eig[, 3], autovalor_ajustado = 0, porcentaje_ajustado = 0)
n_aj <- length(ajustado$sv)
autovalores_acm$autovalor_ajustado[1:n_aj] <- ajustado$sv^2
autovalores_acm$porcentaje_ajustado[1:n_aj] <- 100 * ajustado$inertia.e
autovalores_acm$acumulado_ajustado <- cumsum(autovalores_acm$porcentaje_ajustado)
guardar_tabla(autovalores_acm, "acm_autovalores")
resumen_acm <- data.frame(Q = Q, J = J, inercia_cruda = J / Q - 1, umbral = 1 / Q,
  ejes_sobre_umbral = sum(acm$eig[, 1] > 1 / Q), inercia_total_ajustada = ajustado$inertia.t,
  porcentaje_plano_ajustado = sum(autovalores_acm$porcentaje_ajustado[1:2]))
guardar_tabla(resumen_acm, "acm_resumen")
encabezado("Autovalores del ACM: crudos y ajustados (Greenacre)")
print(round(autovalores_acm[1:6, ], 4), row.names = FALSE)
cat(sprintf("\nQ = %d variables activas, J = %d categorías. Inercia total cruda = J/Q - 1 = %.3f; autovalor medio 1/Q = %.4f\n",
            Q, J, J / Q - 1, 1 / Q))
cat(sprintf("Plano 1-2: %.1f %% de la inercia ajustada (%.1f %% + %.1f %%) y %.1f %% de la cruda (%.1f %% + %.1f %%)\n",
  sum(autovalores_acm$porcentaje_ajustado[1:2]), autovalores_acm$porcentaje_ajustado[1], autovalores_acm$porcentaje_ajustado[2],
  sum(autovalores_acm$porcentaje_crudo[1:2]), autovalores_acm$porcentaje_crudo[1], autovalores_acm$porcentaje_crudo[2]))

## 4.3 Contribuciones, cos2, eta2 y suplementarias del ACM ----
categorias <- ajustado$levelnames
coord <- data.frame(categoria = categorias, acm$var$coord)
contrib <- data.frame(categoria = categorias, acm$var$contrib)
cos2 <- data.frame(categoria = categorias, acm$var$cos2)
guardar_tabla(coord, "acm_categorias_coordenadas"); guardar_tabla(contrib, "acm_categorias_contribuciones")
guardar_tabla(cos2, "acm_categorias_cos2")
guardar_tabla(data.frame(variable = rownames(acm$var$eta2), acm$var$eta2), "acm_eta2")
sup_coord <- data.frame(categoria = rownames(acm$quali.sup$coord), acm$quali.sup$coord)
guardar_tabla(sup_coord, "acm_suplementarias_coordenadas")
guardar_tabla(data.frame(categoria = rownames(acm$quali.sup$cos2), acm$quali.sup$cos2), "acm_suplementarias_cos2")
guardar_tabla(data.frame(variable = rownames(acm$quali.sup$eta2), acm$quali.sup$eta2), "acm_suplementarias_eta2")

umbral_contrib <- 100 / J   # contribución promedio (5,56 %)
encabezado(sprintf("Tabla 11 del informe: categorías con contribución mayor que la promedio (%.2f %%)", umbral_contrib))
for (d in 1:2) {
  sel <- contrib[[paste0("Dim.", d)]] > umbral_contrib
  t11 <- data.frame(categoria = categorias[sel], contribucion = contrib[[paste0("Dim.", d)]][sel],
    coordenada = coord[[paste0("Dim.", d)]][sel], cos2_dimension = cos2[[paste0("Dim.", d)]][sel],
    cos2_plano = cos2$Dim.1[sel] + cos2$Dim.2[sel])
  cat(sprintf("\nDimensión %d (%d categorías):\n", d, nrow(t11)))
  t11 <- t11[order(-t11$contribucion), ]; rownames(t11) <- NULL
  print(t11, digits = 3)
}
encabezado("Contribuciones (%) de todas las categorías, Dim 1 y Dim 2")
print(round(data.frame(contrib[, c("Dim.1", "Dim.2")], row.names = categorias), 2))
encabezado("cos2 de todas las categorías, Dim 1 y Dim 2")
print(round(data.frame(cos2[, c("Dim.1", "Dim.2")], row.names = categorias), 3))
encabezado("eta2 de las variables activas (razón de correlación con cada dimensión)")
print(round(acm$var$eta2[, 1:2], 3))
encabezado("Variables suplementarias: coordenadas, cos2 y eta2 (Dim 1 y 2)")
print(round(acm$quali.sup$coord[, 1:2], 3))
cat("\ncos2:\n"); print(round(acm$quali.sup$cos2[, 1:2], 3))
cat("\neta2:\n"); print(round(acm$quali.sup$eta2[, 1:2], 3))

## 4.4 Figuras de la Etapa 4 ----
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
guardar_fig(f10, "figura10_etapa4_mapa_acs.png", 8)

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
# Las coordenadas son las principales del ACM estándar (matriz indicadora). Los porcentajes de los ejes son la
# inercia ajustada de Greenacre (la que cita el texto), declarados junto a la cruda (34,9 % y 16,6 %).
pct <- function(x) format(round(x, 1), decimal.mark = ",")
# Dos paneles con la misma escala en ambos ejes: mapa completo y ampliación de la zona central.
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
    coord_equal(xlim = lim$x, ylim = lim$y)
}
p_total <- base_mapa(mapa[!en_zoom, ]) +
  annotate("rect", xmin = zoom$x[1], xmax = zoom$x[2], ymin = zoom$y[1], ymax = zoom$y[2], fill = NA,
    colour = tinta_2, linetype = "dashed", linewidth = .3) +
  annotate("text", x = zoom$x[1], y = zoom$y[2] + .12, label = "ampliada a la derecha", hjust = 0,
    family = familia, size = 2.3, colour = tinta_2) +
  labs(title = "Mapa completo", x = NULL, y = paste0("Dim 2 (", pct(aut$porcentaje_ajustado[2]), " % ajustada; ",
    pct(aut$porcentaje_crudo[2]), " % cruda)"))
p_zoom <- base_mapa(mapa[en_zoom, ], zoom) + labs(title = "Ampliación de la zona central", x = NULL, y = NULL)
f11 <- (p_total + p_zoom) + plot_layout(guides = "collect", widths = c(1, 1.1)) &
  theme(legend.position = "bottom", legend.text = element_text(size = 8), plot.title = element_text(size = 9))
f11 <- f11 + plot_annotation(caption = paste0("Dim 1 (", pct(aut$porcentaje_ajustado[1]), " % de la inercia ajustada; ",
  pct(aut$porcentaje_crudo[1]), " % de la cruda): completa ← → a medias. Porcentajes ajustados según Greenacre."),
  theme = theme(plot.caption = element_text(colour = tinta_2, size = 8, hjust = .5)))
guardar_fig(f11, "figura11_etapa4_mapa_acm.png", 12)
cat("\nEtapa 4 terminada: Figuras 10 y 11 guardadas.\n")


# ETAPA 6 · Integración de resultados (tabla síntesis) -------------------------------------------------
# Produce: Tabla 12 del informe (síntesis de las técnicas). Las cifras se toman de los objetos calculados arriba.
set.seed(42)

# Evidencia de la hipótesis de asociaciones, con tamaño del efecto (V de Cramér) entre tipo de tráfico y cada variable.
asociaciones <- data.frame()
for (variable in c("proto_g", "service_g", "state_g")) {
  t <- table(base$tipo_trafico, base[[variable]])
  prueba <- chisq.test(t, correct = FALSE)
  asociaciones <- rbind(asociaciones, data.frame(variable = variable, chi2 = unname(prueba$statistic),
    gl = unname(prueba$parameter), p = prueba$p.value, cramer_v = sqrt(unname(prueba$statistic) / (sum(t) * min(dim(t) - 1)))))
}
guardar_tabla(asociaciones, "integracion_asociaciones")
encabezado("Asociación del tipo de tráfico con protocolo, servicio y estado (chi cuadrado y V de Cramér)")
print(asociaciones, digits = 4, row.names = FALSE)

coma <- function(x, d = 1) trimws(format(round(x, d), nsmall = d, decimal.mark = ","))
ataques <- prop_ataques$x * 100
resumen_grupos <- paste0("G", seq_along(ataques), " ", coma(ataques, 0), " %", collapse = "; ")
integracion <- data.frame(
  tecnica = c("ACP", "AF", "Clustering", "ACS", "ACM"),
  estructura = c(paste0(n_componentes, " componentes; ", coma(tabla_autovalores$acumulado[n_componentes], 2), " % de varianza"),
    paste0(n_factores, " factores (máxima verosimilitud, varimax); ", coma(sum(varianza_af$porcentaje_total)), " % de varianza; ",
      "unicidad de log_spkts en el límite 0,005"),
    paste0("Tres bloques de variables y ", k_elegido, " grupos de observaciones (k-means, Ward.D2 como contraste)"),
    paste0("Tipo de tráfico por estado; V de Cramér = ", coma(v_cramer, 3)),
    paste0("Plano de dos dimensiones; ", coma(sum(autovalores_acm$porcentaje_ajustado[1:2])), " % de inercia ajustada (Greenacre) y ",
      coma(sum(autovalores_acm$porcentaje_crudo[1:2])), " % de inercia cruda")),
  interpretacion = c("Ejes mixtos: complejidad frente a repetición; volumen y actividad",
    "Repetición, ritmo y volumen: reproduce los tres bloques",
    paste0("Bloques de variables iguales a los factores; % de ataques por grupo: ", resumen_grupos),
    "Normal-CON_otros y Exploits-FIN coinciden con asociaciones del ACM",
    "Conversación a medias frente a completa; los ataques caen del lado incompleto salvo Exploits"))
guardar_tabla(integracion, "integracion_tecnicas")
encabezado("Tabla 12 del informe: síntesis de las técnicas")
for (i in seq_len(nrow(integracion)))
  cat(sprintf("\n[%s]\n  Estructura:     %s\n  Interpretación: %s\n", integracion$tecnica[i], integracion$estructura[i], integracion$interpretacion[i]))


# RESUMEN FINAL ---------------------------------------------------------------------------------------
encabezado("Archivos generados")
fig_generadas <- list.files(dir_figuras, pattern = "\\.png$")
tab_generadas <- list.files(dir_tablas, pattern = "\\.csv$")
cat("Figuras en", dir_figuras, "(", length(fig_generadas), "):\n")
cat(paste0("  ", fig_generadas), sep = "\n")
cat("\nTablas CSV en", dir_tablas, "(", length(tab_generadas), "):\n")
cat(paste0("  ", tab_generadas), sep = "\n")
stopifnot(length(fig_generadas) == 11)
cat("\nListo: las 11 figuras y las salidas del informe se generaron sin errores.\n")
