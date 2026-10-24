# Validación de la entrega · 24/10/2026

Validaciones realizadas sobre la muestra Excel confirmada por el usuario:

- Ejecución completa de R/00_datos.R y del generador Matplotlib: finalizó sin errores.
- Segunda ejecución completa: los 26 archivos de datos y tablas tuvieron las mismas huellas SHA-256.
- Comparación en R: identical(read_excel(..., sheet = "muestra"), readRDS("datos/base_limpia.rds")) devolvió TRUE.
- La huella SHA-256 del Excel no cambió:
  74ba98f290ffb8930d76cad21ef69115865e1435d72fd1ae3f361ff09ee767f3.
- NumPy reprodujo las correlaciones, el determinante, KMO, MSA por variable,
  estadístico de Bartlett y bisagras de Tukey calculados por R.
- Las frecuencias de cada variable de X_cat suman 5.000; ninguna modalidad es menor a 5%.
- Se inspeccionaron visualmente las seis figuras PNG. Se corrigieron etiquetas
  superpuestas de los histogramas originales y el orden de las bandas ordinales.

Resultados principales: KMO 0,7482658585; MSA mínima 0,6205789753;
determinante 0,0000630243194453; Bartlett chi-cuadrado 48.303,5295 (66 gl), p < 0,001.
Control actual de atípicos: 1.715 flujos (34,30%), sin eliminación.
El p numérico de Bartlett se aproxima a cero por precisión de máquina; no se interpreta como probabilidad exactamente cero.

Alcance: estas comprobaciones verifican la preparación de la muestra recibida,
no la reconstrucción del muestreo/deduplicación anteriores ni la aprobación académica.
Hay una discrepancia documentada en is_ftp_login = 4; esa variable no entra en los conjuntos analíticos.
Las versiones ejecutadas se registran en resultados/sesion_R.txt y
resultados/procedencia_validacion.json. Las hipótesis y X_cat son propuestas para revisión grupal.
