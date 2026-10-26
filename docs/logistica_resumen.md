# Regresión logística · resumen (ataque = 1, normal = 0)

Todo sale de `R/06_logistica.R` (tablas `resultados/tablas/log_reg_*.csv`, modelo en `resultados/logistica.rds`) y de las figuras 17 y 18.

## Diseño

- **Partición** 70/30 estratificada por `attack_cat` (las 10 categorías con que se armó la muestra), `set.seed(42)`, con round(0,7·n) por categoría al entrenamiento: 3.501 flujos de entrenamiento (51,8 % ataques) y 1.499 de prueba (51,8 %). Cada tipo de tráfico queda en la misma proporción en ambos conjuntos (diferencias < 0,05 puntos porcentuales; Worms: 4 y 2 flujos) y `label` queda balanceado porque es función de `attack_cat`. Se parte la muestra de 5.000 porque el testing set original no está en el repositorio. Ids en `log_reg_particion_ids.csv`, proporciones en `log_reg_particion_attack_cat.csv` y datos completos (68 columnas) en `resultados/muestra_particion_70_30.xlsx`.
- **Cambio respecto de la versión anterior**: la partición se rehízo estratificando por `attack_cat` en lugar de `label`. Antes: AUC 0,878 [0,860–0,896], exactitud 0,817, sensibilidad 0,910, especificidad 0,717. Ahora: AUC 0,882 [0,864–0,900], exactitud 0,818, sensibilidad 0,915, especificidad 0,713. Las diferencias (≤ 0,005) están dentro del ruido de muestreo; la conclusión no cambia.
- **Sin fuga**: el ACP se reajustó solo con el entrenamiento (`prcomp(scale. = TRUE)`) y la prueba se proyectó con `predict()`. Las cargas coinciden con las del ACP de los 5.000 (correlación ≥ 0,999; diferencia máxima 0,016) y ningún signo salió invertido, así que la interpretación de las componentes es la del informe.
- **Predictores**: PC1, PC2, PC3 + `proto_g` (referencia tcp), `service_g` (referencia ninguno) y `state_g` (referencia FIN). Se tomó como referencia la categoría más frecuente de cada una (70,8 %, 60,0 % y 69,3 %), de modo que las demás se comparan con lo "típico". No se usó TTL, `tipo_trafico`, `attack_cat` ni `n_atipicos`.

## Elección del modelo

| Modelo | AIC | Devianza | R² McFadden | AUC prueba |
|---|---|---|---|---|
| M1: 3 puntajes ACP | 3734,2 | 3726,2 | 0,232 | 0,795 |
| M2: M1 + proto + service + state | 2876,5 | 2854,5 | 0,411 | 0,882 |

El test de razón de verosimilitud M1 vs M2 da χ² = 871,7 con 7 gl (p < 0,001). **Se elige M2**: mejora el AIC en unos 860 puntos y el AUC en 0,09. M1 solo no alcanza 0,80.

## Odds ratios del modelo elegido (IC 95 % por verosimilitud perfilada)

| Término | OR | IC 95 % | Lectura |
|---|---|---|---|
| PC1, por desvío del puntaje | 5,01 | 4,11 – 6,15 | Más volumen y temporización y menos repetición de conexiones (`ct_*`): las chances de ataque se multiplican por 5 por cada desvío. |
| PC2, por desvío | 0,59 | 0,53 – 0,67 | Más volumen y más repetición a la vez: las chances bajan 41 %. |
| PC3, por desvío | 2,54 | 2,25 – 2,86 | Más temporización (intervalos y jitter) y menos volumen: las chances se multiplican por 2,5. |
| Estado INT vs FIN | 375,1 | 107,0 – 1.317,7 | Conexión incompleta, con las demás variables fijas. |
| Estado CON_otros vs FIN | 0,19 | 0,08 – 0,44 | Mucho más típico de tráfico normal. |
| Servicio dns vs ninguno | 19,1 | 9,0 – 42,5 | Ver advertencia. |
| Servicio http vs ninguno | 1,88 | 1,47 – 2,41 | Efecto moderado. |
| Protocolo udp vs tcp | 0,14 | 0,04 – 0,49 | Menos chances de ataque, pero muy inestable (ver advertencias). |
| Protocolo otros vs tcp | 0,47 | 0,14 – 1,63 | Incluye 1: sin efecto detectable. |

El OR de cada componente se interpreta **por cada desvío del puntaje** (el OR por unidad bruta de puntaje está en `log_reg_or_por_desvio.csv`). Los puntajes de ACP son combinaciones de las 12 variables, no son exactamente los "bloques" volumen / temporización / repetición de H1.

## Desempeño en prueba (umbral 0,5)

AUC = **0,882**, IC 95 % DeLong **0,864 – 0,900**. Exactitud 0,818; sensibilidad 0,915; especificidad 0,713; precisión 0,775; F1 0,839. De 1.499 flujos: 711 ataques detectados, 66 perdidos, 207 normales marcados como ataque y 515 normales bien clasificados. El modelo detecta bien los ataques pero confunde casi 3 de cada 10 flujos normales con ataques.

## H4

**Se confirma**: el AUC en prueba es 0,882 y el límite inferior del IC (0,864) también supera 0,80. Aclaración: la mejora sobre 0,80 viene de agregar protocolo, servicio y estado; con las componentes solas (M1) H4 no se cumpliría (0,795).

## Advertencias

- **Separación**: no hay. Convergió en 6 iteraciones sin avisos, el coeficiente máximo es 5,9 (EE máximo 0,64) y ninguna probabilidad ajustada está a menos de 1e-8 de 0 o 1. Sin embargo, el OR de INT tiene un IC enorme (107 – 1.318) y cambió de 93 a 375 al rehacer la partición: es inestable y no debe citarse como un valor puntual.
- **Colinealidad entre categóricas**: VIF de `proto_g = udp` ≈ 18,4 y `state_g = INT` ≈ 17,2 (`CON_otros` 8,8, `proto = otros` 7,8). `proto_g = otros` ocurre siempre con servicio ninguno y estado INT, y udp se solapa con INT y dns. Por eso los coeficientes de categorías son condicionales y poco estables, y no se deben leer de a uno. Ejemplo: dns tiene 32 % de ataques en el entrenamiento (menos que ninguno, 49 %), pero su OR ajustado es 19,1; el signo cambia por el control de estado y protocolo. Para las componentes, los VIF son bajos (≤ 3,6).
- **Influencia**: 166 flujos (4,7 %) superan 4/n = 0,0011 en distancia de Cook; el máximo es 0,019 (id 70480), muy lejos de 1. No hay observaciones que dominen el ajuste. No se quitó ninguna.
- **Calibración**: razonable en el centro, pero los deciles altos sobreestiman (decil 10: predicho 0,96, observado 0,84) y el decil 4 subestima (0,40 vs 0,47). Con 150 flujos por decil hay ruido de varios puntos. No se hizo recalibración.

## Limitaciones

- Los ataques son sintéticos (laboratorio IXIA): el desempeño describe este laboratorio, no una red real.
- Sin duplicados y con 52 % de ataques: la probabilidad predicha es relativa a esta base; se interpretan odds ratios, no prevalencias absolutas.
- Se excluyeron las variables TTL por artefacto del laboratorio; con ellas el AUC sería irreal.
- Una sola partición 70/30 de 5.000 flujos (el cambio de estratificación movió el OR de INT de 93 a 375 y el de udp de 0,42 a 0,14): el IC del AUC refleja el muestreo de la prueba, no la variabilidad de la partición. Los `ct_*` usan ventanas de 100 conexiones, así que los flujos no son estrictamente independientes.
- El umbral 0,5 no está optimizado; con la especificidad de 0,72 podría convenir otro según el costo de un falso positivo.
