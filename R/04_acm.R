# ETAPA 4. ACS, ACM y proyección suplementaria del cluster.
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
