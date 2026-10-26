# Validación de decisiones (Etapas 0 a 6)

> Todas las cifras salen de `resultados/tablas/` tras correr `Rscript R/ejecutar_todo.R`. El diagnóstico del AF se reproduce con `Rscript R/aux_diagnostico_af.R`.

## 1. Análisis factorial: caso Heywood y número de factores

**Problema.** Con 4 factores (lo que sugiere el análisis paralelo) `log_spkts` tiene comunalidad 1,029 con minres (unicidad negativa) y 0,995 con ML (unicidad en el límite 0,005). Esto **no depende de 3 vs 4 factores ni de la rotación** (varimax y oblimin dan lo mismo: la rotación no cambia las comunalidades). Pasa con minres, pa, ML, wls y uls. La causa: `log_spkts` casi se reproduce con el factor Volumen (r = 0,86 con `log_sbytes` y 0,80 con `log_dbytes`) y ese factor tiene solo 3 indicadores, el caso clásico de Heywood.

| Solución | Heywood | RMSR | TLI | RMSEA | % var. | Interpretación |
|---|---|---|---|---|---|---|
| 3 f. minres | Sí (1,025) | 0,045 | 0,687 | 0,214 | 67,4 | 3 bloques de H1 |
| 3 f. pa | Sí (1,095) | 0,045 | 0,684 | 0,215 | 67,7 | 3 bloques de H1 |
| 3 f. ML | Sí (límite, 0,995) | 0,059 | 0,716 | 0,204 | 67,0 | 3 bloques de H1 |
| **3 f. GLS** | **No (máx. 0,897; unicidad mín. 0,103)** | 0,051 | 0,609 | 0,239 | 68,6 | **3 bloques de H1** |
| 4 f. minres | Sí (1,029) | 0,026 | 0,777 | 0,180 | 73,0 | divide ct_* en dos |
| 4 f. ML | Sí (límite) | 0,033 | 0,793 | 0,174 | 73,6 | divide ct_* en dos |
| 4 f. GLS | Sí (1,011) | 0,028 | 0,778 | 0,180 | 73,6 | divide ct_* en dos |

En todas las soluciones hay 0 variables sin carga ≥ 0,40 y 0 cargas cruzadas ambiguas (diferencia < 0,20).

**¿Es sustantivo el 4.º factor?** Poco:
- Autovalor factorial observado 0,127 (simulado 0,036): supera al azar solo porque n = 5.000 hace que el análisis paralelo detecte casi cualquier cosa. Está lejos de 1.
- Kaiser sobre la matriz reducida (diagonal = SMC): 4,93 · 1,78 · 1,44 · **0,43** → 3 factores. El 4.º aporta 4,8 % de la varianza común. El ACP (Kaiser y codo) también da 3.
- Solo parte el bloque `ct_*` en dos: `ct_srv_*` (servicio) con 2 variables fuertes, y `ct_*_dport/sport` (puertos). Con oblimin esos dos factores correlacionan 0,62, es decir, miden casi lo mismo. Un factor con 2 indicadores es síntoma de sobreextracción.

**Decisión: 3 factores, estimador GLS, varimax.** Es la única combinación probada de 3 o 4 factores sin Heywood (cambiar de estimador es un remedio estándar y no obliga a sacar una variable de X_num). Explica 68,6 % de la varianza total (F1 25,1 · F2 22,4 · F3 21,1), comunalidad mínima 0,356 (`log_ct_src_ltm`), todas las unicidades ≥ 0,103. Cada variable carga ≥ 0,54 en un solo factor:
- **F1 Repetición de conexiones** (5 `ct_*`, cargas 0,54 a 0,91).
- **F2 Temporización** (`dur`, `sinpkt`, `sjit`, `synack`, 0,68 a 0,87).
- **F3 Volumen** (`spkts`, `sbytes`, `dbytes`, 0,79 a 0,91).

Coincide con H1 y con los bloques del cluster de variables (ARI = 1,000).

**Qué decir con honestidad ante la docente:**
1. El análisis paralelo sugiere 4 y nos apartamos, con los motivos de arriba. El gráfico (figura 09) muestra ambos cortes.
2. Con 4 factores el ajuste es mejor (RMSR 0,033 vs 0,051; TLI 0,79 vs 0,61). Es el costo de la parsimonia. El ajuste exacto se rechaza en todas las soluciones (χ² p < 0,001, normal con n = 5.000) y el RMSEA es alto (0,17 a 0,24): el modelo es descriptivo, no confirmatorio.
3. GLS estima la comunalidad de `log_spkts` en 0,87; los demás estimadores la llevan a 1 o más. Debe leerse como "casi toda su varianza es Volumen". No cambia ni cargas ni nombres.
4. Sensibilidad (solo informativa, X_num no se toca): sin `log_spkts`, 3 factores no tienen Heywood con ningún estimador. Es propuesta a discutir en el grupo, no se implementó (regla 3).

## 2. Cortes del ACM (7 variables)

- **Terciles de `dur` (0,0185 s y 0,709 s) y `sbytes` (564 y 1.580 bytes).** Ambas variables son muy asimétricas (`dur`: mediana 0,30 s, p99 32 s; 26 flujos con `dur` = 0). Cortes de igual amplitud dejarían casi todo en una categoría y la ACM se dominaría por modalidades raras. Los terciles dan categorías de 33 % (todas ≥ 5 %) y no usan la etiqueta de ataque, así que no hay fuga. Sustantivamente: 18 ms es del orden de un intercambio mínimo en una red de laboratorio; 1.580 bytes está cerca del MTU de Ethernet (1.500), o sea "altos" ≈ más de un paquete lleno. **Es una lectura a posteriori; el criterio principal es estadístico (igual frecuencia).** Alternativa con sentido (< 0,01 s / < 1 s; ≤ 200 / 1.500 bytes) da categorías de 31/45/24 % y 21/43/36 %: también válida, no mejor.
- **`respuesta_destino`** (`dpkts` = 0, 18,9 %): corte natural, no hay que elegir un umbral. Es "sin respuesta del destino", sustantivo para H3.
- Conviene saber: `duracion_banda` y `bytes_origen_banda` se asocian a `tipo_trafico` (V de duración con tipo = 0,26), así que no son ruido.

## 3. Par del ACS: tipo_trafico × state_g

V de Cramér: state_g 0,405 > service_g 0,320 > proto_g 0,302. `state_g` es la variable que mejor encarna H3 (INT = conexión incompleta). La tabla 5 × 3 tiene frecuencia esperada mínima 43 (supuesto del χ² sobrado) y dos dimensiones capturan el 100 % de la inercia (77,9 % + 22,1 %), por lo que el mapa no pierde información. `respuesta_destino` daría 1 sola dimensión (solo 2 columnas). Cuidado al interpretar: `state_g` está ligado a `proto_g` (FIN solo ocurre en TCP; INT incluye todo `otros`).

## 4. Número de clusters: k = 6

- Silhouette k-means: k = 2: 0,328 · 3: 0,302 · 4: 0,327 · 5: 0,329 · **6: 0,333** · 7: 0,277 · 8: 0,284. Entre k = 2, 4, 5 y 6 las diferencias son < 0,007 (k = 3 queda más abajo, 0,302): son empates prácticos, y todas están por debajo de 0,5 (estructura de grupos débil). Lo que sí es claro es la caída en k = 7.
- Codo (WSS k-means): las ganancias son 7.496 (2→3), 6.722 (3→4), 3.046 (4→5), 2.054 (5→6), 1.858 (6→7). **El codo más marcado está en k = 4**, no en 6.
- Interpretabilidad de k = 6: cluster 1 (898) es 98,6 % Normal y 1,4 % ataque; cluster 3 (147 flujos, 2,9 %) es 100 % ataque, 88 % Generic, con `ct_dst_sport_ltm` +5,1 desvíos: es un grupo chico pero sustantivo (ráfagas repetidas), no un artefacto. ARI Ward vs k-means = 0,813. Con otras semillas k = 6 da tamaños casi iguales (141 a 2.140), es estable.
- **Veredicto: defendible, no indefendible; no se cambió.** Se elige por silhouette máxima y se reconoce que k = 4 también es defendible (codo, silhouette 0,327). Debilidad a declarar: los clusters 2 y 6 tienen silhouette media baja (0,06 y 0,12) y 36 % y 27 % de sus flujos con silhouette negativa: están mal separados.

## 5. Otros problemas encontrados

1. **Cifras a mano**: `05_integracion.R` ya las calcula desde las tablas. Siguen escritas a mano en `python/graficos_parte2.py` los rótulos del biplot ("CP1 (43,29%)", "CP2 (16,88%)") y los textos cualitativos de las filas ACP, ACS y ACM de `integracion_tecnicas`; no se tocaron pero hay que revisarlos si cambia la base.
2. **H2 se cumple solo en parte**: el cluster 3 aísla casi solo ataques Generic (no "no distingue tipos de ataque"). Reportarlo en el informe.
3. **ACM**: el 87,4 % es inercia **ajustada** (Greenacre), que es optimista; la inercia cruda de las dos primeras dimensiones es 41,4 %. Aclararlo siempre junto al número.
4. `verificar_resultados.py` tenía el corte de `sbytes` (564 y 1.580) escrito a mano; ahora lo lee de `cortes_discretizacion.csv`.
5. Cambio de formato en las salidas del AF: ahora hay F1 a F3 en vez de F1 a F4, y `af_puntajes.csv` tiene `Factor1` a `Factor3`.
