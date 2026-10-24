# ETAPA 0: importar, auditar, describir y congelar conjuntos de análisis.
# Ejecutar desde la raíz del repositorio: source("R/00_datos.R", encoding="UTF-8")
# No modifica el Excel ni aplica eliminaciones o imputaciones automáticas.
set.seed(42)
options(stringsAsFactors = FALSE)
paquetes <- c("readxl", "psych")
faltan <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) stop("Instalar primero en R: install.packages(c(",
  paste(sprintf('"%s"', faltan), collapse = ", "), "))")
library(readxl)
library(psych)

archivo <- "muestra_estratificada-simulado-de-ataques.xlsx"
if (!file.exists(archivo)) stop("Abrir la raíz del repositorio como directorio de trabajo.")
dir.create("datos", showWarnings = FALSE)
dir.create("resultados/tablas", recursive = TRUE, showWarnings = FALSE)
dir.create("resultados/figuras", recursive = TRUE, showWarnings = FALSE)
dir.create("docs", showWarnings = FALSE)
guardar <- function(x, nombre) {
  write.csv(x, file.path("resultados/tablas", paste0(nombre, ".csv")),
            row.names = FALSE, fileEncoding = "UTF-8", na = "")
}

# 1. Importación y diccionario: el tipo analítico no siempre coincide con el almacenamiento.
base <- read_excel(archivo, sheet = "muestra")
base_original <- base
info <- read_excel(archivo, sheet = "diccionario")
stopifnot(!anyDuplicated(info$variable), setequal(names(base), info$variable))
info <- info[match(names(base), info$variable), ]
stopifnot(all(info$tipo %in% c("continua", "conteo", "categórica", "binaria")))
diccionario <- data.frame(nombre = info$variable, descripcion = info$descripcion,
  unidad = info$unidad,
  tipo = ifelse(info$tipo %in% c("continua", "conteo"), "numérica", "categórica"),
  rol_original = info$rol, motivo_exclusion = info$motivo_exclusion)
guardar(diccionario, "diccionario_variables")

# X_num: decisión del grupo; se seleccionan solamente las versiones logarítmicas.
vars_num <- c("log_dur", "log_spkts", "log_sbytes", "log_dbytes", "log_sinpkt",
  "log_sjit", "log_synack", "log_ct_srv_src", "log_ct_srv_dst", "log_ct_src_ltm",
  "log_ct_src_dport_ltm", "log_ct_dst_sport_ltm")
vars_crudas <- sub("^log_", "", vars_num)
stopifnot(all(vars_num %in% names(base)), all(vars_crudas %in% names(base)))
X_num <- as.data.frame(base[vars_num])
mediciones <- diccionario$nombre[diccionario$tipo == "numérica"]
almacenadas_num <- names(base)[vapply(base, is.numeric, logical(1))]

# 2. Calidad. Faltantes reales y textos vacíos se cuentan por separado.
faltantes <- data.frame(variable = names(base),
  faltantes_NA = vapply(base, function(x) sum(is.na(x)), integer(1)),
  vacios = vapply(base, function(x) sum(!is.na(x) & trimws(as.character(x)) == ""), integer(1)))
guardar(faltantes, "faltantes")
# Perfil original: 45 columnas de UNSW-NB15, excluyendo el identificador.
cols_perfil <- setdiff(names(base)[seq_len(45)], "id")
duplicados <- data.frame(criterio = c("filas completas", "id", "perfil original sin id"),
  filas_adicionales = c(sum(duplicated(base)), sum(duplicated(base$id)),
                       sum(duplicated(base[cols_perfil]))))
guardar(duplicados, "duplicados")

# Registro de incidencias: no se corrige un código si no se conoce su significado.
incidencias <- data.frame(id = numeric(), variable = character(),
  valor = character(), regla = character(), decision = character())
anotar <- function(variable, malos, regla, decision = "Conservar; revisar antes de usar esta variable.") {
  indices <- which(malos %in% TRUE)
  if (length(indices)) incidencias <<- rbind(incidencias,
    data.frame(id = base$id[indices], variable = variable,
      valor = as.character(base[[variable]][indices]), regla = regla, decision = decision))
  length(indices)
}
reglas <- data.frame(regla = character(), incidencias = integer())
registrar <- function(regla, n) reglas <<- rbind(reglas, data.frame(regla = regla, incidencias = n))
registrar("Celdas numéricas negativas", sum(vapply(almacenadas_num, function(v)
  anotar(v, !is.na(base[[v]]) & base[[v]] < 0, "Mediciones y códigos no negativos"), integer(1))))
registrar("Celdas numéricas no finitas (sin contar NA)", sum(vapply(almacenadas_num, function(v)
  anotar(v, !is.na(base[[v]]) & !is.finite(base[[v]]), "Valor finito"), integer(1))))
conteos <- info$variable[info$tipo == "conteo"]
registrar("Conteos no enteros", sum(vapply(conteos, function(v)
  anotar(v, abs(base[[v]] - round(base[[v]])) > 1e-8, "Conteo entero"), integer(1))))
for (v in c("sttl", "dttl")) registrar(paste(v, "fuera de 0..255"),
  anotar(v, base[[v]] > 255, "TTL en rango 0..255"))
for (v in c("swin", "dwin")) registrar(paste(v, "fuera de 0..65535"),
  anotar(v, base[[v]] > 65535, "Ventana TCP en rango 0..65535"))
vars_ventana <- grep("^ct_.*(src|dst|ltm)$", names(base), value = TRUE)
registrar("Conteos de ventana de 100 mayores que 100", sum(vapply(vars_ventana, function(v)
  anotar(v, base[[v]] > 100, "Ventana de contexto de 100 conexiones"), integer(1))))
registrar("dur = 0 con spkts > 1", anotar("dur", base$dur == 0 & base$spkts > 1,
  "Duración cero con múltiples paquetes: revisar precisión temporal"))
registrar("sbytes < spkts", anotar("sbytes", base$sbytes < base$spkts,
  "Bytes enviados inferiores a paquetes enviados"))
for (v in c("usa_http", "is_sm_ips_ports")) registrar(paste(v, "fuera de 0/1"),
  anotar(v, !base[[v]] %in% c(0, 1), "Indicador binario"))
registrar("is_ftp_login fuera de 0/1", anotar("is_ftp_login",
  !base$is_ftp_login %in% c(0, 1), "Discrepancia con la definición binaria del diccionario",
  "Conservar el código original; no usar en X_num ni X_cat; revisar documentación de origen."))
registrar("label fuera de normal/ataque", anotar("label", !base$label %in% c("normal", "ataque"),
  "La versión importada usa etiquetas textuales"))
registrar("Inconsistencia label y attack_cat", anotar("label",
  (base$attack_cat == "Normal") != (base$label == "normal"), "Normal corresponde a label normal"))
verificacion_log <- data.frame(variable = grep("^log_", names(base), value = TRUE))
verificacion_log$error_maximo <- vapply(verificacion_log$variable, function(v)
  max(abs(base[[v]] - log1p(base[[sub("^log_", "", v)]]))), numeric(1))
stopifnot(all(verificacion_log$error_maximo < 1e-10))
guardar(verificacion_log, "verificacion_log1p")
guardar(reglas, "calidad_reglas")
guardar(incidencias, "incidencias_revision")

# Atípicos: bisagras de Tukey (fivenum), coherentes con los boxplots de R.
# No se usa quantile(type=7) porque produciría límites distintos en datos con empates.
atipicos <- matrix(FALSE, nrow(base), length(vars_num), dimnames = list(NULL, vars_num))
limites <- do.call(rbind, lapply(vars_num, function(v) {
  x <- X_num[[v]]
  stopifnot(all(is.finite(x)))
  cinco <- fivenum(x)
  q1 <- cinco[2]; q3 <- cinco[4]; ric <- q3 - q1
  li <- q1 - 1.5 * ric; ls <- q3 + 1.5 * ric
  atipicos[, v] <<- x < li | x > ls
  data.frame(variable = v, q1_tukey = q1, mediana = cinco[3], q3_tukey = q3,
    ric = ric, limite_inferior = li, limite_superior = ls,
    bigote_inferior = min(x[x >= li & x <= ls]),
    bigote_superior = max(x[x >= li & x <= ls]),
    n_atipicos = sum(atipicos[, v]), porcentaje = 100 * mean(atipicos[, v]))
}))
guardar(limites, "atipicos_limites")
control_atipicos <- data.frame(id = base$id, n_atipicos_original = base$n_atipicos,
  n_atipicos_revision_12 = rowSums(atipicos))
guardar(control_atipicos, "atipicos_por_flujo")
guardar(data.frame(indicador = c("al_menos_uno_original", "al_menos_uno_revision_12"),
  n = c(sum(base$n_atipicos > 0), sum(rowSums(atipicos) > 0)),
  porcentaje = 100 * c(mean(base$n_atipicos > 0), mean(rowSums(atipicos) > 0))), "atipicos_resumen")

decisiones <- data.frame(tema = c("Faltantes", "Duplicados", "Valores imposibles",
  "Código FTP", "Ceros y servicio ninguno", "Atípicos", "Transformaciones", "Aprobación"),
  decision = c("No imputar: no hay NA ni textos vacíos en esta versión.",
  "No eliminar filas: los tres controles de duplicación arrojan cero.",
  "No corregir automáticamente; registrar todas las reglas e incidencias para revisión.",
  "Conservar is_ftp_login = 4 (id 97597); variable excluida de los conjuntos analíticos.",
  "Conservar ceros y ninguno: no tratarlos automáticamente como faltantes.",
  "Conservar todos los flujos; separar la revisión actual de n_atipicos original.",
  "Usar las 12 log_ acordadas; no transformar ni estandarizar dos veces.",
  "Versión preparada para revisión; la aprobación académica corresponde al grupo y docente."))
guardar(decisiones, "decisiones_calidad")

# 3. Descriptiva de TODAS las mediciones y, por separado, las 12 crudas y 12 log.
resumir <- function(variables) do.call(rbind, lapply(variables, function(v) {
  x <- base[[v]]; x <- x[is.finite(x)]
  q <- quantile(x, c(0, .25, .5, .75, 1), names = FALSE, type = 7)
  data.frame(variable = v, n = length(x), media = mean(x), desvio = sd(x),
    minimo = q[1], q1 = q[2], mediana = q[3], q3 = q[4], maximo = q[5],
    ceros = sum(x == 0), porcentaje_ceros = 100 * mean(x == 0))
}))
guardar(resumir(mediciones), "resumen_numerico_completo")
guardar(resumir(c(vars_crudas, vars_num)), "resumen_numerico_seleccion")

# 4. X_cat: propuesta operativa de 7 variables, documentada para revisión del grupo.
# Dos cortes por terciles evitan elegir umbrales según la etiqueta de ataque.
# La tercera discretización distingue ausencia/presencia de respuesta (dpkts).
cortes_dur <- unname(quantile(base$dur, c(1/3, 2/3), type = 7))
cortes_bytes <- unname(quantile(base$sbytes, c(1/3, 2/3), type = 7))
X_cat <- as.data.frame(base[c("tipo_trafico", "proto_g", "service_g", "state_g")])
X_cat$respuesta_destino <- ifelse(base$dpkts == 0, "sin_respuesta", "con_respuesta")
X_cat$duracion_banda <- cut(base$dur, c(-Inf, cortes_dur, Inf),
  labels = c("corta", "media", "larga"), right = TRUE)
X_cat$bytes_origen_banda <- cut(base$sbytes, c(-Inf, cortes_bytes, Inf),
  labels = c("bajos", "medios", "altos"), right = TRUE)
X_cat[] <- lapply(X_cat, factor)
stopifnot(!anyNA(X_cat))
vars_cat <- names(X_cat)
cortes <- data.frame(variable = c("duracion_banda", "bytes_origen_banda", "respuesta_destino"),
  origen = c("dur", "sbytes", "dpkts"), unidad_original = c("segundos", "bytes", "paquetes"),
  corte_1 = c(cortes_dur[1], cortes_bytes[1], 0),
  corte_2 = c(cortes_dur[2], cortes_bytes[2], NA),
  criterio = c("Terciles de la muestra, quantile tipo 7; intervalos cerrados a derecha",
    "Terciles de la muestra, quantile tipo 7; intervalos cerrados a derecha",
    "Sin respuesta: dpkts = 0; con respuesta: dpkts > 0"))
guardar(cortes, "cortes_discretizacion")
frecuencias <- function(datos, variables) do.call(rbind, lapply(variables, function(v) {
  t <- table(as.character(datos[[v]]), useNA = "ifany")
  data.frame(variable = v, categoria = names(t), frecuencia = as.integer(t),
    porcentaje = 100 * as.integer(t) / nrow(datos))
}))
f_cat <- frecuencias(X_cat, vars_cat)
stopifnot(all(f_cat$porcentaje >= 5))
guardar(f_cat, "frecuencias_X_cat")
guardar(frecuencias(base, diccionario$nombre[diccionario$tipo == "categórica"]),
  "frecuencias_categoricas_completas")
guardar(frecuencias(base, "attack_cat"), "frecuencias_attack_cat")
guardar(frecuencias(base, "label"), "frecuencias_label")
write.csv(data.frame(id = base$id, X_cat), "datos/categoricas_acm.csv",
  row.names = FALSE, fileEncoding = "UTF-8")

# 5. Piloto: Pearson sobre las versiones log. KMO/Bartlett no prueban normalidad.
correlaciones <- cor(X_num, method = "pearson", use = "everything")
stopifnot(all(is.finite(correlaciones)), min(eigen(correlaciones, symmetric = TRUE)$values) > 0)
guardar(data.frame(variable = rownames(correlaciones), correlaciones, check.names = FALSE), "correlaciones")
kmo <- psych::KMO(correlaciones)
bartlett <- psych::cortest.bartlett(correlaciones, n = nrow(X_num))
piloto <- data.frame(n = nrow(X_num), p = ncol(X_num), determinante = det(correlaciones),
  kmo_global = kmo$MSA, msa_minima = min(kmo$MSAi),
  bartlett_chi2 = bartlett$chisq, bartlett_gl = bartlett$df,
  bartlett_p_calculado = bartlett$p.value,
  bartlett_p_informe = ifelse(bartlett$p.value < .001, "< 0,001", format(bartlett$p.value)))
guardar(piloto, "piloto_supuestos")
guardar(data.frame(variable = names(kmo$MSAi), msa = as.numeric(kmo$MSAi)), "msa_por_variable")
if (kmo$MSA < .6 || any(kmo$MSAi < .5) || det(correlaciones) <= 1e-5)
  warning("El piloto requiere revisión: NO se modifica X_num automáticamente.")

# 6. Congelar archivos comunes conservando la base original y los identificadores.
stopifnot(identical(base, base_original))
saveRDS(base, "datos/base_limpia.rds", version = 3)
write.csv(base, "datos/base_limpia.csv", row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(list(version = "etapa0-v1", semilla = 42L, id = base$id,
  vars_num = vars_num, vars_cat = vars_cat, X_num = X_num, X_cat = X_cat,
  cortes = cortes, estado_X_num = "12 log_ decididas por el grupo",
  estado_X_cat = "Propuesta operativa de 7; revisión grupal pendiente",
  estandarizacion = "Aplicar scale() o scale.=TRUE en ACP/AF/clustering, no aquí"),
  "datos/conjuntos_congelados.rds", version = 3)
guardar(data.frame(conjunto = c(rep("X_num", length(vars_num)), rep("X_cat", length(vars_cat))),
  variable = c(vars_num, vars_cat),
  estado = c(rep("Decisión del grupo: 12 log_", length(vars_num)),
    rep("Propuesta operativa; pendiente de revisión grupal", length(vars_cat)))), "conjuntos_congelados")
guardar(data.frame(filas = nrow(base), columnas = ncol(base),
  numericas = sum(diccionario$tipo == "numérica"), categoricas = sum(diccionario$tipo == "categórica"),
  celdas_NA = sum(faltantes$faltantes_NA), vacios = sum(faltantes$vacios)), "dimensiones")
writeLines(c(paste("Fuente de trabajo:", archivo), paste("MD5:", unname(tools::md5sum(archivo))),
  "La procedencia anterior de la muestra se describe según CONTEXTO_PROYECTO.md; no se remuestrea.",
  "La base no se elimina, imputa ni altera en esta etapa."), "resultados/procedencia_R.txt")
writeLines(sub("[[:blank:]]+$", "", capture.output(sessionInfo())), "resultados/sesion_R.txt")

# 7. Todos los gráficos son generados exclusivamente por Matplotlib en Python.
# Elegir Python por variable de entorno, por .venv o por PATH, sin rutas personales.
if (Sys.getenv("ETAPA0_GRAFICOS", "1") == "1") {
  python <- Sys.getenv("PYTHON_ETAPA0")
  if (!nzchar(python)) {
    candidato <- if (.Platform$OS.type == "windows") ".venv/Scripts/python.exe" else ".venv/bin/python"
    python <- if (file.exists(candidato)) candidato else unname(Sys.which("python"))
  }
  if (!nzchar(python)) stop("No se encontró Python; seguir README.md para preparar .venv.")
  estado <- system2(python, shQuote("python/graficos_etapa0.py"))
  if (estado != 0) stop("Los cálculos R terminaron; falló Python. Revisar requirements.txt y README.md.")
}
cat("\nEtapa 0 terminada. Base:", nrow(base), "flujos y", ncol(base), "columnas.\n")
print(piloto)
cat("\nAtípicos revisados:", sum(rowSums(atipicos) > 0), "flujos; todos conservados.\n")
cat("Aprobación académica y propuesta X_cat: pendientes de revisión por grupo/docente.\n")
