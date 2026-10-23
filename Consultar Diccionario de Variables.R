library(readxl)

# Abre una ventana para seleccionar el Excel
ruta_excel <- file.choose()

# Importar ambas hojas
base <- read_excel(path = ruta_excel, sheet = "muestra")
info <- read_excel(path = ruta_excel, sheet = "diccionario")

info <- info[match(names(base), info$variable), ]

diccionario <- data.frame(
  nombre = info$variable,
  descripcion = info$descripcion,
  unidad = info$unidad,
  tipo = ifelse(
    info$tipo %in% c("continua", "conteo"),
    "numérica",
    "categórica"
  )
)

View(diccionario)
