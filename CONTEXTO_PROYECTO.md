# CONTEXTO DEL PROYECTO · Estadística Multivariada · UNSW-NB15

> Archivo de contexto para el grupo y para cualquier agente de IA (Claude, Codex, Cursor, etc.).
> **Leelo completo antes de tocar código o datos.** Si sos un agente, respetá la sección 11.
> Última actualización: 23/10/2026.
>
> **Regla de lectura:** este archivo distingue tres cosas: lo **hecho** (existe y está verificado),
> lo **decidido por el grupo** y lo **pendiente o no decidido**. Si algo no figura como decidido, no lo está.

---

## 1. Qué es esto

- **Materia:** Estadística Multivariada, 2.º semestre 2026. UCC (Universidad Católica de Córdoba), sede Río Cuarto.
- **Docente:** Prof. Silvana Malpassi.
- **Trabajo:** proyecto integrador grupal. Se aplican sobre **una misma base** las técnicas multivariadas vistas en clase.
- **Herramienta:** R (paquete `psych` para KMO, MSA y Bartlett).
- **Técnicas de la Parte 2 (consigna actual):** ACP, AF, conglomerados (de observaciones y de variables), ACS y ACM.
- **Regresión logística:** viene en una **parte posterior** del proyecto. El objetivo es predecir si un flujo es ataque o normal. La pregunta guía y las hipótesis de la Etapa 0 tienen que contemplarla desde ahora.
- **Repositorio:** https://github.com/Maxi49/Proyecto-integrador-Estadistica-Multivariada (contenido no revisado en esta actualización).

---

## 2. Estado actual (23/10/2026)

| Qué | Estado |
|---|---|
| Base limpia y estratificada (xlsx) | ✅ Hecha y entregada a la profe. Corregida el 23/10 (solo el diccionario, ver sección 6). **Falta reenviarla.** |
| Chequeo del determinante en R | ⏳ Pendiente. Los números de este archivo se calcularon en Python; hay que reproducirlos en R |
| Pregunta guía e hipótesis | ❌ No definidas por el grupo |
| Script `00_datos.R` | ❌ No existe |
| Capítulo "Datos" del informe | ❌ No existe |
| Etapas 1 a 6 | ❌ No empezadas |

**Importante:** existía un texto de contexto anterior, generado por otra sesión de IA, con decisiones "D1–D9", hipótesis H1–H4, scripts y documentos (`decisiones.md`, `reporte_etapa0.md`, `vars_proyecto.rds`, etc.). **Nada de eso fue decidido por el grupo y esos archivos no existen.** Lo único real es la base. Las ideas de esa sesión están resumidas como referencia en la sección 10.

---

## 3. Qué pide la consigna (Parte 2)

| Etapa | Qué pide | Producto |
|---|---|---|
| **0. Exploración y preparación** | (a) Pregunta guía (1–2 oraciones) y **tres hipótesis**: qué variables se mueven juntas, si hay grupos de observaciones, qué asociaciones entre categorías. (b) Importar en R y armar el diccionario (nombre, descripción, unidad, tipo). (c) Calidad: faltantes, duplicados, imposibles y atípicos (boxplots y criterio explícito); decidir y registrar qué se hace con cada problema. (d) Descriptiva: resúmenes, histogramas, matriz de correlaciones con mapa de calor, tablas de frecuencia. (e) Piloto de supuestos: correlaciones, Bartlett, KMO y MSA (`psych`); congelar X_num (≥ 8 numéricas) y X_cat. (f) Un script por etapa, `set.seed` fijo, base limpia guardada | Base aprobada, capítulo "Datos" con descripción e hipótesis, `00_datos.R` |
| **1. ACP** | `prcomp(X_num, scale. = TRUE)` justificando la estandarización (mirar varianzas; comparar con la versión sin estandarizar). Autovalores, varianza explicada y acumulada, Kaiser, codo. Interpretar con correlaciones, contribuciones y cos2; nombrar las dos primeras. Biplot coloreado por una categórica de contexto; describir ≥ 3 observaciones extremas | Capítulo "ACP", `01_acp.R` |
| **2. AF** | Supuestos: **determinante > 0,00001**, Bartlett p < 0,05, KMO y MSA (si MSA < 0,50, sacar de a una, la peor primero). Cantidad de factores (gráfica y analíticamente). Matriz de patrón ocultando cargas < 0,40, comunalidades, unicidades, varianza explicada, cargas cruzadas (diferencia ≥ 0,20). Nombrar factores. Guardar puntajes. Tabla comparativa ACP vs AF y cuál conviene | Capítulo "AF", `02_af.R` |
| **3. Conglomerados** | Jerárquico (euclidiana, Ward.D2, dendrograma). Elegir k con codo y silhouette para k = 2 a 8. K-means (nstart = 25, semilla fija) comparado con el jerárquico. Repetir sobre puntajes del ACP/AF y comparar con variables originales. **Cluster de variables** (dendrograma) comparado con componentes y factores. Perfil de cada cluster (medias originales y estandarizadas, mapa de calor, nombre) y cruce con la variable de contexto. Guardar el cluster en la base | Capítulo "Clustering", `03_cluster.R` |
| **4. ACS y ACM** | X_cat: categóricas de la base **más al menos 3 numéricas discretizadas** con cortes justificados; agrupar categorías < 5 %. ACS con dos variables. ACM: autovalores, inercia (ajustada: Benzécri o Greenacre, `ca::mjca`), dimensiones a retener, mapa, contribuciones, cos2, eta², nombre de dimensiones. Cluster de la Etapa 3 como suplementaria. Tres asociaciones relevantes sin sobreinterpretar | Capítulo "ACM", `04_acm.R` |
| **5. Informe y exposición** | PDF A4, márgenes 2,5 cm, Arial o Calibri 11, interlineado 1,5, justificado, número de página abajo a la derecha, portada completa, índices, gráficos con epígrafe, referencias en página aparte ordenadas alfabéticamente. Exposición oral ≤ 20 minutos | Informe PDF |
| **6. Integración** | Tabla con una fila por técnica (ACP, AF, cluster de variables, cluster de observaciones, ACM). ¿Se confirmaron las hipótesis? ¿Coinciden los bloques? ¿Los clusters se explican por las dimensiones y el ACM? Limitaciones y próximos pasos | Parte de la exposición |

---

## 4. La base: UNSW-NB15

- **Qué es:** tráfico de red etiquetado para detección de intrusiones. Lo creó el Australian Centre for Cyber Security (UNSW Canberra) en 2015.
- **Unidad de análisis:** cada fila es un **flujo**, una "conversación" entre dos equipos de la red.
- **Cómo se generó:** en un laboratorio. El tráfico normal es realista, pero **los ataques son sintéticos** (herramienta IXIA PerfectStorm). Es una limitación que hay que declarar.
- **Origen de nuestra muestra:** el archivo de training de UNSW-NB15 (175.341 filas × 45 columnas), sin duplicados y muestreado.
- **Fuente oficial:** https://research.unsw.edu.au/projects/unsw-nb15-dataset
- **Licencia:** uso libre para investigación académica, citando:
  - Moustafa, N., & Slay, J. (2015). UNSW-NB15: a comprehensive data set for network intrusion detection systems. *MilCIS*, IEEE. https://doi.org/10.1109/MilCIS.2015.7348942
  - Moustafa, N., & Slay, J. (2016). The evaluation of Network Anomaly Detection Systems… *Information Security Journal: A Global Perspective*, 25(1–3), 18–31. https://doi.org/10.1080/19393555.2015.1125974
- **Convención de nombres:** prefijo `s` = origen → destino (quien inicia); `d` = destino → origen (quien responde).

### Tipos de tráfico (`attack_cat`)

| Categoría | Qué es |
|---|---|
| Normal | Tráfico legítimo |
| Generic | Ataques contra cifrados por bloques |
| Exploits | Aprovechar un fallo conocido de un software |
| Fuzzers | Bombardear un programa con datos aleatorios para que falle |
| DoS | Saturar un servicio para dejarlo inaccesible |
| Reconnaissance | Escaneo previo al ataque (puertos, servicios) |
| Analysis | Escaneos, spam, ataques por HTML |
| Backdoor | Acceso oculto salteando la autenticación |
| Shellcode | Código inyectado para tomar control de la máquina |
| Worms | Malware que se replica solo |

---

## 5. El archivo de trabajo (hecho y verificado)

**Archivo:** `muestra_estratificada-ataques.xlsx` (versión corregida del 23/10).

| Hoja | Contenido |
|---|---|
| `muestra` | 5.000 filas × 68 columnas. Los datos |
| `diccionario` | Una fila por columna: `variable`, `descripcion`, `unidad`, `tipo`, `rol`, `motivo_exclusion` |

La columna `rol` del diccionario dice para qué se usa cada variable: **X_num** (ACP, AF, clusters), **X_cat** (ACM), **excluida**, **contexto** o **respuesta**.

### Lo que ya trae la base aplicado

Estas decisiones **ya están aplicadas en el archivo** que se entregó. Las tomó la otra sesión; el grupo **todavía tiene que asumirlas y saber justificarlas** (o cambiarlas y reenviar la base).

| Decisión aplicada | Dato verificado en la base | Argumento para defenderla |
|---|---|---|
| Se sacaron filas duplicadas | 0 duplicados. En el training original eran el 38,6 % (casi todas ataques automáticos) | Se analizan perfiles únicos de flujo. Consecuencia: las proporciones no son prevalencias reales |
| Muestra estratificada proporcional de 5.000 por `attack_cat` | Normal 48,2 %, Exploits 18,4 %, Fuzzers 15,0 %, Reconnaissance 7,0 %, Generic 3,9 %, DoS 3,5 %, Analysis 1,5 %, Backdoor 1,4 %, Shellcode 1,0 %, Worms 0,1 % | Tamaño manejable para clustering jerárquico; mantiene las proporciones |
| `label` como respuesta | 51,8 % ataque, 48,2 % normal | Para la logística de la parte posterior |
| Faltantes | 0 NA. `service = "-"` → "ninguno" (sin servicio, no faltante) | Ceros en variables TCP son estructurales (flujos no TCP o sin respuesta): no se imputan |
| Transformación log(x+1) | Columnas `log_*` = exactamente `log1p()` de las crudas. Asimetría de `sbytes` baja de 33,3 a 1,0 | Asimetría extrema en las crudas. Siguen asimétricas `log_ct_dst_sport_ltm` (4,7), `log_ct_src_dport_ltm` (3,1), `log_dur` (2,8) |
| Atípicos marcados, no borrados | `n_atipicos`: 32,1 % de flujos con ≥ 1 variable fuera de 1,5 × IQR (en escala log) | En ciberseguridad lo extremo puede ser el fenómeno. Faltan los boxplots |
| Categóricas agrupadas | Ninguna categoría < 7 % (ver sección 7) | Cumple el 5 % de la consigna |

---

## 6. X_num: 12 numéricas (decidido por el grupo el 23/10)

Se usan las versiones `log_`.

| Bloque esperado | Variable | Significado | Unidad |
|---|---|---|---|
| Volumen | `spkts` | Paquetes enviados por el origen | paquetes |
| Volumen | `sbytes` | Bytes enviados por el origen | bytes |
| Volumen | `dbytes` | Bytes enviados por el destino | bytes |
| Temporización | `dur` | Duración total del flujo | segundos |
| Temporización | `sinpkt` | Tiempo promedio entre paquetes del origen | ms |
| Temporización | `sjit` | Jitter del origen (variabilidad del tiempo entre paquetes) | ms |
| Temporización | `synack` | Handshake TCP: tiempo entre SYN y SYN-ACK (0 si no es TCP) | segundos |
| Contexto | `ct_srv_src` | De las últimas 100 conexiones: mismo servicio y misma IP origen | conteo |
| Contexto | `ct_srv_dst` | Mismo servicio y misma IP destino | conteo |
| Contexto | `ct_src_ltm` | Misma IP origen | conteo |
| Contexto | `ct_src_dport_ltm` | Mismo origen y mismo puerto destino | conteo |
| Contexto | `ct_dst_sport_ltm` | Mismo destino y mismo puerto origen | conteo |

Los `ct_*` son conteos (no continuas estrictas).

### Por qué se sacaron `dpkts` y `rate` (cambio del 23/10)

- **Problema:** con las 14 variables originales, el determinante de la matriz de correlaciones daba **1,03 × 10⁻⁷**. La consigna (Etapa 2, punto a) pide **> 0,00001** para el AF.
- **Causa:** redundancia. `dpkts` tiene r = 0,95 con `dbytes` (VIF 50,5: el 98 % de su variación se explica con las otras). `rate` es exactamente (spkts + dpkts − 1) / dur, una variable derivada; además r = −0,91 con `sinpkt` (VIF 14,3).
- **Por qué dos y no una:** sacando solo `dpkts` el determinante queda en 5,2 × 10⁻⁶, todavía bajo el umbral.
- **Por qué `dpkts` y no `dbytes`:** `dpkts` es la más redundante (VIF 50 vs 28) y los bytes miden mejor el volumen.
- **Las columnas siguen en la base** (rol "excluida"). `dpkts` sirve para discretizar "con / sin respuesta" en el ACM.

### Supuestos con las 12 (calculados en Python; **reproducir en R**)

| Indicador | 14 originales | 12 actuales |
|---|---|---|
| Determinante | 1,03 × 10⁻⁷ ❌ | 6,3 × 10⁻⁵ ✅ |
| KMO global | 0,786 | 0,748 |
| MSA mínima | 0,673 | 0,621 (`log_spkts`) |
| Autovalores > 1 | 3 | 3 (5,19 · 2,03 · 1,72) |
| Varianza con 3 componentes | 76,4 % | 74,5 % |

Con las 12, una rotación varimax de 3 componentes da tres bloques limpios (cargas ≥ 0,66 en su bloque): volumen (3), temporización (4) y contexto (5). `sjit` tiene una carga cruzada de 0,41 en volumen, con diferencia 0,40 (cumple el criterio de 0,20).

Código para verificar en R:

```r
library(readxl); library(psych)
datos <- read_excel("muestra_estratificada-ataques.xlsx", sheet = "muestra")
X <- datos[, c("log_dur","log_spkts","log_sbytes","log_dbytes","log_sinpkt","log_sjit","log_synack",
               "log_ct_srv_src","log_ct_srv_dst","log_ct_src_ltm","log_ct_src_dport_ltm","log_ct_dst_sport_ltm")]
det(cor(X))                            # ~6,3e-05
KMO(X)                                 # ~0,75; ninguna MSA < 0,5
cortest.bartlett(cor(X), n = nrow(X))
```

### Otras excluidas de X_num

El motivo de cada una está en la hoja `diccionario`. Resumen: derivadas de otras (`sload`, `dload`, `smean`, `dmean`, `tcprtt`), redundantes con pares incluidos (`ackdat`, `dinpkt`, `djit`, `sloss`, `dloss`, `ct_dst_ltm`, `ct_dst_src_ltm`), casi binarias (`swin`, `dwin`), aleatorias por diseño (`stcpb`, `dtcpb`), muchos ceros (`trans_depth`, `response_body_len`, `ct_flw_http_mthd`, `is_ftp_login`, `ct_ftp_cmd`), pocos valores (`sttl`, `dttl`, `ct_state_ttl`).

---

## 7. Categóricas disponibles

| Variable | Rol en el diccionario | Categorías (% en la muestra) |
|---|---|---|
| `tipo_trafico` | X_cat | Normal 48,2 · Exploits 18,4 · Fuzzers 15,0 · Otros ataques 11,5 · Reconnaissance 7,0. "Otros" = Generic + DoS + Analysis + Backdoor + Shellcode + Worms |
| `proto_g` | X_cat | tcp 70,8 · udp 21,9 · otros 7,3 |
| `service_g` | X_cat | ninguno 60,0 · http 17,4 · otros 12,3 · dns 10,3 |
| `state_g` | X_cat | FIN 69,3 · INT 18,3 · CON_otros 12,4 |
| `ttl_origen` | contexto (a decidir en Etapa 4) | 254 48,7 · 31 35,8 · otros 15,5 |
| `perfil_estado_ttl` | contexto (a decidir en Etapa 4) | 1 43,8 · 0 36,5 · 2_o_mas 19,7 |
| `repeticion_servicio` | contexto (a decidir en Etapa 4) | media 47,2 · baja 42,8 · alta 10,0 (cortes sobre `ct_srv_src`: 1–2, 3–10, > 10) |
| `usa_http` | contexto | 0 82,1 · 1 17,9 |

⚠️ **TTL:** `ttl_origen = 31` es **100 % tráfico normal** y `perfil_estado_ttl = 0` es 98,7 % normal. Es un artefacto del laboratorio (los atacantes tenían TTL fijo). Si entran al ACM, hay que aclararlo. **No usarlas como predictores en la logística** (separación perfecta).

⚠️ **Redundancia:** `proto_g = otros` coincide siempre con `service_g = ninguno` y `state_g = INT`. En el ACM puede formar un eje propio que no aporta nada nuevo.

---

## 8. Datos de la base útiles para escribir las hipótesis

No son hipótesis. Son hechos verificados que conviene tener en cuenta para no proponer algo que ya se sabe que no se cumple.

- **Bloques de variables:** las correlaciones muestran tres grupos claros: volumen, temporización y repetición de conexiones (`ct_*`).
- **Repetición de conexiones:** en la base sin duplicados, los ataques **no** repiten más que el tráfico normal. Media de `log_ct_srv_src`: Normal 1,67, Exploits 0,89, Fuzzers 1,65, Reconnaissance 1,08, Otros 1,78.
- **Conexiones sin respuesta** (`dpkts = 0`): Otros ataques 63 %, Fuzzers 33 %, Reconnaissance 27 %, Exploits 8 %, Normal 7 %.
- **Estado INT (conexión incompleta):** Otros ataques 62 %, Fuzzers 33 %, Reconnaissance 26 %, Exploits 8 %, Normal 6 %. Normal es el único con muchas "CON_otros" (24 %).
- **Protocolo:** TCP en Exploits 91 %, Normal 73 %, Reconnaissance 73 %, Fuzzers 67 %, Otros 35 %.
- **Ceros estructurales:** `synack` 29,6 % (flujos no TCP), `sjit` 25,9 %, `dpkts` y `dbytes` 18,9 % (sin respuesta). Es probable que el protocolo pese mucho en los clusters.

---

## 9. Lo que falta: decisiones y trabajo

### Decisiones pendientes del grupo

- [ ] Asumir (o cambiar) las decisiones ya aplicadas en la base (sección 5) y saber defenderlas.
- [ ] Pregunta guía (1–2 oraciones), que cubra también la logística.
- [ ] Tres hipótesis para la Parte 2 (variables que se mueven juntas · grupos de observaciones · asociaciones entre categorías) y una para la logística.
- [ ] Variable de contexto para colorear gráficos y cruzar clusters (candidata obvia: `tipo_trafico`).
- [ ] Qué 3 numéricas discretizar para el ACM y con qué cortes (Etapa 4).
- [ ] Qué categóricas entran al ACM y cuáles como suplementarias (Etapa 4).
- [ ] Qué par de variables para el ACS (Etapa 4).
- [ ] Cómo validar la logística: testing set original (habría que prepararlo igual que la muestra) o partir la muestra de 5.000 en 70/30.

### Trabajo pendiente inmediato (Etapa 0)

- [ ] Correr en R el chequeo de la sección 6 y confirmar los números.
- [ ] Reenviar la base corregida a la profe con la nota explicando el cambio.
- [ ] Escribir `00_datos.R`: importar, diccionario, calidad (faltantes, duplicados, imposibles, boxplots de atípicos), descriptiva (resúmenes, histogramas, mapa de calor de correlaciones, frecuencias), supuestos (determinante, Bartlett, KMO, MSA), congelar X_num y X_cat, `set.seed`, guardar la base.
- [ ] Escribir el capítulo "Datos" del informe con la descripción de la base y las hipótesis.

---

## 10. Referencia: lo que propuso otra sesión de IA (NO decidido)

| Propuesta | Qué dice la base |
|---|---|
| H1: tres factores (volumen, temporización, contexto) | Coherente con los datos, pero se escribió después de mirar las correlaciones |
| H2: los clusters separan Normal de ataques y mezclan los tipos de ataque | Posible, aunque el protocolo puede dominar la separación |
| H3: el tipo de tráfico se asocia con protocolo, servicio y estado ("Normal con TCP y FIN") | El ejemplo no se cumple: Reconnaissance tiene las mismas proporciones de TCP y FIN |
| H4: la repetición de conexiones es lo que más predice ataque | No se sostiene en la base sin duplicados (sección 8) |
| Logística con puntajes del ACP/AF como predictores, sin TTL ni `tipo_trafico` | Razonable: evita multicolinealidad y fuga de la etiqueta |
| Validar con el testing set original | No está preparado; es una opción, no un hecho |
| Tablero con variable de contexto | No aparece en la consigna de la Parte 2 |

---

## 11. Reglas para agentes de IA (y para humanos)

1. **No dar por decidido nada que este archivo no marque como decidido.** Si proponés algo, presentalo como propuesta.
2. **No modificar la hoja `muestra`.** Los datos ya fueron entregados. Si un resultado sugiere cambiar la base o X_num, reportalo y proponé; no lo implementes.
3. **X_num son las 12 de la sección 6.** No volver a las 14.
4. **`set.seed()` fijo** al inicio de todo script con algo aleatorio (k-means, muestreos).
5. **Rutas relativas** (por ejemplo con `here::here()`). Nada de `C:/Users/...`.
6. **Un script por etapa** (`00_datos.R`, `01_acp.R`, …) que corra de punta a punta. Comentarios en español explicando el porqué.
7. **No usar `label`, `attack_cat` ni `tipo_trafico`** para construir ACP, AF ni clusters. Solo para colorear o comparar después.
8. **Estandarizar** antes de ACP y clustering (`scale()` o `scale. = TRUE`).
9. **Salida explicable:** el grupo tiene que poder defender cada línea frente a la profe. Código simple antes que sofisticado.
10. Si algo no cierra (KMO raro, un cluster vacío, un warning), **avisar**. No esconderlo.
11. Los números de este archivo salieron de la muestra de 5.000. Si un agente cita cifras de otro lado (por ejemplo, del training completo), tiene que decirlo.

---

## 12. Limitaciones a declarar en el informe

- Ataques sintéticos: los resultados describen este laboratorio, no una red real.
- Sin duplicados se analizan perfiles únicos; las proporciones no son prevalencias reales.
- La probabilidad de ataque de la logística es relativa a esta base (52 % ataques): interpretar odds ratios, no porcentajes absolutos.
- Las variables TTL separan por artefacto del laboratorio.
- Los `ct_*` usan ventanas de 100 conexiones: los flujos no son estrictamente independientes.
- Con n = 5.000, Bartlett rechaza ante cualquier asociación: pesa más el KMO.
- Quedan variables asimétricas aun en log (`log_ct_dst_sport_ltm`, `log_ct_src_dport_ltm`, `log_dur`).
