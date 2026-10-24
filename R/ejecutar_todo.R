# Ejecutar desde la carpeta principal del repositorio.
# Paquetes: install.packages(c("readxl", "psych", "cluster", "ca", "FactoMineR"))
# Las figuras se crean luego con Python; ver python/graficos_parte2.py.
for (archivo in c("00_datos.R", "01_acp.R", "02_af.R", "03_cluster.R", "04_acm.R", "05_integracion.R")) {
  cat("\nEJECUTANDO", archivo, "\n")
  source(paste0("R/", archivo), encoding = "UTF-8")
}
