# ETAPA 6. Síntesis de resultados de las técnicas multivariadas.
set.seed(42)
base <- readRDS("resultados/base_con_clusters.rds")
acp <- readRDS("resultados/acp.rds")
af <- readRDS("resultados/af.rds")
km <- readRDS("resultados/clustering.rds")
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")

# Evidencia de la hipótesis de asociaciones, con tamaños del efecto.
asociaciones <- data.frame()
for (variable in c("proto_g", "service_g", "state_g")) {
  t <- table(base$tipo_trafico, base[[variable]])
  prueba <- chisq.test(t, correct = FALSE)
  asociaciones <- rbind(asociaciones, data.frame(variable = variable,
    chi2 = unname(prueba$statistic), gl = unname(prueba$parameter), p = prueba$p.value,
    cramer_v = sqrt(unname(prueba$statistic) / (sum(t) * min(dim(t) - 1)))))
}
guardar(asociaciones, "integracion_asociaciones")

# Las cifras se leen de las tablas ya guardadas por 01 a 04 (nada escrito a mano), con coma decimal.
leer <- function(nombre) read.csv(paste0("resultados/tablas/", nombre, ".csv"), fileEncoding = "UTF-8")
coma <- function(x, d = 1) trimws(format(round(x, d), nsmall = d, decimal.mark = ","))
acp_ac <- leer("acp_autovalores")$acumulado[acp$n_componentes]
af_total <- sum(leer("af_varianza")$porcentaje_total)
v_cramer <- leer("acs_asociacion")$cramer_v
acm_aut <- leer("acm_autovalores")
acm_plano_aj <- sum(acm_aut$porcentaje_ajustado[1:2])
acm_plano_cr <- sum(acm_aut$porcentaje_crudo[1:2])
ataques <- leer("cluster_proporcion_ataques")$x * 100
resumen_grupos <- paste0("G", seq_along(ataques), " ", coma(ataques, 0), " %", collapse = "; ")

integracion <- data.frame(
  tecnica = c("ACP", "AF", "Clustering", "ACS", "ACM"),
  estructura = c(paste0(acp$n_componentes, " componentes; ", coma(acp_ac, 2), " % de varianza"),
    paste0(af$n_factores, " factores (máxima verosimilitud, varimax); ", coma(af_total), " % de varianza; ",
      "unicidad de log_spkts en el límite 0,005"),
    paste0("Tres bloques de variables y ", km$k, " grupos de observaciones (k-means, Ward.D2 como contraste)"),
    paste0("Tipo de tráfico por estado; V de Cramér = ", coma(v_cramer, 3)),
    paste0("Plano de dos dimensiones; ", coma(acm_plano_aj), " % de inercia ajustada (Greenacre) y ",
      coma(acm_plano_cr), " % de inercia cruda")),
  interpretacion = c("Ejes mixtos: complejidad frente a repetición; volumen y actividad",
    "Repetición, ritmo y volumen: reproduce los tres bloques",
    paste0("Bloques de variables iguales a los factores; % de ataques por grupo: ", resumen_grupos),
    "Normal-CON_otros y Exploits-FIN coinciden con asociaciones del ACM",
    "Conversación a medias frente a completa; los ataques caen del lado incompleto salvo Exploits")
)
guardar(integracion, "integracion_tecnicas")
print(integracion)
