# Ejecutar desde la carpeta principal del repositorio.
# Paquetes (una sola vez):
# install.packages(c("readxl", "psych", "GPArotation", "cluster", "ca", "FactoMineR",
#                    "MASS", "pROC", "writexl", "ggplot2", "ggrepel", "patchwork"))
# Las figuras del informe se crean con 07_figuras.R.
for (archivo in c("00_datos.R", "01_acp.R", "02_af.R", "03_cluster.R", "04_acm.R",
                  "05_integracion.R", "06_logistica.R", "07_figuras.R")) {
  cat("\nEJECUTANDO", archivo, "\n")
  source(paste0("R/", archivo), encoding = "UTF-8")
}
