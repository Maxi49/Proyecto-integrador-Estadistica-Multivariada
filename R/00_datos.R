# ETAPA 0. Ejecutar desde la carpeta principal del proyecto.
# Instalar una sola vez: install.packages(c("readxl", "psych"))
# Ejecutar: source("R/00_datos.R", encoding = "UTF-8")
library(readxl)
library(psych)
set.seed(42)

# 1. Importar el mismo Excel que usamos en el script del diccionario.
ruta_excel <- "muestra_estratificada-simulado-de-ataques.xlsx"
base <- read_excel(path = ruta_excel, sheet = "muestra")
info <- read_excel(path = ruta_excel, sheet = "diccionario")
info <- info[match(names(base), info$variable), ]
stopifnot(!anyNA(info$variable), !anyDuplicated(info$variable))
base_original <- base

diccionario <- data.frame(
  nombre = info$variable,
  descripcion = info$descripcion,
  unidad = info$unidad,
  tipo = ifelse(info$tipo %in% c("continua", "conteo"), "numérica", "categórica")
)
print(dim(base))
print(table(diccionario$tipo))
if (interactive()) View(diccionario)

# Guardar solo las tablas necesarias, con nombres fáciles de identificar.
dir.create("resultados/tablas", recursive = TRUE, showWarnings = FALSE)
dir.create("resultados/figuras", recursive = TRUE, showWarnings = FALSE)
guardar_tabla <- function(tabla, nombre) {
  write.csv(tabla, paste0("resultados/tablas/", nombre, ".csv"),
            row.names = FALSE, fileEncoding = "UTF-8", na = "")
}
guardar_tabla(diccionario, "diccionario_variables")

# 2. Elegir las 12 log_ acordadas para ACP, AF y clustering.
variables_num <- c(
  "log_dur", "log_spkts", "log_sbytes", "log_dbytes", "log_sinpkt", "log_sjit",
  "log_synack", "log_ct_srv_src", "log_ct_srv_dst", "log_ct_src_ltm",
  "log_ct_src_dport_ltm", "log_ct_dst_sport_ltm"
)
X_num <- as.data.frame(base[variables_num])
stopifnot(all(is.finite(as.matrix(X_num))))

# 3. Revisar faltantes, duplicados y valores incompatibles con su definición.
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
    sum((base$attack_cat == "Normal") != (base$label == "normal")))
)
ftp_revision <- base[!base$is_ftp_login %in% c(0, 1), c("id", "is_ftp_login", "ct_ftp_cmd")]
guardar_tabla(faltantes, "faltantes")
guardar_tabla(calidad, "calidad")
guardar_tabla(ftp_revision, "ftp_revision")
print(calidad)
print(ftp_revision)

# Atípicos: límites de Tukey sobre las 12 log_, sin borrar observaciones.
# fivenum usa bisagras de Tukey: pueden diferir de quantile cuando hay empates.
atipicos <- matrix(FALSE, nrow = nrow(base), ncol = length(variables_num))
limites <- data.frame()
for (i in seq_along(variables_num)) {
  variable <- variables_num[i]
  x <- X_num[[variable]]
  cinco <- fivenum(x)
  q1 <- cinco[2]
  q3 <- cinco[4]
  ric <- q3 - q1
  inferior <- q1 - 1.5 * ric
  superior <- q3 + 1.5 * ric
  atipicos[, i] <- x < inferior | x > superior
  limites <- rbind(limites, data.frame(variable = variable, q1_tukey = q1,
    mediana = cinco[3], q3_tukey = q3, limite_inferior = inferior, limite_superior = superior,
    bigote_inferior = min(x[x >= inferior & x <= superior]),
    bigote_superior = max(x[x >= inferior & x <= superior]), n_atipicos = sum(atipicos[, i])))
}
revision_atipicos <- data.frame(id = base$id, n_atipicos_original = base$n_atipicos,
                              n_atipicos_revision_12 = rowSums(atipicos))
guardar_tabla(limites, "atipicos_limites")
guardar_tabla(revision_atipicos, "atipicos_por_flujo")
cat("Flujos con atípicos en las 12 variables:", sum(rowSums(atipicos) > 0), "\n")

# Registrar qué se hace con cada problema; conservar la base recibida.
decisiones <- data.frame(
  tema = c("Faltantes", "Duplicados", "Valores incompatibles", "Código FTP",
           "Ceros y servicio ninguno", "Atípicos", "Indicador anterior"),
  decision = c("No imputar: no se encontraron faltantes en esta base.",
    "No eliminar filas: no se encontraron duplicados en esta base.",
    "Registrar los controles y revisar incidencias antes de cualquier corrección.",
    "Conservar el código 4 y el flujo; is_ftp_login no entra en X_num ni X_cat.",
    "Conservar: pueden ser valores estructurales, no faltantes.",
    "Conservar todos los flujos; un extremo no demuestra error ni ataque.",
    "No sobrescribir n_atipicos; guardar la revisión de las 12 variables por separado.")
)
guardar_tabla(decisiones, "decisiones_calidad")

# 4. Descriptiva de las 47 numéricas; se incluyen dpkts y las versiones log_.
numericas <- diccionario$nombre[diccionario$tipo == "numérica"]
resumen <- data.frame()
for (variable in numericas) {
  x <- base[[variable]]
  q <- quantile(x, c(0, .25, .5, .75, 1), na.rm = TRUE, names = FALSE, type = 7)
  resumen <- rbind(resumen, data.frame(variable = variable, media = mean(x, na.rm = TRUE),
    desvio = sd(x, na.rm = TRUE), minimo = q[1], q1 = q[2], mediana = q[3], q3 = q[4],
    maximo = q[5], ceros = sum(x == 0, na.rm = TRUE)))
}
guardar_tabla(resumen, "resumen_numerico")
print(resumen)

categoricas <- diccionario$nombre[diccionario$tipo == "categórica"]
frecuencias <- data.frame()
for (variable in categoricas) {
  tabla <- table(base[[variable]], useNA = "ifany")
  frecuencias <- rbind(frecuencias, data.frame(variable = variable, categoria = names(tabla),
    frecuencia = as.integer(tabla), porcentaje = 100 * as.integer(tabla) / nrow(base)))
}
guardar_tabla(frecuencias, "frecuencias_categoricas")

# 5. Piloto con psych: Pearson, Bartlett, KMO y MSA por variable.
correlaciones <- cor(X_num, method = "pearson")
kmo <- KMO(correlaciones)
bartlett <- cortest.bartlett(correlaciones, n = nrow(X_num))
msa <- data.frame(variable = names(kmo$MSAi), msa = as.numeric(kmo$MSAi))
piloto <- data.frame(determinante = det(correlaciones), kmo_global = kmo$MSA,
  msa_minima = min(kmo$MSAi), bartlett_chi2 = bartlett$chisq, bartlett_gl = bartlett$df,
  bartlett_p_calculado = bartlett$p.value,
  bartlett_p_informe = ifelse(bartlett$p.value < .001, "< 0,001", as.character(bartlett$p.value)))
guardar_tabla(data.frame(variable = rownames(correlaciones), correlaciones), "correlaciones")
guardar_tabla(msa, "msa_por_variable")
guardar_tabla(piloto, "piloto_supuestos")
print(piloto)
print(msa)
if (kmo$MSA < .6 || min(kmo$MSAi) < .5 || det(correlaciones) <= 1e-5)
  warning("Revisar el piloto; no se cambia X_num automáticamente.")

# 6. Congelar X_cat: cuatro categorías existentes y propuesta de tres discretizaciones.
# Los terciles no usan la etiqueta de ataque para elegir los cortes.
cortes_dur <- unname(quantile(base$dur, c(1/3, 2/3), type = 7))
cortes_bytes <- unname(quantile(base$sbytes, c(1/3, 2/3), type = 7))
X_cat <- as.data.frame(base[c("tipo_trafico", "proto_g", "service_g", "state_g")])
X_cat$respuesta_destino <- ifelse(base$dpkts == 0, "sin_respuesta", "con_respuesta")
X_cat$duracion_banda <- cut(base$dur, c(-Inf, cortes_dur, Inf), labels = c("corta", "media", "larga"))
X_cat$bytes_origen_banda <- cut(base$sbytes, c(-Inf, cortes_bytes, Inf), labels = c("bajos", "medios", "altos"))
X_cat[] <- lapply(X_cat, factor)
frecuencias_cat <- data.frame()
for (variable in names(X_cat)) {
  tabla <- table(X_cat[[variable]])
  frecuencias_cat <- rbind(frecuencias_cat, data.frame(variable = variable,
    categoria = names(tabla), frecuencia = as.integer(tabla), porcentaje = 100 * as.integer(tabla) / nrow(base)))
}
stopifnot(!anyNA(X_cat), all(frecuencias_cat$porcentaje >= 5))
guardar_tabla(frecuencias_cat, "frecuencias_X_cat")
guardar_tabla(data.frame(variable = c("dur", "sbytes"), corte_1 = c(cortes_dur[1], cortes_bytes[1]),
  corte_2 = c(cortes_dur[2], cortes_bytes[2])), "cortes_discretizacion")
guardar_tabla(data.frame(conjunto = c(rep("X_num", ncol(X_num)), rep("X_cat", ncol(X_cat))),
  variable = c(names(X_num), names(X_cat))), "conjuntos_congelados")

# 7. Guardar la base común y los conjuntos sin crear una carpeta datos ni archivos md.
stopifnot(identical(base, base_original))
saveRDS(base, "resultados/base_limpia.rds")
saveRDS(list(X_num = X_num, X_cat = X_cat, id = base$id, semilla = 42,
  cortes_dur = cortes_dur, cortes_bytes = cortes_bytes,
  estado_X_cat = "Propuesta para revisión grupal"), "resultados/conjuntos_congelados.rds")
cat("Base y conjuntos guardados en resultados. Excel original conservado.\n")
cat("Gráficos: ejecutar en Python el archivo python/graficos_etapa0.py.\n")
