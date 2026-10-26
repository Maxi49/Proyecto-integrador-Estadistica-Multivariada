# Ejecutar desde la carpeta principal del repositorio.
# Paquetes (una sola vez):
# install.packages(c("readxl", "psych", "GPArotation", "cluster", "ca", "FactoMineR",
#                    "MASS", "pROC", "writexl"))
# Las figuras se crean luego con Python; ver Como_ejecutar.txt.
for (archivo in c("00_datos.R", "01_acp.R", "02_af.R", "03_cluster.R", "04_acm.R",
                  "05_integracion.R", "06_logistica.R")) {
  cat("\nEJECUTANDO", archivo, "\n")
  source(paste0("R/", archivo), encoding = "UTF-8")
}
