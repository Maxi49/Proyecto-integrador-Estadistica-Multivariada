# Revisión del código R (rama `pr2` = `claude/project-thread-d0v8xg`, PR #2)

Revisión de `R/00_datos.R` a `R/07_figuras.R`, `R/ejecutar_todo.R`, `R/aux_diagnostico_af.R`, los scripts de `python/` y `Como_ejecutar.txt`, contrastada con las decisiones del informe final (PDF de 25 páginas) y con el recálculo independiente de la revisión estadística previa.

## 1. Resumen

- **El pipeline corre completo y sin errores** con `Rscript R/ejecutar_todo.R` (unos 30 s, `LANG=C.UTF-8`). Con la rama tal cual llegó **fallaba en `07_figuras.R`** porque el paquete `patchwork` no estaba instalado y no figuraba en `Como_ejecutar.txt`. Se lo instaló y se agregó a las instrucciones.
- **Las tablas de `resultados/tablas/` coinciden con las cifras del informe** (detalle en la sección 4). Las cifras de las tablas son correctas; lo que estaba mal era lo que las rodeaba: texto fijo en `05_integracion.R`, un verificador de Python de la versión anterior, la leyenda de la figura 6 y varias figuras.
- **Quedaban restos de la versión anterior** (k = 6, GLS, ACM de 7 activas) en `python/verificar_resultados.py` (fallaba), `Como_ejecutar.txt`, comentarios de `04_acm.R`, las figuras de `resultados/figuras/` (regeneradas) y, sin tocar, en `CONTEXTO_PROYECTO.md`, `docs/guion_exposicion.md`, `docs/validacion_decisiones.md` y todo `informe/` (LaTeX y `main.pdf`).
- Se corrigieron las figuras 5, 6 y 11. Las figuras 1 y 10 ya cumplían.
- Los valores que necesita el informe para sus correcciones están en `docs/valores_para_informe.md`.

## 2. Problemas encontrados por script

### Críticos (cambian lo que el informe puede afirmar o impiden correr)

| Dónde | Problema | Estado |
|---|---|---|
| `R/ejecutar_todo.R`, `Como_ejecutar.txt` | `07_figuras.R` necesita `ggplot2`, `ggrepel`, `patchwork` (y la fuente Carlito) y las instrucciones no los listaban: el pipeline se cortaba en el último script. | Corregido en las instrucciones (`d03df88`). |
| `python/verificar_resultados.py` | Verificaba el WSS de k = 6, exigía una fila `gls` que no existe y reconstruía un ACM de 7 variables: fallaba con la rama final. | Corregido (`d03df88`); ahora pasa. |
| `R/07_figuras.R`, fig05 | Los puntos ya estaban coloreados y los extremos rotulados, pero el factor de escala de las flechas (4,5) no se declaraba en ningún lado. | Corregido: va al pie de la figura (`34415f5`). |
| `R/07_figuras.R`, fig06 | La leyenda decía "percentil 95", pero `fa.parallel` exporta en `fa.sim` el **promedio** de las 100 simulaciones (verificado: `pc.sim[1]` = 1,0803 coincide con la media simulada, no con el percentil 95 = 1,0965). | Leyenda corregida a "promedio de 100 simulaciones" (`34415f5`). El informe debe cambiar el epígrafe de la Figura 6 en el mismo sentido. |
| `R/07_figuras.R`, fig11 | El eje decía 83,5 % y 8,1 % (inercia ajustada) mientras las coordenadas son las del ACM estándar (cruda: 34,9 % y 16,6 %), y los rótulos se superponían en la zona central. | Rehecha en dos paneles (mapa y ampliación), escala 1:1, ejes con ambos porcentajes (`34415f5`). |
| `informe/` (LaTeX, `main.pdf`), `CONTEXTO_PROYECTO.md`, `docs/guion_exposicion.md`, `docs/validacion_decisiones.md` | Siguen describiendo AF con GLS (68,6 %), k = 6 y ACM de 7 variables (41,4 % crudo). Contradicen el informe final y el código. | **No se tocó**: ver recomendaciones. |

### Importantes

| Dónde | Problema | Estado |
|---|---|---|
| `R/05_integracion.R` | Cifras escritas a mano ("74,51 %", "V = 0,405", "91,7 %") y una frase de la versión k = 6 ("un grupo mayormente normal y dos mayormente ataque"; con k = 4 los grupos tienen 46, 73, 5 y 91 % de ataques). Además no reflejaba que el AF es ML con unicidad en el límite ni la inercia cruda del ACM. | Reescrito: las cifras se leen de las tablas (`d03df88`). La tabla `integracion_tecnicas.csv` ahora dice 74,51 %, 67,0 %, V = 0,405, 91,7 % ajustada y 51,6 % cruda, y 46/73/5/91 % de ataques por grupo. |
| `R/02_af.R` | El ajuste solo guardaba χ² y RMSR. La revisión estadística muestra RMSEA = 0,204 y TLI = 0,716, que el informe no menciona y que contradicen el argumento "el χ² rechaza solo por el tamaño de muestra". Además emitía dos avisos por corrida (ultra-Heywood y pesos de puntajes) que son esperables pero asustan. | `af_ajuste.csv` incluye ahora `rmsea` (0,2038) y `tli` (0,7158); avisos del diagnóstico minres silenciados con comentario (`d03df88`). |
| `R/07_figuras.R`, figs 9 y 11 | Los nombres G1 a G4 se asignan por posición del número de cluster. Si cambia la numeración de k-means (otra versión de R, otro orden) las etiquetas quedarían intercambiadas sin ningún error. | Se agregó un `stopifnot` con los tamaños esperados 1.220 / 2.444 / 1.121 / 215 (`34415f5`). |
| `R/07_figuras.R`, fig05 | Los id de los flujos extremos (127446, 97189, 44648) estaban escritos a mano. | Ahora se buscan (mínimo de CP1, máximo y mínimo de CP2) y salen los mismos tres (`34415f5`). Ojo: `acp_extremos.csv` guarda los tres de mayor distancia (127446, 125215, 136451), que **no** son los del texto del informe. |
| Figuras de `resultados/figuras/` (python) | Los PNG versionados estaban desactualizados respecto de las tablas finales (cambiaron al regenerarlos). | Regeneradas y commiteadas (`d03df88`). |
| `R/07_figuras.R` | Dependía de la fuente Carlito sin respaldo (en Windows/macOS sin la fuente, fallaría o cambiaría el ancho del texto). | Respaldo a `sans` (`34415f5`). |

### Menores

- `R/06_logistica.R`: el encabezado dice "partición estratificada por label" y más abajo se estratifica por `attack_cat`; "decidido por el grupo/orquestador" es un resto de proceso. Sin impacto en resultados.
- `R/06_logistica.R` reescribe `resultados/muestra_particion_70_30.xlsx` (1,9 MB) en cada corrida con bytes distintos, lo que ensucia los diffs de git (se restauró antes de commitear). Conviene no versionarlo o generarlo solo bajo pedido.
- `R/05_integracion.R` cargaba `base` y `X` sin usarlos (se quitó `X`).
- `R/ejecutar_todo.R` supone que se corre desde la raíz del repositorio; falla con un error poco claro si no es así. Se sugiere `stopifnot(file.exists("R/ejecutar_todo.R"))` al inicio.
- fig08 (dendrograma de variables): la etiqueta más larga toca el borde inferior del rectángulo de los bloques; es cosmético.
- fig07: el eje del silhouette está truncado en 0,20 a 0,36 y solo muestra el codo de k-means (el texto del informe menciona que se miró también Ward).
- `ejecutar_todo.R` y `00_datos.R` usan `set.seed(42)` en todos los scripts; está bien, y k-means lo reinicia dentro del bucle de k. No hay semillas ocultas ni aleatoriedad sin controlar (los repel de las figuras usan `seed = 42`).
- No se encontraron rutas absolutas ni dependencias de la máquina más allá de la fuente.
- Código muerto: ninguno relevante en `00` a `07`. `aux_diagnostico_af.R` compara `gls` a propósito (es el diagnóstico de estimadores) y funciona; no forma parte de `ejecutar_todo.R`, como se declara.

## 3. Estado de las figuras del informe (`resultados/figuras_informe/`, 16 cm de ancho, 300 ppp)

| Figura | Estado | Detalle |
|---|---|---|
| fig01 boxplots | Cumple (sin cambios) | Usa bisagras de Tukey (`fivenum`) y el script verifica con `stopifnot` los 1.715 flujos (34,3 %). Por variable: dbytes 1.056, ct_src_dport_ltm 581, ct_dst_sport_ltm 466 (cajas colapsadas en la moda, se ve en la figura). |
| fig05 biplot | Corregida | Los 5.000 puntos, sin recorte, coloreados por tipo de tráfico con leyenda; centros de cada tipo; flujos 127446 (−9,57; 5,20), 97189 (6,33; 5,32) y 44648 (−0,02; −3,55) rotulados y dentro de la ventana; escala 1:1; pie con "flechas = correlación × 4,5". |
| fig10 mapa ACS | Cumple (sin cambios) | `coord_equal()`, 77,9 % y 22,1 %, coma decimal, sin solapamientos. |
| fig11 mapa ACM | Corregida | Dos paneles con escala 1:1 (completo y ampliación del bloque central), ejes "Dim 1 (83,5 % de la inercia ajustada; 34,9 % de la cruda)" y "Dim 2 (8,1 % ajustada; 16,6 % cruda)", rótulos legibles. |
| fig06 | Corregida | Leyenda "promedio de 100 simulaciones". |

Legibilidad: las figuras están hechas para 16 cm (el `\linewidth` del informe es 16 cm con márgenes de 2,5 cm): texto de ejes de 7,2 pt y rótulos de 6,8 a 7,6 pt. Si se las reduce por debajo de 14 cm, los rótulos de los mapas bajarán de 7 pt; conviene insertarlas con `width=\linewidth`. Todas usan coma decimal (el eje x de la fig01 solo tiene enteros y el mapa de calor lleva coma en las celdas). En el mapa de fig11 queda un punto ("Otros ataques") apenas tapado por su propio rótulo.

## 4. Verificación de las tablas contra el informe

| Tema | Tabla | Valor en la tabla | Informe | OK |
|---|---|---|---|---|
| ACP | `acp_autovalores` | 5,195 / 2,026 / 1,721; 43,3 / 16,9 / 14,3 %; acum. 74,51 % | igual | Sí |
| AF | `af_varianza`, `af_cargas_completas` | 23,7 / 21,7 / 21,6 % = 67,0 %; spkts h² 0,995 (u² = 0,005); ct_srv_src 0,88 / h² 0,82; sinpkt 0,955 / 0,968 | igual | Sí |
| AF | `af_ajuste` | χ²(33) = 6.887,4; RMSR 0,059; RMSEA 0,204; TLI 0,716 | χ² y RMSR en el informe; RMSEA y TLI faltan | Sí (ampliado) |
| Clusters | `cluster_tamanos` | 1.220 / 2.444 / 1.121 / 215 | igual | Sí |
| Clusters | `cluster_proporcion_ataques` | 45,9 / 72,9 / 4,9 / 90,7 % | 46 / 73 / 5 / 91 | Sí |
| Clusters | `cluster_comparaciones` | ARI Ward-k-means 0,772; k-means log vs ACP 0,958 | 0,77 y 0,96 | Sí |
| Clusters | `cluster_metricas` | SSW 41.918 / 34.422 / 27.700 / 24.654 / 22.600 / 20.742 / 19.343; silhouettes de la Tabla C1 | igual | Sí |
| ACM | `acm_autovalores` | crudo 34,93 y 16,63 %; ajustado 83,54 y 8,13 % | 83,5 y 8,1 (ajustada); 34,9 y 16,6 sin informar | Sí |
| ACM | `acm_eta2` | Dim 1: estado 0,921, protocolo 0,912, duración 0,749; Dim 2: estado 0,720, protocolo 0,505, servicio 0,478 | igual | Sí |
| ACM | `acm_categorias_contribuciones` | ver `docs/valores_para_informe.md` | Tabla 11 incompleta (faltan 3 filas) | Corregir en el informe |
| ACS | `acs_asociacion`, `acs_inercia` | χ²(8) = 1.637,2; V = 0,4046; 77,9 y 22,1 % | igual | Sí |
| Atípicos | `atipicos_limites` | 1.715 flujos; dbytes 1.056; ct_src_dport_ltm 581; ct_dst_sport_ltm 466 | igual | Sí |

## 5. Commits locales en `pr2` (no se hizo push)

| Hash | Contenido |
|---|---|
| `34415f5` | `R/07_figuras.R` y PNG de `resultados/figuras_informe/`: figs 5, 6 y 11, id de extremos calculados, fuente con respaldo, chequeo de grupos. |
| `d03df88` | `02_af.R` (RMSEA, TLI, avisos), `04_acm.R` (comentario), `05_integracion.R` (cifras desde tablas), `verificar_resultados.py`, `Como_ejecutar.txt`, tablas y figuras de `python/` regeneradas. |
| (este commit) | `docs/valores_para_informe.md` y `docs/revision_codigo.md`. |

## 6. Qué recomiendo que decida el grupo

1. **Qué hacer con `informe/` (LaTeX y `main.pdf`) y los documentos de apoyo** (`CONTEXTO_PROYECTO.md`, `guion_exposicion.md`, `validacion_decisiones.md`): hoy cuentan otra historia (GLS 68,6 %, k = 6, ACM de 7 variables con 41,4 % crudo). Si el informe oficial es el PDF de 25 páginas, conviene borrar o archivar esos archivos, o actualizarlos, antes de entregar el repositorio; un lector que los abra encontrará cifras contradictorias.
2. **Informar RMSEA (0,204) y TLI (0,716)** del AF y cambiar el argumento "el χ² rechaza por el tamaño de muestra": esos índices también indican ajuste pobre. Alternativa: presentar el AF como descriptivo y decirlo.
3. **Epígrafe de la Figura 6**: "promedio de las simulaciones", no percentil 95. Y epígrafe de la Figura 11: aclarar que el plano explica 91,7 % de la inercia ajustada (Greenacre) y 51,6 % de la cruda, y que las coordenadas son las del ACM estándar.
4. **Completar la Tabla 11** con las 14 filas de `docs/valores_para_informe.md` (faltan `dns` en Dim 1, `sin_respuesta` y `udp` en Dim 2) y corregir "913 de 945" (son 913 de 913).
5. **Unificar el criterio de atípicos**: bisagras de Tukey en texto y figura (ya hecho en el código); aclarar que en `ct_dst_sport_ltm` y `ct_src_dport_ltm` el RIC es casi nulo y el criterio marca todo lo que no es la moda.
6. **Versionar o no `resultados/`** (RDS, PNG, xlsx de 1,9 MB): cada corrida los cambia byte a byte y el diff de la revisión se llena de binarios. Sugerencia: versionar solo `tablas/` y `figuras_informe/`, y agregar el resto a `.gitignore`.
7. **Si se quiere dejar de depender de la numeración de k-means**, renombrar los grupos por su perfil (por ejemplo ordenándolos por tamaño) en `03_cluster.R` en lugar de por posición en `07_figuras.R`. Hoy está protegido por un `stopifnot`, que alcanza mientras no cambie la versión de R.
