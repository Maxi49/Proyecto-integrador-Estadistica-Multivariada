# Regresión logística · resumen (ataque = 1, normal = 0)

Todo sale de `R/06_logistica.R` (tablas `resultados/tablas/log_reg_*.csv`, modelo en `resultados/logistica.rds`) y de las figuras 17 y 18.

## Diseño

- **Partición** estratificada por `label`, `set.seed(42)`: 3.500 flujos de entrenamiento (51,8 % ataques) y 1.500 de prueba (51,9 %). Se parte la muestra de 5.000 porque el testing set original no está en el repositorio y habría que prepararlo igual. Los ids están en `log_reg_particion_ids.csv`.
- **Sin fuga**: el ACP se reajustó solo con el entrenamiento (`prcomp(scale. = TRUE)`) y la prueba se proyectó con `predict()`. Las cargas coinciden con las del ACP de los 5.000 (correlación ≥ 0,999; diferencia máxima 0,015) y ningún signo salió invertido, así que la interpretación de las componentes es la del informe.
- **Predictores**: PC1, PC2, PC3 + `proto_g` (referencia tcp), `service_g` (referencia ninguno) y `state_g` (referencia FIN). Se tomó como referencia la categoría más frecuente de cada una (70,8 %, 60,0 % y 69,3 %), de modo que las demás se comparan con lo "típico". No se usó TTL, `tipo_trafico`, `attack_cat` ni `n_atipicos`.

## Elección del modelo

| Modelo | AIC | Devianza | R² McFadden | AUC prueba |
|---|---|---|---|---|
| M1: 3 puntajes ACP | 3744,1 | 3736,1 | 0,229 | 0,794 |
| M2: M1 + proto + service + state | 2895,9 | 2873,9 | 0,407 | 0,878 |

El test de razón de verosimilitud M1 vs M2 da χ² = 862,2 con 7 gl (p < 0,001). **Se elige M2**: mejora el AIC en unos 850 puntos y el AUC en 0,08. M1 solo no alcanza 0,80.

## Odds ratios del modelo elegido (IC 95 % por verosimilitud perfilada)

| Término | OR | IC 95 % | Lectura |
|---|---|---|---|
| PC1, por desvío del puntaje | 4,68 | 3,82 – 5,77 | Más volumen y temporización y menos repetición de conexiones (`ct_*`): las chances de ataque se multiplican por 4,7 por cada desvío. |
| PC2, por desvío | 0,61 | 0,54 – 0,69 | Más volumen y más repetición a la vez: las chances bajan 39 %. |
| PC3, por desvío | 2,55 | 2,27 – 2,89 | Más temporización (intervalos y jitter) y menos volumen: las chances se multiplican por 2,6. |
| Estado INT vs FIN | 92,7 | 22,6 – 361,8 | Conexión incompleta, con las demás variables fijas. |
| Estado CON_otros vs FIN | 0,05 | 0,02 – 0,13 | Mucho más típico de tráfico normal. |
| Servicio dns vs ninguno | 18,7 | 8,5 – 43,0 | Ver advertencia. |
| Servicio http vs ninguno | 1,88 | 1,47 – 2,42 | Efecto moderado. |
| Protocolo udp / otros vs tcp | 0,42 / 1,13 | IC amplios que incluyen 1 | Sin efecto detectable una vez controlado el estado y el servicio. |

El OR de cada componente se interpreta **por cada desvío del puntaje** (el OR por unidad bruta de puntaje está en `log_reg_or_por_desvio.csv`). Los puntajes de ACP son combinaciones de las 12 variables, no son exactamente los "bloques" volumen / temporización / repetición de H1.

## Desempeño en prueba (umbral 0,5)

AUC = **0,878**, IC 95 % DeLong **0,860 – 0,896**. Exactitud 0,817; sensibilidad 0,910; especificidad 0,717; precisión 0,776; F1 0,838. De 1.500 flujos: 708 ataques detectados, 70 perdidos, 204 normales marcados como ataque y 518 normales bien clasificados. El modelo detecta bien los ataques pero confunde casi 3 de cada 10 flujos normales con ataques.

## H4

**Se confirma**: el AUC en prueba es 0,878 y el límite inferior del IC (0,860) también supera 0,80. Aclaración: la mejora sobre 0,80 viene de agregar protocolo, servicio y estado; con las componentes solas (M1) H4 no se cumpliría (0,794).

## Advertencias

- **Separación**: no hay. Convergió en 6 iteraciones sin avisos, el coeficiente máximo es 4,5 (EE máximo 0,71) y ninguna probabilidad ajustada está a menos de 1e-8 de 0 o 1. Sin embargo, el OR de INT tiene un IC enorme (22,6 – 361,8): es inestable y no debe citarse como "93 veces".
- **Colinealidad entre categóricas**: VIF de `proto_g = udp` ≈ 16,1 y `state_g = INT` ≈ 16,0 (`CON_otros` 8,1, `proto = otros` 7,4). `proto_g = otros` ocurre siempre con servicio ninguno y estado INT, y udp se solapa con INT y dns. Por eso los coeficientes de categorías son condicionales y poco estables, y no se deben leer de a uno. Ejemplo: dns tiene 31 % de ataques en el entrenamiento (menos que ninguno, 49 %), pero su OR ajustado es 18,7; el signo cambia por el control de estado y protocolo. Para las componentes, los VIF son bajos (≤ 3,7).
- **Influencia**: 151 flujos (4,3 %) superan 4/n = 0,0011 en distancia de Cook; el máximo es 0,030 (id 97189), muy lejos de 1. No hay observaciones que dominen el ajuste. No se quitó ninguna.
- **Calibración**: razonable en el centro, pero los deciles altos sobreestiman (decil 10: predicho 0,94, observado 0,86) y el decil 4 subestima (0,38 vs 0,48). Con 150 flujos por decil hay ruido de varios puntos. No se hizo recalibración.

## Limitaciones

- Los ataques son sintéticos (laboratorio IXIA): el desempeño describe este laboratorio, no una red real.
- Sin duplicados y con 52 % de ataques: la probabilidad predicha es relativa a esta base; se interpretan odds ratios, no prevalencias absolutas.
- Se excluyeron las variables TTL por artefacto del laboratorio; con ellas el AUC sería irreal.
- Una sola partición 70/30 de 5.000 flujos: el IC del AUC refleja el muestreo de la prueba, no la variabilidad de la partición. Los `ct_*` usan ventanas de 100 conexiones, así que los flujos no son estrictamente independientes.
- El umbral 0,5 no está optimizado; con la especificidad de 0,72 podría convenir otro según el costo de un falso positivo.
