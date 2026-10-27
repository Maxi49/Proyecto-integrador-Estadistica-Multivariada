# Ejecutar desde la carpeta principal del repositorio.
# Paquetes: install.packages(c("readxl", "psych", "cluster", "ca", "FactoMineR"))
# Las figuras del informe se crean con 06_figuras.R (paquetes ggplot2, ggrepel y patchwork).
for (archivo in c("00_datos.R", "01_acp.R", "02_af.R", "03_cluster.R", "04_acm.R", "05_integracion.R", "06_figuras.R")) {
  cat("\nEJECUTANDO", archivo, "\n")
  source(paste0("R/", archivo), encoding = "UTF-8")
}
