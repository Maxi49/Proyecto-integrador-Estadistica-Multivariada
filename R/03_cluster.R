# PLANTILLA DE ETAPA POSTERIOR: Clustering. No contiene resultados calculados.
# Ejecutar desde la raíz del repositorio, después de completar la Etapa 0.
set.seed(42)
if (!file.exists("datos/conjuntos_congelados.rds")) stop("Ejecutar primero R/00_datos.R.")
base <- readRDS("datos/base_limpia.rds")
conjuntos <- readRDS("datos/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
X_cat <- conjuntos$X_cat
stop("Etapa Clustering pendiente. Esta plantilla solo carga los datos comunes; no ejecuta la técnica.")
