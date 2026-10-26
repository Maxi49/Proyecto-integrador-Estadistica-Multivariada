# Guía de redacción del informe (para todos los que escriben capítulos)

## Límite de páginas (lo más importante)
El cuerpo (de la Introducción a las Conclusiones) **no puede superar 15 páginas**. Para que
también se cumpla si la docente cuenta portada, índices y referencias, el objetivo es
**12 páginas de cuerpo**. Presupuesto por capítulo (páginas A4 compiladas, con figuras):

| Archivo | Capítulo | Páginas |
|---|---|---|
| capitulos/01_introduccion.tex | Introducción: contexto, pregunta guía, hipótesis | 0,75 |
| capitulos/02_datos.tex | Datos: base, X_num, X_cat, calidad, descriptiva, supuestos | 1,75 |
| capitulos/03_acp.tex | ACP | 1,5 |
| capitulos/04_af.tex | AF (incluye tabla ACP vs AF) | 1,5 |
| capitulos/05_cluster.tex | Conglomerados (observaciones y variables) | 2 |
| capitulos/06_acm.tex | ACS y ACM | 1,75 |
| capitulos/07_logistica.tex | Regresión logística | 1,25 |
| capitulos/08_integracion.tex | Integración, hipótesis, limitaciones, conclusiones | 1,5 |

Lo que no entre va al **Anexo A** (anexos/anexo_a_complementos.tex), que no cuenta para el
límite: figuras secundarias, tablas largas, detalles. En el cuerpo se cita: "(ver Anexo A, Figura A.3)".
Para escribir en el Anexo A, NO edites el archivo directamente si otro agente también lo hace:
creá `anexos/a_<tu_capitulo>.tex` (p. ej. `anexos/a_acp.tex`) y el orquestador lo incluye.

## Formato LaTeX (el preámbulo ya está en informe/main.tex: no lo modifiques)
- Cada capítulo empieza con `\section{...}` y `\label{sec:...}` (ya están en los archivos). Usá `\subsection` con moderación.
- Compilar para controlar, SIEMPRE con carpeta de salida propia (hay agentes compilando en paralelo): `cd informe && latexmk -pdf -interaction=nonstopmode -outdir=/tmp/tex_<tu_capitulo> main.tex`. Mirá las páginas de tu capítulo con `pdftoppm -f N -l M -r 60 -png main.pdf /tmp/...` y la herramienta Read.
- Figuras (están en ../resultados/figuras, ya en graphicspath):
  ```latex
  \begin{figure}[H]
    \centering
    \grafico[0.9\linewidth]{08_acp_codo_biplot.png}
    \caption{Texto que explica qué muestra y qué se concluye. Fuente: elaboración propia con UNSW-NB15.}
    \label{fig:acp-biplot}
  \end{figure}
  ```
  `\grafico` agrega el recuadro que pide la consigna. Epígrafe SIEMPRE debajo, explicativo (no solo un título).
- Tablas: epígrafe arriba, `booktabs`, envueltas en `tablacompacta` para interlineado simple:
  ```latex
  \begin{table}[H]
    \centering
    \caption{...}\label{tab:...}
    \begin{tablacompacta}
    \begin{tabular}{lrr} \toprule ... \bottomrule \end{tabular}
    \end{tablacompacta}
  \end{table}
  ```
- Números con coma decimal ("74,5 %", "0,748"). Hasta 2–3 decimales. p-valores: "p < 0,001".
- Nombres de variables en `\texttt{log\_spkts}` (escapar el guion bajo).
- Citas: `\citep{clave}` / `\citet{clave}`. Claves existentes en informe/referencias.bib. Si necesitás una referencia
  nueva (libro de multivariada, paquete de R), agregala al .bib con datos reales y verificables (autor, año, título,
  editorial/DOI). No inventes referencias. Referencias útiles y reales: Hair et al. (2019) *Multivariate Data Analysis* 8.ª ed., Cengage;
  Johnson y Wichern (2007) *Applied Multivariate Statistical Analysis* 6.ª ed., Pearson; Greenacre (2017) *Correspondence Analysis in Practice* 3.ª ed., CRC;
  Revelle (2024) paquete psych; Husson, Lê y Pagès (2017) *Exploratory Multivariate Analysis by Example Using R* 2.ª ed., CRC;
  Hosmer, Lemeshow y Sturdivant (2013) *Applied Logistic Regression* 3.ª ed., Wiley; Kaufman y Rousseeuw (1990) *Finding Groups in Data*, Wiley;
  Horn (1965) análisis paralelo, Psychometrika 30(2):179–185; Kaiser (1974) KMO, Psychometrika 39(1):31–36; R Core Team (2024).
  Si agregás una, usá exactamente esos datos o verificá.

## Contenido y estilo
- Español formal y claro, en primera persona del plural ("observamos", "decidimos"). Justificar cada decisión.
- **Cada número sale de un CSV de resultados/tablas o de lo que corriste.** Nunca de memoria ni del contexto si el CSV dice otra cosa. Si un número del contexto no coincide con el CSV, manda el CSV.
- Interpretar sin sobreinterpretar: técnicas descriptivas, datos de laboratorio, ataques sintéticos.
- Cada capítulo cierra con 1–3 oraciones que conecten con la hipótesis correspondiente (H1–H4, ver docs/etapa0_pregunta_hipotesis.md).
- Reglas del proyecto: tipo_trafico, label y attack_cat no construyen ACP/AF/clusters; solo colorean o se cruzan después.
- No modifiques scripts de R ni de Python salvo que se te pida. Si una figura necesaria no existe o se ve mal, avisá en tu respuesta final.
