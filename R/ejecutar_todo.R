# Ejecutar desde la carpeta principal del repositorio.
# Paquetes (una sola vez):
# install.packages(c("readxl", "psych", "GPArotation", "cluster", "ca", "FactoMineR",
#                    "MASS", "pROC", "writexl", "ggplot2", "ggrepel", "patchwork", "systemfonts"))
# Cada etapa genera sus propias figuras del informe (resultados/figuras_informe/), con el estilo común de
# R/estilo_graficos.R:
#   Etapa 0 (00_datos.R)    -> Figuras 1 a 3
#   Etapa 1 (01_acp.R)      -> Figuras 4 y 5
#   Etapa 2 (02_af.R)       -> Figura 6
#   Etapa 3 (03_cluster.R)  -> Figuras 7 a 9
#   Etapa 4 (04_acm.R)      -> Figuras 10 y 11
# 05_integracion.R es la síntesis (Etapa 6); 06_logistica.R es una etapa posterior que no entra en el informe.
for (archivo in c("00_datos.R", "01_acp.R", "02_af.R", "03_cluster.R", "04_acm.R",
                  "05_integracion.R", "06_logistica.R")) {
  cat("\nEJECUTANDO", archivo, "\n")
  source(paste0("R/", archivo), encoding = "UTF-8")
}
