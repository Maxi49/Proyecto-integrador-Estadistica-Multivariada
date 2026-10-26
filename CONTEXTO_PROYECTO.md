# CONTEXTO DEL PROYECTO · Estadística Multivariada · UNSW-NB15

> Archivo de contexto para el grupo y para cualquier agente de IA (Claude, Codex, Cursor, etc.).
> **Leelo completo antes de tocar código o datos.** Si sos un agente, respetá la sección 11.
> Última actualización: 26/10/2026 (reemplaza la versión del 23/10, que estaba desactualizada:
> decía que las Etapas 1 a 6 no estaban empezadas y el repositorio ya las tenía).
>
> **Regla de lectura:** este archivo distingue tres cosas: lo **hecho** (existe y está verificado),
> lo **decidido** y lo **pendiente**. Las decisiones del 26/10 las tomó una sesión de IA a pedido
> del grupo y están marcadas **[validar con el grupo]** hasta que el grupo las asuma.

---

## 1. Qué es esto

- **Materia:** Estadística Multivariada, 2.º semestre 2026. UCC (Universidad Católica de Córdoba), sede Río Cuarto.
- **Docente:** Prof. Silvana Malpassi.
- **Trabajo:** proyecto integrador grupal. Se aplican sobre **una misma base** las técnicas multivariadas vistas en clase.
- **Herramientas (decidido por el grupo el 26/10):** los **scripts de análisis quedan en R** (`psych` para KMO, MSA, Bartlett y AF; `cluster`; `ca` y `FactoMineR` para ACS/ACM; `MASS` y `pROC` para la logística). Las **representaciones gráficas se hacen en Python** (Matplotlib) leyendo las tablas que exporta R. **Todos los scripts se anexan al informe** (Anexo B).
- **Informe:** en LaTeX (`informe/`), con las normas de la Etapa 5 y un límite de **15 páginas sin contar anexos**.
- **Técnicas de la Parte 2:** ACP, AF, conglomerados (de observaciones y de variables), ACS y ACM. Además, **regresión logística** para predecir si un flujo es ataque o normal.
- **Repositorio:** https://github.com/Maxi49/Proyecto-integrador-Estadistica-Multivariada

---

## 2. Estado actual (26/10/2026)

| Qué | Estado |
|---|---|
| Base limpia y estratificada (xlsx) | ✅ Hecha. Sin cambios desde el 23/10. **Confirmar que se reenvió a la profe** con la nota de dpkts y rate |
| Chequeo del determinante, KMO y MSA en R | ✅ Reproducido en R: det 6,30×10⁻⁵, KMO 0,748, MSA mín. 0,621, Bartlett p < 0,001 |
| Pregunta guía e hipótesis H1–H4 | ✅ Redactadas (`docs/etapa0_pregunta_hipotesis.md`) **[validar con el grupo]** |
| Etapa 0 `R/00_datos.R` | ✅ Hecho |
| Etapa 1 ACP `R/01_acp.R` | ✅ Hecho |
| Etapa 2 AF `R/02_af.R` (+ `R/aux_diagnostico_af.R`) | ✅ Hecho. Corregido el 26/10 (caso Heywood, ver sección 6) |
| Etapa 3 conglomerados `R/03_cluster.R` | ✅ Hecho |
| Etapa 4 ACS/ACM `R/04_acm.R` | ✅ Hecho |
| Etapa 6 integración `R/05_integracion.R` | ✅ Hecho (sin cifras escritas a mano desde el 26/10) |
| Regresión logística `R/06_logistica.R` | ✅ Hecha el 26/10 **[validar con el grupo]** |
| Gráficos en Python (`python/`) | ✅ 18 figuras, coma decimal, `verificar_resultados.py` pasa |
| Informe LaTeX (`informe/`) | ✅ 8 capítulos + Anexo A (complementos, diccionario, resumen numérico, tabla de integración) + Anexo B (código). 15 páginas sin anexos (portada, 2 de índices, cuerpo pp. 4–14, referencias p. 15). Revisado por un revisor independiente el 26/10 y corregido. **Falta:** completar la portada (integrantes, facultad, carrera, fecha) y revisar la opinión del grupo (`% REVISAR GRUPO`) |
| Exposición oral (≤ 20 min) | ✅ Guion en `docs/guion_exposicion.md` (15 diapositivas, 18:45 min, 4 oradores, preguntas probables) y presentación de 15 diapositivas en Claude (artefacto privado «Exposición · UNSW-NB15 multivariado»; se descarga como PowerPoint o PDF y hay que compartirlo para que lo vea el resto del grupo). **[ensayar; completar nombres]** |
| Todo el pipeline | ✅ `Rscript R/ejecutar_todo.R` + 3 scripts de Python corren de punta a punta en ~15 s y reproducen los resultados |

---

## 3. Qué pide la consigna (Parte 2)

| Etapa | Qué pide | Dónde está |
|---|---|---|
| **0. Exploración y preparación** | Pregunta guía y 3 hipótesis; diccionario; calidad (faltantes, duplicados, imposibles, atípicos con boxplots y criterio); descriptiva; piloto de supuestos; congelar X_num y X_cat; un script por etapa con `set.seed` | `R/00_datos.R`, cap. 1 y 2 del informe, Anexo A.1 |
| **1. ACP** | `prcomp(scale. = TRUE)` justificando la estandarización; autovalores, Kaiser, codo; correlaciones, contribuciones, cos2; nombrar 2 CP; biplot coloreado; ≥ 3 extremos | `R/01_acp.R`, cap. 3 |
| **2. AF** | Determinante > 0,00001, Bartlett, KMO, MSA; nº de factores (gráfico y analítico); patrón con cargas < 0,40 ocultas, comunalidades, unicidades, varianza, cruzadas (≥ 0,20); nombres; puntajes; tabla ACP vs AF | `R/02_af.R`, cap. 4, Anexo A.2 |
| **3. Conglomerados** | Ward.D2 euclidiano; codo y silhouette k = 2–8; k-means nstart = 25; tabla cruzada; repetir con puntajes; cluster de variables; perfiles; cruce con contexto; guardar | `R/03_cluster.R`, cap. 5, Anexo A.3 |
| **4. ACS y ACM** | X_cat con ≥ 3 discretizadas y categorías ≥ 5 %; ACS de dos variables; ACM con inercia ajustada, dimensiones, mapa, contribuciones, cos2, eta², nombres; cluster suplementario; 3 asociaciones | `R/04_acm.R`, cap. 6, Anexo A.4 |
| **5. Informe y exposición** | PDF A4, márgenes 2,5 cm, Arial/Calibri 11, interlineado 1,5, justificado, nº de página abajo a la derecha, portada, índices, epígrafes, referencias en página aparte; exposición ≤ 20 min | `informe/main.tex`; `docs/guion_exposicion.md` |
| **6. Integración** | Tabla por técnica; ¿hipótesis? ¿bloques coinciden? ¿clusters explicados?; limitaciones y próximos pasos; opinión propia | `R/05_integracion.R`, cap. 8, exposición |

---

## 4. La base: UNSW-NB15

- **Qué es:** tráfico de red etiquetado para detección de intrusiones (Australian Centre for Cyber Security, UNSW Canberra, 2015).
- **Unidad de análisis:** cada fila es un **flujo** (una "conversación" entre dos equipos).
- **Generación:** en laboratorio. Tráfico normal realista, **ataques sintéticos** (IXIA PerfectStorm). Limitación a declarar.
- **Origen de la muestra:** archivo de training (175.341 filas × 45 columnas, cifra del sitio oficial; no está en el repositorio), sin duplicados y muestreado.
- **Fuente:** https://research.unsw.edu.au/projects/unsw-nb15-dataset · Moustafa y Slay (2015, 2016), citados en `informe/referencias.bib`.
- **Convención de nombres:** prefijo `s` = origen → destino; `d` = destino → origen.

Tipos de tráfico (`attack_cat`): Normal, Generic, Exploits, Fuzzers, DoS, Reconnaissance, Analysis, Backdoor, Shellcode, Worms (descripción en el informe, cap. 2).

---

## 5. El archivo de trabajo

**Archivo:** `muestra_estratificada-simulado-de-ataques.xlsx` (sin cambios desde el 23/10; el adjunto del 26/10 es idéntico byte a byte).

| Hoja | Contenido |
|---|---|
| `muestra` | 5.000 filas × 68 columnas. **No se modifica nunca.** |
| `diccionario` | `variable`, `descripcion`, `unidad`, `tipo`, `rol`, `motivo_exclusion` |

Decisiones ya aplicadas en la base (y cómo defenderlas): sin duplicados (perfiles únicos; las proporciones no son prevalencias), muestra estratificada proporcional de 5.000 por `attack_cat`, `label` como respuesta (51,8 % ataque), 0 faltantes (`service = "-"` → "ninguno"), ceros estructurales no imputados, `log1p()` por asimetría extrema, atípicos marcados y conservados, categóricas agrupadas (todas ≥ 5 %).

**Dato corregido:** con el criterio 1,5 × RIC sobre las 12 variables de X_num en escala log hay **1.715 flujos (34,3 %)** con al menos un atípico. El 32,1 % que decía la versión anterior corresponde a `n_atipicos` de la base, calculado sobre otro conjunto de variables.

### Partición para la logística (nuevo, 26/10)
- 70/30 **estratificada por `attack_cat`** (las 10 categorías del diseño muestral), `set.seed(42)`: 3.501 entrenamiento / 1.499 prueba, 51,8 % de ataques en ambos; las proporciones por tipo difieren < 0,05 puntos (Worms: 4 / 2).
- Exportada en `resultados/muestra_particion_70_30.xlsx` (hojas `entrenamiento`, `prueba`, `resumen`) y `resultados/tablas/log_reg_particion_ids.csv`.

---

## 6. Conjuntos congelados y decisiones por técnica

### X_num: 12 numéricas en escala log (decidido por el grupo el 23/10)
Volumen: `spkts`, `sbytes`, `dbytes` · Temporización: `dur`, `sinpkt`, `sjit`, `synack` · Repetición: `ct_srv_src`, `ct_srv_dst`, `ct_src_ltm`, `ct_src_dport_ltm`, `ct_dst_sport_ltm`. Se excluyeron `dpkts` (VIF 50,5) y `rate` (derivada, r = −0,91 con `sinpkt`) para que el determinante supere 10⁻⁵.

### X_cat: 7 categóricas (aplicado en el código; **[validar con el grupo]**)
`tipo_trafico` (5), `proto_g` (3), `service_g` (4), `state_g` (3) y tres discretizadas: `respuesta_destino` (`dpkts` = 0 → sin respuesta, 18,9 %), `duracion_banda` y `bytes_origen_banda` (terciles: `dur` 0,0185 y 0,709 s; `sbytes` 564 y 1.580 bytes). Criterio de los terciles: estadístico (variables muy asimétricas, categorías del 33 %, sin usar la etiqueta). TTL fuera.

### Resultados y decisiones por técnica

| Técnica | Resultado | Decisión y motivo |
|---|---|---|
| ACP | 3 CP, 74,5 % (43,3 + 16,9 + 14,3). CP1 *magnitud del flujo frente a repetición*, CP2 *volumen de tráfico*, CP3 *ritmo lento* | Kaiser + codo. Los ejes son mixtos (no reproducen los bloques puros) |
| AF | **3 factores, GLS, varimax**, 68,6 % de la varianza: F1 *Repetición de conexiones*, F2 *Temporización*, F3 *Volumen*. Sin Heywood (unicidad mín. 0,103) | **[validar con el grupo]** El análisis paralelo sugería 4, pero con 4 factores (y con minres, pa, ML con 3) `log_spkts` da comunalidad ≥ 1 (caso Heywood). El 4.º factor solo partía los `ct_*` en dos (r = 0,62 entre ellos) y su autovalor reducido es 0,43. Costo: ajuste global flojo (RMSR 0,051, TLI 0,61, RMSEA 0,24). Detalle: `docs/validacion_decisiones.md` |
| Cluster de variables | Tres bloques, idénticos a los factores (ARI = 1,000) | — |
| Cluster de observaciones | k-means k = 6 (silhouette 0,333); ARI Ward/k-means 0,813; con puntajes del ACP ARI 0,708 | **[validar con el grupo]** k = 6 gana por muy poco (k = 2–6 entre 0,302 y 0,333; el codo más claro está en k = 4). Clusters 2 y 6 mal separados. Cluster 3 (147 flujos) es 100 % ataque, 88,4 % Generic |
| ACS | `tipo_trafico` × `state_g`, V de Cramér 0,405, 2 dim. = 100 % | La asociación más fuerte de las candidatas y la que mejor encarna H3 |
| ACM | Q = 7, J = 23; plano Dim1–Dim2 = **87,4 % de inercia ajustada (Greenacre)**, 41,4 % cruda. Dim 1: conexión efímera sin respuesta frente a sesión TCP completa; Dim 2: DNS/UDP con estado CON frente a protocolo *otros* no establecido | Siempre aclarar si la inercia es ajustada o cruda |
| Logística | M2 = 3 puntajes del ACP (reajustado solo con entrenamiento) + `proto_g` + `service_g` + `state_g`. AUC prueba **0,882** [0,864–0,900]; exactitud 0,818, sensibilidad 0,915, especificidad 0,713. M1 (solo puntajes) AUC 0,795 | **[validar con el grupo]** Sin TTL (separación artificial) ni `tipo_trafico`/`attack_cat` (fuga de la etiqueta). Los OR de las categóricas son inestables (VIF ≈ 17–18; INT pasó de 93 a 375 al cambiar la partición): leerlos solo por su dirección |

### Hipótesis (veredicto en el informe, cap. 8)
- **H1** tres bloques (volumen, temporización, repetición): **confirmada** por AF y cluster de variables; el ACP los mezcla.
- **H2** grupos que separan parcialmente normal de ataque sin distinguir tipos: **parcial** (cluster 1 es 98,6 % normal, cluster 3 100 % ataque, pero el 3 sí aísla un tipo: Generic).
- **H3** ataque ↔ INT y sin respuesta; normal ↔ FIN/CON y servicios: **parcial** (vale para Otros ataques, Fuzzers y Reconnaissance; no para Exploits, que es 90 % FIN; dns pesa más en ataques).
- **H4** logística con AUC > 0,80 en prueba: **confirmada** (0,882), pero solo gracias a las categóricas (M1 da 0,795).

---

## 7. Categóricas disponibles y advertencias

| Variable | Uso | Categorías (%) |
|---|---|---|
| `tipo_trafico` | X_cat y contexto para colorear | Normal 48,2 · Exploits 18,4 · Fuzzers 15,0 · Otros ataques 11,5 · Reconnaissance 7,0 |
| `proto_g` | X_cat, logística | tcp 70,8 · udp 21,9 · otros 7,3 |
| `service_g` | X_cat, logística | ninguno 60,0 · http 17,4 · otros 12,3 · dns 10,3 |
| `state_g` | X_cat, logística | FIN 69,3 · INT 18,3 · CON_otros 12,4 |
| `ttl_origen`, `perfil_estado_ttl` | No se usan | Artefacto del laboratorio (31 = 100 % normal) |
| `repeticion_servicio`, `usa_http` | No se usan | — |

⚠️ **Redundancias (verificadas el 26/10):** **todos** los flujos con `state_g = INT` son `respuesta_destino = sin_respuesta` (913 de 913), y de los 945 sin respuesta solo 32 no son INT (son CON_otros). `proto_g = otros` implica siempre `service_g = ninguno` (363/363) y casi siempre INT (344/363). Explican la colinealidad de la logística y que el estado domine la Dim 1 del ACM.

---

## 8. Hechos de la base útiles para interpretar

- Repetición de conexiones: en la base sin duplicados los ataques **no** repiten más que el normal.
- Sin respuesta (`dpkts` = 0) e INT: Otros ataques 63 % y 62 %; Fuzzers 33 %; Reconnaissance 27 %; Exploits 8 %; Normal 7 % y 6 %. Normal es el único con muchas CON_otros (24 %).
- Ceros estructurales: `synack` 29,6 %, `sjit` 25,9 %, `dbytes` 18,9 %.

---

## 9. Pendientes del grupo

- [ ] Leer y **asumir o cambiar** las decisiones marcadas [validar con el grupo]: hipótesis, AF de 3 factores GLS, k = 6, X_cat de 7 variables con terciles, diseño de la logística (70/30 por `attack_cat`, M2).
- [ ] Completar la portada del informe (`informe/main.tex`: `\autores`, `\afiliacion`, `\fechaentrega`).
- [ ] Revisar y reescribir con voz propia la opinión crítica (`% REVISAR GRUPO` en `informe/capitulos/08_integracion.tex` y en `docs/guion_exposicion.md`).
- [ ] Repartir oradores y ensayar la exposición cronometrada (≤ 20 min).
- [ ] Confirmar que la base corregida del 23/10 se reenvió a la profe.
- [ ] Después de completar la portada, recompilar el PDF y controlar que siga en 15 páginas sin anexos (hoy no hay margen: cualquier agregado al cuerpo debe compensarse moviendo material al Anexo A).
- [ ] (Opcional) Discutir la propuesta de sensibilidad del AF: sin `log_spkts` no hay Heywood con ningún estimador (no se aplicó porque X_num está congelado).

---

## 10. Estructura del repositorio

```
R/                 00_datos.R … 06_logistica.R, aux_diagnostico_af.R, ejecutar_todo.R
python/            graficos_etapa0.py, graficos_parte2.py, graficos_logistica.py, verificar_resultados.py
resultados/        tablas/*.csv, figuras/*.png (01–18), *.rds, muestra_particion_70_30.xlsx
informe/           main.tex, capitulos/01–08, anexos/ (A complementos, B código), referencias.bib, main.pdf
docs/              etapa0_pregunta_hipotesis.md, validacion_decisiones.md, logistica_resumen.md,
                   guion_exposicion.md, guia_redaccion_informe.md
Como_ejecutar.txt  orden de ejecución y paquetes
```

Nota: el commit del 23/10 había sacado los documentos del repositorio. El informe LaTeX se incluye ahora dentro (`informe/`) porque su Anexo B lee los scripts directamente de `R/` y `python/`; si el grupo prefiere tenerlo afuera, hay que mantener esa estructura relativa.

---

## 11. Reglas para agentes de IA (y para humanos)

1. **No dar por decidido nada que este archivo no marque como decidido.** Lo marcado [validar con el grupo] es propuesta aplicada, no decisión del grupo.
2. **No modificar la hoja `muestra`.** Si un resultado sugiere cambiar la base o X_num, reportalo y proponé; no lo implementes.
3. **X_num son las 12 de la sección 6.** No volver a las 14.
4. **`set.seed(42)`** al inicio de todo script con algo aleatorio.
5. **Rutas relativas** desde la carpeta principal del repositorio. Nada de `C:/Users/...`.
6. **Un script por etapa**, que corra de punta a punta. Comentarios en español explicando el porqué.
7. **No usar `label`, `attack_cat` ni `tipo_trafico`** para construir ACP, AF ni clusters (solo para colorear o comparar después). `tipo_trafico` sí es variable activa del ACM.
8. **Estandarizar** antes de ACP y clustering.
9. **Salida explicable:** el grupo tiene que poder defender cada línea. Código simple antes que sofisticado.
10. Si algo no cierra (KMO raro, cluster vacío, warning, Heywood), **avisar**. No esconderlo.
11. Los números salen de `resultados/tablas/` de la muestra de 5.000. Si se cita otra fuente, decirlo.
12. **Análisis en R, gráficos en Python** leyendo las tablas de `resultados/tablas`. Sin cifras escritas a mano en los gráficos ni en las tablas de integración.
13. **Informe:** máximo 15 páginas sin anexos; epígrafe debajo de cada gráfico, encima de cada tabla; coma decimal.

---

## 12. Limitaciones a declarar en el informe

- Ataques sintéticos: los resultados describen este laboratorio, no una red real.
- Sin duplicados se analizan perfiles únicos; las proporciones no son prevalencias reales.
- La probabilidad de la logística es relativa a esta base (52 % ataques): interpretar odds ratios, no porcentajes absolutos. Una sola partición 70/30.
- Colinealidad entre protocolo, servicio y estado: OR categóricos inestables.
- Las variables TTL separan por artefacto del laboratorio (excluidas).
- Los `ct_*` usan ventanas de 100 conexiones: los flujos no son estrictamente independientes.
- Con n = 5.000, Bartlett rechaza ante cualquier asociación: pesa más el KMO. Lo mismo el χ² de ajuste del AF.
- Asimetría persistente en log (`log_ct_dst_sport_ltm`, `log_ct_src_dport_ltm`, `log_dur`).
- AF con ajuste global flojo; k = 6 con silhouette casi empatada; terciles como criterio estadístico, no sustantivo.
