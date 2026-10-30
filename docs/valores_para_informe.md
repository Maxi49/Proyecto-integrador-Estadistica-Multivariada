# Valores exactos para las correcciones del informe

Generado a partir de `resultados/tablas/` (salida de `Rscript R/ejecutar_todo.R`, semilla 42). Coma decimal. Todos los valores se pueden regenerar corriendo el pipeline.

## (a) Tabla 11 completa: categorías del ACM con contribución mayor que la promedio (100/18 = 5,56 %)

Contribución y coordenada son de la dimensión indicada; cos² es la calidad de representación en el plano (Dim 1 + Dim 2). Se incluye también el cos² de la propia dimensión.

### Dimensión 1 (8 categorías)

| Categoría | Contribución (%) | Coordenada | cos² en la dimensión | cos² en el plano |
|---|---:|---:|---:|---:|
| respuesta_destino = sin_respuesta | 12,28 | 1,65 | 0,63 | 0,90 |
| state_g = INT | 12,25 | 1,68 | 0,63 | 0,90 |
| duracion_banda = corta | 11,91 | 1,22 | 0,75 | 0,75 |
| proto_g = udp | 10,78 | 1,44 | 0,58 | 0,79 |
| bytes_origen_banda = bajos | 8,30 | 1,01 | 0,53 | 0,54 |
| state_g = FIN | 6,52 | -0,63 | 0,89 | 0,90 |
| proto_g = tcp | 6,33 | -0,61 | 0,91 | 0,92 |
| service_g = dns | 6,23 | 1,59 | 0,29 | 0,73 |

### Dimensión 2 (6 categorías)

| Categoría | Contribución (%) | Coordenada | cos² en la dimensión | cos² en el plano |
|---|---:|---:|---:|---:|
| state_g = CON_otros | 24,73 | 2,00 | 0,56 | 0,72 |
| service_g = dns | 19,89 | 1,96 | 0,44 | 0,73 |
| proto_g = otros | 16,90 | -2,16 | 0,36 | 0,57 |
| state_g = INT | 11,19 | -1,11 | 0,27 | 0,90 |
| respuesta_destino = sin_respuesta | 10,81 | -1,07 | 0,27 | 0,90 |
| proto_g = udp | 8,31 | 0,87 | 0,21 | 0,79 |

Total: 8 filas en Dim 1 y 6 en Dim 2 (14 filas; 4 categorías superan el umbral en ambas dimensiones: `service_g = dns`, `state_g = INT`, `proto_g = udp` y `respuesta_destino = sin_respuesta`).

Las que **faltan en la Tabla 11 actual del informe** son: `service_g = dns` en Dim 1 (6,23 %), y `respuesta_destino = sin_respuesta` (10,81 %) y `proto_g = udp` (8,31 %) en Dim 2.

Categorías que superan el umbral en ambas dimensiones:

| Categoría | Contr. Dim 1 (%) | Coord. Dim 1 | Contr. Dim 2 (%) | Coord. Dim 2 | cos² plano |
|---|---:|---:|---:|---:|---:|
| service_g = dns | 6,23 | 1,59 | 19,89 | 1,96 | 0,73 |
| state_g = INT | 12,25 | 1,68 | 11,19 | -1,11 | 0,90 |
| proto_g = udp | 10,78 | 1,44 | 8,31 | 0,87 | 0,79 |
| respuesta_destino = sin_respuesta | 12,28 | 1,65 | 10,81 | -1,07 | 0,90 |

## (b) Autovalores del ACM: inercia cruda e inercia ajustada de Greenacre

Q = 6 variables activas, J = 18 categorías. Inercia total cruda = J/Q − 1 = 2,000. Autovalor medio = 1/Q = 0,1667 (lo superan 4 dimensiones). Inercia total ajustada = 0,4877.

| Dim | Autovalor crudo | % crudo | % crudo acumulado | Autovalor ajustado | % ajustado | % ajustado acumulado |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0,6986 | 34,93 | 34,93 | 0,4074 | 83,54 | 83,54 |
| 2 | 0,3326 | 16,63 | 51,56 | 0,0397 | 8,13 | 91,67 |
| 3 | 0,2244 | 11,22 | 62,78 | 0,0048 | 0,98 | 92,65 |
| 4 | 0,1749 | 8,75 | 71,52 | 0,0001 | 0,02 | 92,67 |
| 5 | 0,1428 | 7,14 | 78,66 | 0,0000 | 0,00 | 92,67 |

Plano 1-2: **51,6 % de la inercia cruda** (34,9 % + 16,6 %) y **91,7 % de la ajustada de Greenacre** (83,5 % + 8,1 %). La corrección aplicada es la de Greenacre (`ca::mjca(lambda = "adjusted")`), no la de Benzécri pura (que daría aprox. 90,1 % y 8,8 %). La tercera dimensión ajustada es 0,98 %; desde la 4.ª es menor que 0,1 %.

Las coordenadas del mapa (fig11) son las principales del ACM estándar (cruda); por eso la figura rotula los ejes con ambos porcentajes.

## (c) Atípicos con bisagras de Tukey (`fivenum`), sobre las 12 variables log(x + 1)

Regla: fuera de [Q1 − 1,5·RIC; Q3 + 1,5·RIC] con Q1 y Q3 = bisagras de Tukey. Límites en la escala log(x + 1) sin estandarizar (el criterio es invariante a la estandarización).

| Variable | Q1 (bisagra) | Q3 (bisagra) | Límite inferior | Límite superior | Atípicos | % de 5.000 |
|---|---:|---:|---:|---:|---:|---:|
| dur | 0,002 | 0,679 | -1,015 | 1,696 | 189 | 3,8 |
| spkts | 1,099 | 3,135 | -1,957 | 6,191 | 19 | 0,4 |
| sbytes | 6,225 | 7,816 | 3,838 | 10,202 | 256 | 5,1 |
| dbytes | 5,187 | 7,999 | 0,970 | 12,216 | 1.056 | 21,1 |
| sinpkt | 0,212 | 4,317 | -5,945 | 10,474 | 33 | 0,7 |
| sjit | 0,000 | 8,345 | -12,517 | 20,862 | 0 | 0,0 |
| synack | 0,000 | 0,061 | -0,092 | 0,153 | 44 | 0,9 |
| ct_srv_src | 0,693 | 1,946 | -1,186 | 3,825 | 10 | 0,2 |
| ct_srv_dst | 0,693 | 1,946 | -1,186 | 3,825 | 10 | 0,2 |
| ct_src_ltm | 0,693 | 1,609 | -0,681 | 2,984 | 127 | 2,5 |
| ct_src_dport_ltm | 0,693 | 0,896 | 0,389 | 1,200 | 581 | 11,6 |
| ct_dst_sport_ltm | 0,693 | 0,693 | 0,693 | 0,693 | 466 | 9,3 |
| **Suma de las 12 (un flujo cuenta varias veces)** | | | | | 2.791 | |

**Flujos con al menos un atípico: 1.715 de 5.000 (34,3 %).** Número de variables atípicas por flujo: 0 → 3.285; 1 → 1.018; 2 → 384; 3 → 259; 4 → 46; 5 → 4; 6 → 4.

Comparación con el cálculo por `quantile` (tipo 7), que es lo que dibujaba la figura anterior: 2.082 flujos (41,6 %) y `ct_src_dport_ltm` 1.250 en vez de 581. En `ct_dst_sport_ltm` Q1 = Q3 (RIC = 0), así que cualquier valor distinto de la moda queda marcado (466): el criterio no discrimina en ese conteo. La fig01 actual usa las bisagras y coincide con estas cifras (el script lo verifica con `stopifnot`).
