# Guion de la exposición oral · UNSW-NB15 · Estadística Multivariada (UCC)

> Máximo 20 minutos. Este guion suma **18:45** (1:15 de margen). 15 diapositivas, 4 oradores.
> Todas las cifras salen de los capítulos del informe o de `resultados/tablas/*.csv` (si difieren, manda el CSV).
> Los OR de PC1, PC2 y PC3 son **por desvío del puntaje** (el CSV `log_reg_coeficientes.csv` trae también el OR por unidad bruta: 2,03; 0,70; 2,03). Decirlo siempre así.
>
> **Cómo se calcularon los tiempos.** Cada guion tiene 80 a 150 palabras (≈ 55 a 70 s hablado a ritmo normal). El resto del tiempo de cada diapositiva es para **señalar la figura** (marcado con `[pausa]`) y respirar. Si al ensayar sobran más de 90 s, sacar la última frase de las diapositivas 3, 7 y 9 (están marcadas con «recortable»).

## 1. Plan de tiempos y oradores

| N.º | Diapositiva (título) | Orador | Min |
|---|---|---|---|
| 1 | Cinco técnicas, una pregunta: ¿qué distingue un ataque del tráfico normal? | Integrante 1 | 0:45 |
| 2 | Cada fila es una conversación de red y las variables no se mueven solas | Integrante 1 | 1:00 |
| 3 | Con log(x+1) y 12 variables, los supuestos se cumplen | Integrante 1 | 1:30 |
| 4 | Tres componentes resumen el 74,5 %: tamaño del flujo frente a repetición | Integrante 1 | 1:30 |
| 5 | Tres factores limpios, pero hubo que esquivar un caso Heywood | Integrante 2 | 1:45 |
| 6 | El ACP resume, el AF interpreta: para esta pregunta, el AF | Integrante 2 | 1:00 |
| 7 | Seis grupos útiles, pero no categorías naturales | Integrante 2 | 1:45 |
| 8 | Cluster de variables y AF dan exactamente los mismos tres bloques | Integrante 3 | 1:00 |
| 9 | El estado de la conexión organiza el mapa de categorías | Integrante 3 | 1:45 |
| 10 | Con estado, servicio y protocolo, el AUC pasa de 0,795 a 0,882 | Integrante 3 | 1:45 |
| 11 | Cinco técnicas cuentan la misma historia, con matices | Integrante 4 | 1:15 |
| 12 | H1 y H4 se confirman; H2 y H3, solo en parte | Integrante 4 | 1:15 |
| 13 | Lo que estos datos no nos dejan decir | Integrante 4 | 0:45 |
| 14 | Nuestra opinión: lo sólido es la estructura, lo frágil son los grupos y los OR | Integrante 4 | 1:15 |
| 15 | Respuesta a la pregunta guía y cierre | Integrante 4 | 0:30 |
| | **Total** | | **18:45** |

Bloques por orador: Integrante 1 = 4:45 (diap. 1 a 4) · Integrante 2 = 4:30 (5 a 7) · Integrante 3 = 4:30 (8 a 10) · Integrante 4 = 5:00 (11 a 15).

**Reglas de la sala.** Quien habla cambia la diapositiva. Quien no habla no mira el celular ni el reloj: el cronometrista es [Integrante 4], con el reloj a la vista, y avisa con un gesto a los 5, 10 y 15 minutos (marcas esperadas: diap. 5 a los 4:45, diap. 8 a los 9:15, diap. 11 a los 13:45).

---

## 2. Diapositivas

### Diapositiva 1 · Cinco técnicas, una pregunta: ¿qué distingue un ataque del tráfico normal? (0:45 · Integrante 1)

**En pantalla**
- Pregunta guía (abreviada): ¿qué patrones de volumen, temporización y repetición de conexiones caracterizan a los flujos de UNSW-NB15 y cuánto distinguen ataque de normal?
- H1 tres bloques de variables · H2 grupos por forma de conexión · H3 ataque ~ conexión incompleta · H4 AUC > 0,80
- Título, materia, UCC Río Cuarto, integrantes.

**Dato grande:** 5.000 flujos · 12 variables numéricas + 7 categóricas.
**Figura:** ninguna del repo. Gráfico simple nuevo: una línea con cinco cajitas (ACP, AF, Cluster, ACM, Logística) que desembocan en la pregunta.

**Guion**
> Buenas tardes. Somos [nombre del grupo] y les vamos a contar qué encontramos al aplicar las técnicas de la materia sobre una base de tráfico de red, UNSW-NB15. Nuestra pregunta guía es qué patrones de volumen, temporización y repetición de conexiones caracterizan a los flujos de red, y en qué medida esos patrones, junto con el protocolo, el servicio y el estado de la conexión, distinguen el tráfico normal del de ataque, al punto de poder estimar la probabilidad de que un flujo sea un ataque. Partimos de cuatro hipótesis, que ven en pantalla. Una aclaración de honestidad: cuando las fijamos ya habíamos explorado los datos, así que las tratamos como hipótesis de partida y las contrastamos al final, incluidas las que fallan.

**Transición:** «Empiezo por la base.» (mismo orador)

---

### Diapositiva 2 · Cada fila es una conversación de red y las variables no se mueven solas (1:00 · Integrante 1)

**En pantalla**
- UNSW-NB15 (Moustafa y Slay, UNSW Canberra): tráfico normal realista + 9 tipos de ataque **sintéticos**
- Muestra: 5.000 flujos únicos de 175.341, estratificada por `attack_cat`
- 48,2 % normal · 51,8 % ataque (sin duplicados: eran 38,6 % del original)
- Multivariada: muchas numéricas correlacionadas + categóricas + etiqueta externa

**Dato grande:** 48,2 % / 51,8 %.
**Figura:** gráfico simple nuevo: barra horizontal apilada con Normal 48,2 · Exploits 18,4 · Fuzzers 15,0 · Reconnaissance 7,0 · Otros ataques 11,5 (los porcentajes de ataque suman 51,9 por redondeo; el total real es 51,8).

**Guion**
> La base la armaron Moustafa y Slay en el laboratorio de UNSW Canberra. Cada fila es un flujo, una conversación entre un origen y un destino, descrita por variables de volumen, de tiempo, de conexión y de contexto. El tráfico normal es realista, pero los ataques son sintéticos, y eso lo vamos a tener presente todo el tiempo. Del archivo de entrenamiento, que tiene 175.341 flujos, tomamos 5.000 únicos, estratificados por tipo de ataque: 48,2 % normales y 51,8 % ataques. Quitamos los duplicados, que eran el 38,6 % del original, así que esas proporciones no son prevalencias de una red real. Es una base típicamente multivariada: muchas numéricas correlacionadas, varias categóricas y una etiqueta externa, normal o ataque, que usamos solo para contrastar, nunca para construir componentes, factores ni grupos.

**Transición:** «Veamos cómo preparamos esas variables.» (mismo orador)

---

### Diapositiva 3 · Con log(x+1) y 12 variables, los supuestos se cumplen (1:30 · Integrante 1)

**En pantalla**
- log(x+1): la asimetría de `sbytes` baja de 33,3 a 1,0
- 14 candidatas → 12: se sacaron `dpkts` (r = 0,95 con `dbytes`) y `rate` (r = −0,91 con `sinpkt`)
- Determinante 6,3×10⁻⁵ · KMO 0,748 · MSA mínima 0,621 · Bartlett p < 0,001
- Atípicos: 34,3 % de los flujos con alguno; **se conservan**

**Dato grande:** KMO 0,748.
**Figura:** `07_datos_resumen.png` (histograma crudo frente a log, boxplots de volumen y mapa de correlaciones con los tres bloques). Alternativa si se quiere solo el mapa: `04_correlaciones.png`.

**Guion**
> Las variables son positivas, muy asimétricas y con rangos enormes, así que aplicamos log de x más uno, que conserva los ceros: la asimetría de `sbytes` baja de 33 a 1. Trabajamos con 12 variables numéricas. Teníamos 14 candidatas, pero `dpkts` es casi igual a `dbytes` y `rate` es casi el opuesto de `sinpkt`; con las dos adentro el determinante daba 10 a la menos 7, y sacando solo `dpkts` seguía por debajo de 10 a la menos 5. Sacando ambas queda en 6,3 por 10 a la menos 5, KMO de 0,748 y MSA mínima de 0,62. [pausa: señalar el mapa de correlaciones] Ya acá se ven tres zonas: volumen, temporización y repetición, esta última con correlaciones negativas con el resto. Los atípicos, un 34 %, los conservamos: en ciberseguridad lo extremo puede ser justamente el fenómeno de interés. *(recortable: última oración)*

**Transición:** «Con esto corremos el ACP.» (mismo orador)

---

### Diapositiva 4 · Tres componentes resumen el 74,5 %: tamaño del flujo frente a repetición (1:30 · Integrante 1)

**En pantalla**
- Se estandariza: varianzas de 0,002 a 13,61; sin estandarizar CP1 = 66,4 %, estandarizado 43,3 %
- Autovalores 5,20 · 2,03 · 1,72 · (4.º: 0,76) → 3 componentes (Kaiser + codo)
- CP1: tamaño y ritmo **frente a** repetición · CP2: volumen · CP3: ritmo lento
- Extremos: 127446, 125215, 136451 (UDP/DNS, INT, 2 paquetes, 114 bytes)

**Dato grande:** 74,5 % acumulado con 3 componentes.
**Figura:** `08_acp_codo_biplot.png` (codo y biplot CP1–CP2 con los tres flujos rotulados).

**Guion**
> Estandarizamos porque las varianzas van de 0,002 a casi 14, y tres variables reúnen el 83 % de la varianza total: sin estandarizar, la primera componente captaría el 66 % y estaríamos mirando escalas, no relaciones. Estandarizado, los autovalores son 5,2; 2,0 y 1,7, y el cuarto cae a 0,76: Kaiser y el codo coinciden en tres componentes, con 74,5 % acumulado. [pausa: señalar el codo y las flechas del biplot] CP1 opone el tamaño y el ritmo del flujo a la repetición de conexiones. CP2 es volumen y CP3, ritmo lento. Los tres flujos extremos son UDP al servicio DNS, de dos paquetes y 114 bytes, sin respuesta, con mucha repetición. No son errores: 152 flujos de la muestra tienen ese patrón y todos son ataques. Pero fijense que en el biplot los tipos de tráfico se solapan.

**Transición:** «Le paso a [Integrante 2], que sigue con los factores.»

---

### Diapositiva 5 · Tres factores limpios, pero hubo que esquivar un caso Heywood (1:45 · Integrante 2)

**En pantalla**
- Paralelo sugiere 4 (4.º autovalor 0,127 vs 0,036 simulado); Kaiser reducido: 4,93 · 1,78 · 1,44 · **0,43** → 3
- Con 4 factores, `ct_*` se parte en dos que correlacionan 0,62
- Heywood: `log_spkts` con comunalidad 1,025 (minres), 1,095 (pa); GLS: máx. 0,897
- F1 Repetición 25,1 % · F2 Temporización 22,4 % · F3 Volumen 21,1 % = **68,6 %**
- Ajuste flojo: TLI 0,609 · RMSEA 0,239 → uso descriptivo

**Dato grande:** 68,6 % con 3 factores (GLS, varimax).
**Figura:** `09_af_paralelo.png` (muestra los dos cortes: 3 y 4). Gráfico simple nuevo: tres cajas F1, F2, F3 con las variables y su rango de cargas (F1: 0,54 a 0,91; F2: 0,68 a 0,87; F3: 0,79 a 0,91).

**Guion**
> En el análisis factorial los supuestos ya estaban verificados, así que no sacamos ninguna variable. El análisis paralelo sugería cuatro factores, pero el cuarto autovalor es 0,127 contra 0,036 simulado: supera al azar sobre todo porque con 5.000 flujos casi cualquier cosa lo supera. Con Kaiser sobre la matriz reducida el cuarto vale 0,43, y con cuatro factores el bloque de repetición se parte en dos que correlacionan 0,62, síntoma de sobreextracción. Nos quedamos con tres. Segundo problema: un caso Heywood. `log_spkts` pasa de comunalidad 1 con varios estimadores, y rotar no lo arregla. La única combinación sin solución impropia fue tres factores con GLS. [pausa: mostrar las cajas] Salen Repetición, Temporización y Volumen, con cargas de 0,54 a 0,91, sin cargas cruzadas, y 68,6 % de la varianza. El ajuste global es flojo, así que lo usamos de forma descriptiva.

**Transición:** (mismo orador) «¿Y esto en qué se diferencia del ACP?»

---

### Diapositiva 6 · El ACP resume, el AF interpreta: para esta pregunta, el AF (1:00 · Integrante 2)

**En pantalla** (tabla de 4 filas, dos columnas)
- Varianza: total (ACP) vs. común (AF)
- Retenido: 3 comp., 74,5 % vs. 3 factores, 68,6 %
- Ejes: combinaciones mixtas vs. bloques
- Uso en el proyecto: ACP → predictor de la logística; AF → leer los bloques de H1

**Dato grande:** 74,5 % frente a 68,6 %.
**Figura:** tabla simple nueva (la Tabla ACP vs AF del capítulo 4, con letra grande y solo esas 4 filas).

**Guion**
> La diferencia de fondo es qué varianza usa cada técnica. El ACP trabaja con la varianza total y retiene 74,5 %; el AF separa la unicidad y trabaja con la varianza común: retiene 68,6 % de la total. Pero lo que cambia no es el ajuste, es la interpretación. En el ACP cada eje mezcla tiempo, volumen y repetición, y hay que leer contrastes; en el AF los tres ejes son exactamente los tres bloques de H1. Por eso, para esta base y esta pregunta, el AF es más adecuado. Eso sí, no tiramos el ACP: da puntajes exactos, sin soluciones impropias, y lo usamos como predictor en la regresión logística. Resumir y entender son dos tareas distintas, y cada técnica gana en una.

**Transición:** «Ahora, en vez de variables, agrupamos observaciones.» (mismo orador)

---

### Diapositiva 7 · Seis grupos útiles, pero no categorías naturales (1:45 · Integrante 2)

**En pantalla**
- Silhouette k-means: 0,333 en k = 6; k = 2, 4, 5: 0,327 a 0,329; k = 3: 0,302; k = 7: 0,277 (todo < 0,5)
- Codo más marcado en k = 4; elegimos k = 6 y lo declaramos
- C1 898 flujos «transferencias voluminosas»: 1,4 % ataque · C3 147 «ráfagas repetidas sin respuesta»: 100 % ataque · C4 2.131: 71,0 % · C5 1.135: 46,3 % · C2 405: 72,6 % · C6 284: 34,9 %
- C2 y C6 mal separados (silhouette 0,063 y 0,119)

**Dato grande:** silhouette 0,333, con estructura débil.
**Figura:** `10_cluster_seleccion.png` (codo y silhouette) a la izquierda; a la derecha una tabla simple nueva con los 6 clusters (nombre, n, % ataque). De respaldo, `12_cluster_perfiles_variables.png` (panel izquierdo, mapa de calor de perfiles).

**Guion**
> Hicimos Ward sobre las 12 variables estandarizadas y k-means con 25 inicios. Elegir k fue lo más discutible. El silhouette de k-means es máximo en k igual 6, con 0,333, pero k igual 2, 4 y 5 dan entre 0,327 y 0,329, prácticamente empatados, y todos están por debajo de 0,5: la estructura de grupos es débil. El codo más marcado está en k igual 4. Elegimos 6 por el silhouette y porque aparece un grupo chico y muy definido, que con 4 se perdería. [pausa: señalar la tabla] El cluster 1, transferencias voluminosas, es 98,6 % normal. El 3, de 147 flujos, son ráfagas repetidas sin respuesta y es 100 % ataque, casi todos Generic. Los otros cuatro mezclan entre 35 y 73 % de ataques, y el 2 y el 6 están mal separados. Leemos los grupos como una descripción útil, no como categorías naturales. *(recortable: última oración)*

**Transición:** «Le paso a [Integrante 3].»

---

### Diapositiva 8 · Cluster de variables y AF dan exactamente los mismos tres bloques (1:00 · Integrante 3)

**En pantalla**
- Ward sobre variables: tres bloques (temporización, volumen, repetición)
- ARI cluster de variables vs. factores del AF = **1,000**
- El ACP mezcla volumen y temporización en CP1
- Clusters vs. dimensiones: CP1 η² = 0,86; F2 0,78, F3 0,73, F1 0,72 (cluster 3: F1 = +3,78)

**Dato grande:** ARI = 1,000.
**Figura:** `12_cluster_perfiles_variables.png`, panel derecho (dendrograma Ward de variables); recortar el panel o resaltarlo.

**Guion**
> Además de agrupar flujos, agrupamos variables: Ward sobre las columnas estandarizadas. [pausa: señalar el dendrograma] El dendrograma separa tres bloques, temporización, volumen y repetición, con las cinco `ct_*` juntas. Y coinciden exactamente con los tres factores del AF: el índice de Rand ajustado es 1,000. Eso sostiene H1. El ACP, en cambio, pide tres ejes pero no los entrega puros. Y a la pregunta de si los clusters de flujos se explican por las dimensiones: sí, CP1 explica el 86 % de la variabilidad entre clusters y los tres factores entre 72 y 78 %. Ojo, es en parte circular, porque agrupamos con las mismas variables; por eso después miramos las categorías del ACM, que no participaron.

**Transición:** (mismo orador) «Pasemos a las variables categóricas.»

---

### Diapositiva 9 · El estado de la conexión organiza el mapa de categorías (1:45 · Integrante 3)

**En pantalla**
- ACS tipo × estado: V de Cramér 0,405 (servicio 0,320, protocolo 0,302); 2 dimensiones = 100 % de la inercia
- INT: 62,3 % de «Otros ataques» frente a 5,9 % de Normal; Exploits: 90,4 % en FIN
- ACM (7 variables, 23 categorías): plano = **41,4 % crudo** (87,4 % ajustado, optimista)
- Dim 1: «conexión efímera sin respuesta» (INT, UDP, corta) frente a «sesión TCP completa» (FIN, TCP); η² estado 0,909
- Cluster 3 (suplementario): Dim 1 = 2,16, 100 % INT y sin respuesta

**Dato grande:** 41,4 % crudo / 87,4 % ajustado (siempre juntos).
**Figura:** `15_acm_categorias.png` (mapa de categorías). Respaldo: `13_acs_mapa.png`, `16_acm_clusters_eta.png`.

**Guion**
> Primero un análisis de correspondencias simple entre tipo de tráfico y estado, porque el estado es la variable más asociada al tipo: V de Cramér de 0,405. El estado INT, conexión incompleta, concentra el 62 % de «otros ataques» y solo el 6 % de lo normal; Exploits, en cambio, es 90 % FIN. Después, el ACM con siete variables, tres de ellas discretizadas. El plano de dos dimensiones reúne 41,4 % de inercia cruda, y 87,4 % ajustada con Greenacre, que es optimista; por eso damos siempre los dos números. [pausa: señalar el mapa, izquierda y derecha] La Dim 1 opone la conexión efímera, sin respuesta, UDP y corta, a la sesión TCP completa. El cluster 3, que no intervino en el ACM, cae aislado a la derecha: 100 % INT y sin respuesta. Es descriptivo, no causal. *(recortable: última oración)*

**Transición:** (mismo orador) «Y ahora, ¿se puede estimar la probabilidad de ataque?»

---

### Diapositiva 10 · Con estado, servicio y protocolo, el AUC pasa de 0,795 a 0,882 (1:45 · Integrante 3)

**En pantalla**
- Partición 70/30 estratificada por `attack_cat`: 3.501 entrenamiento / 1.499 prueba; ACP reajustado solo con entrenamiento
- Sin TTL, sin `tipo_trafico`, sin `attack_cat`
- M1 (3 puntajes): AUC 0,795 · M2 (+ proto, service, state): **AUC 0,882** (IC 95 % 0,864 a 0,900)
- Sensibilidad 0,915 · especificidad 0,713 · 207 normales marcados como ataque (28,7 %), 66 ataques perdidos (8,5 %)
- OR por desvío: PC1 5,01 · PC3 2,54 · PC2 0,59. Estado INT vs FIN: 375 (IC 107 a 1.318) → **inestable**

**Dato grande:** AUC = 0,882.
**Figura:** `17_logistica_roc_confusion.png`. Respaldo: `18_logistica_or_calibracion.png` (forest plot de OR y calibración).

**Guion**
> Partimos la muestra 70/30, estratificada por tipo de ataque, y reajustamos el ACP solo con entrenamiento para no filtrar información. Excluimos TTL, que es un artefacto del laboratorio y daría un AUC irreal, y cualquier variable que contenga la etiqueta. Con solo los puntajes del ACP, el AUC en prueba es 0,795: H4 no se cumpliría. Agregando protocolo, servicio y estado sube a 0,882, con un intervalo de 0,864 a 0,900. [pausa: señalar la matriz de confusión] Detecta el 91,5 % de los ataques, pero marca como ataque casi 3 de cada 10 flujos normales. Los odds ratios de las componentes son estables: un desvío más de PC1 multiplica las chances por 5. Los de las categóricas no: el de INT, 375, tiene un intervalo de 107 a 1.318 y cambió de 93 a 375 al rehacer la partición. Sirve para la dirección, no como valor puntual.

**Transición:** «Le paso a [Integrante 4], que integra todo.»

---

### Diapositiva 11 · Cinco técnicas cuentan la misma historia, con matices (1:15 · Integrante 4)

**En pantalla** (tabla, una fila por técnica; letra grande, 1 línea por celda)
- ACP: 3 comp. (74,5 %), ejes mixtos · AF: 3 factores (68,6 %), = cluster de variables (ARI 1,000)
- Cluster de observaciones: 6 grupos, silhouette 0,333; C3 aislado
- ACS/ACM: Dim 1 = INT, sin respuesta, UDP frente a FIN, TCP; plano 41,4 % crudo
- Logística: AUC 0,882; PC1, estado INT, CON_otros, dns

**Dato grande:** una sola oposición, «conexión repetitiva, breve y sin respuesta» frente a «sesión completa», que reaparece en CP1, F1, cluster 3, Dim 1 del ACM y PC1 de la logística.
**Figura:** tabla de integración (Tabla del capítulo 8, abreviada a 5 filas y 3 columnas: estructura, protagonistas, coincide/discrepa). Es el entregable de la Etapa 6a.

**Guion**
> Esta es la tabla de integración, una fila por técnica. Si se la mira de lejos, aparece una misma oposición en todas: conexiones breves, repetidas y sin respuesta, frente a sesiones completas. Está en CP1 del ACP, en el factor de repetición del AF, en el cluster 3, en la Dim 1 del ACM y en PC1 y el estado INT de la logística. Los matices: el ACP y el AF coinciden en aislar la repetición, pero solo el AF y el cluster de variables dan los tres bloques puros. El ACM y la logística coinciden en INT y CON_otros, pero el servicio dns cambia de signo al ajustar, y eso lo vamos a ver como advertencia sobre leer coeficientes de a uno.

**Transición:** (mismo orador) «¿Qué pasó entonces con las hipótesis?»

---

### Diapositiva 12 · H1 y H4 se confirman; H2 y H3, solo en parte (1:15 · Integrante 4)

**En pantalla**
- H1 **confirmada**: AF = cluster de variables (ARI 1,000), cargas ≥ 0,54; el ACP no las separa
- H2 **parcial**: C1 98,6 % normal y C3 100 % ataque; los otros cuatro, 34,9 a 72,6 %; y C3 sí distingue un tipo (130 de 147 = Generic)
- H3 **parcial**: INT y sin respuesta con «Otros ataques» (62,3 % y 63,2 % vs 5,9 % y 6,9 % de Normal); Exploits es casi todo FIN
- H4 **confirmada**: AUC 0,882, límite inferior 0,864 > 0,80 (con M1 solo, no)
- Sorpresa: repetición alta en C3 (100 % ataque) y C6 (34,9 %); INT = sin respuesta (913 de 913)

**Dato grande:** 2 confirmadas, 2 parciales.
**Figura:** gráfico simple nuevo: cuatro filas H1 a H4 con semáforo (verde, amarillo, amarillo, verde) y la cifra clave de cada una.

**Guion**
> Resumimos los veredictos. H1, los tres bloques, se confirma: AF y cluster de variables coinciden exactamente. H2 se cumple en parte: hay un cluster casi puro de normales y otro puro de ataques, pero los otros cuatro mezclan, y además falla la parte que decía que los grupos no distinguen tipos de ataque: el cluster 3 es casi todo Generic. H3 también en parte: INT y la falta de respuesta se asocian con ataques, pero solo con «otros ataques», Fuzzers y Reconnaissance, porque Exploits es casi todo FIN con respuesta. H4 se confirma, con la aclaración de que depende de agregar las categóricas. Y entre las sorpresas: la repetición, por sí sola, no distingue ataques, porque los clusters 3 y 6 la tienen alta, pero uno es 100 % ataque y el otro 35 %.

**Transición:** (mismo orador) «Ahora, lo que no podemos afirmar.»

---

### Diapositiva 13 · Lo que estos datos no nos dejan decir (0:45 · Integrante 4)

**En pantalla**
- Ataques sintéticos; sin duplicados: las proporciones no son prevalencias (52 % de ataques)
- Los `ct_*` usan ventanas de 100 conexiones: los flujos no son independientes
- Terciles del ACM: criterio estadístico; k = 6 empata en silhouette
- Una sola partición 70/30; TTL excluidas; datos observacionales
- AF con ajuste flojo (TLI 0,609); persiste asimetría en `log_dur` (2,8)

**Dato grande:** ninguno (diapositiva de texto, 5 líneas máximo).
**Figura:** ninguna.

**Guion**
> Las limitaciones. Los ataques son sintéticos y no hay duplicados, así que el 52 % de ataques no representa una red real y la probabilidad de la logística es relativa a esta base. Las variables `ct_*` se calculan sobre ventanas de 100 conexiones, así que los flujos no son estrictamente independientes. Los terciles del ACM son un criterio estadístico, no sustantivo. Usamos una sola partición 70/30, y vimos que los odds ratios categóricos se mueven con ella. El ajuste global del AF es flojo. Y los datos son observacionales: describimos asociaciones, no causas.

**Transición:** (mismo orador) «Y ahora, lo que opinamos.»

---

### Diapositiva 14 · Nuestra opinión: lo sólido es la estructura, lo frágil son los grupos y los OR (1:15 · Integrante 4)

> **REVISAR GRUPO:** juicios propuestos en el borrador; deben ser opiniones que todo el grupo defienda (ver sección 3).

**En pantalla**
- Sólido: tres bloques recuperados por tres técnicas (AF, cluster de variables y ACP en número)
- Frágil: lectura de los 6 grupos y los OR categóricos aislados
- Lo que más aporta para discriminar: el estado de la conexión (AUC 0,795 → 0,882)
- Próximos pasos: testing set oficial, validación cruzada, regularización o interacciones

**Dato grande:** 0,795 → 0,882.
**Figura:** `18_logistica_or_calibracion.png` (forest plot: se ven los intervalos anchos de las categóricas) o ninguna.

**Guion**
> Nuestra opinión. Lo más sólido es la estructura de variables: tres técnicas dan los mismos tres bloques. Lo más frágil, la lectura de los grupos, con silhouette de 0,33, y los odds ratios categóricos tomados de a uno, que se mueven con la partición. Para discriminar ataque de normal, a nuestro juicio el estado de la conexión aporta más que cualquier patrón numérico: sin las categóricas, el AUC no llega a 0,80. Y creemos que el desempeño describe este laboratorio y no una red real. Como próximos pasos: validar con el testing set oficial procesado igual, repetir con validación cruzada, y probar interacciones o regularización para estabilizar los odds ratios. [Ajustar con las opiniones reales del grupo.]

**Transición:** (mismo orador) «Cerramos.»

---

### Diapositiva 15 · Respuesta a la pregunta guía y cierre (0:30 · Integrante 4)

**En pantalla**
- Los flujos se organizan en tres patrones: volumen, temporización y repetición
- Junto con estado, servicio y protocolo permiten estimar la probabilidad de ataque: AUC 0,882, con 28,7 % de normales marcados como ataque
- ¿Preguntas?

**Dato grande:** AUC 0,882 y 28,7 % de falsos positivos (los dos números juntos).
**Figura:** ninguna.

**Guion**
> Volviendo a la pregunta: los flujos se organizan en tres patrones, volumen, temporización y repetición, y esos patrones, junto con el estado, el servicio y el protocolo, permiten estimar la probabilidad de ataque con un AUC de 0,882, a costa de marcar como ataque a casi 3 de cada 10 flujos normales. Y con la salvedad de que los ataques son de laboratorio: lo más sólido que nos llevamos es la estructura de las variables, no los números puntuales. Muchas gracias; quedamos a disposición para sus preguntas.

---

## 3. Opinión crítica del grupo (borrador) — REVISAR GRUPO

> Cada juicio tiene evidencia del informe, pero **son opiniones**: el grupo debe confirmarlas o cambiarlas antes de exponer, y que cada integrante pueda defenderlas. Etapa 6 pide «su propia crítica y opinión».

1. **Para esta pregunta, lo que más aportó fue el estado de la conexión, no una técnica de reducción.** Con los tres puntajes del ACP el AUC en prueba es 0,795 (AIC 3.734,2); agregando protocolo, servicio y estado sube a 0,882 (AIC 2.876,5, razón de verosimilitud χ² = 871,7, 7 gl). Entre las técnicas de variables numéricas, el AF fue la más útil para *entender* (bloques puros) y el ACP para *predecir*. Defensa: el ACM y la logística coinciden en INT y CON_otros.
2. **Confianza en la logística: media y acotada.** Es un buen resultado interno (IC 0,864 a 0,900), pero los ataques son sintéticos, la proporción de 52 % de ataques es del diseño muestral, una sola partición, y excluimos TTL porque con ellas el AUC sería irreal. Además, INT coincide con «sin respuesta» en 913 de 913 flujos: el modelo no puede separarlos. Defensa: nos fiamos de la dirección de los efectos y del AUC como cota para este laboratorio, no de los valores puntuales de OR ni de la probabilidad como prevalencia.
3. **No «vendemos» los seis clusters como categorías.** Silhouette 0,333, k = 2, 4 y 5 casi empatan, el codo más marcado está en k = 4 y los clusters 2 y 6 tienen 36 % y 27 % de flujos con silhouette negativo. Lo valioso es el cluster 3, chico pero nítido (147 flujos, 100 % ataque, casi todo Generic).
4. **Qué haríamos distinto.** (a) Fijar las hipótesis antes de correr las técnicas (las fijamos después de explorar). (b) Usar el testing set oficial en lugar de partir la muestra. (c) Probar el AF sin `log_spkts`, que elimina el caso Heywood con cualquier estimador (propuesta nuestra, no implementada para no tocar X_num). (d) Evaluar un umbral distinto de 0,5 según el costo de un falso positivo (especificidad 0,713).

---

## 4. Preguntas probables de la docente y respuestas cortas

1. **¿Por qué log(x+1)?** Las 12 variables son positivas, muy asimétricas y con rangos enormes; log(x+1) conserva los ceros (18,9 % de `dbytes`, 29,6 % de `synack` y 25,9 % de `sjit` son ceros estructurales) y baja la asimetría de `sbytes` de 33,3 a 1,0. Persisten colas en `log_dur` (2,8): lo declaramos como limitación.
2. **¿Por qué sacaron `dpkts` y `rate`?** Con 14 candidatas el determinante era 1,0×10⁻⁷ (consigna: > 10⁻⁵). `dpkts` tiene r = 0,95 con `dbytes` y `rate` r = −0,91 con `sinpkt`. Sacando solo `dpkts` el determinante quedaba en 5,2×10⁻⁶, todavía bajo el umbral; sacando las dos, 6,3×10⁻⁵.
3. **¿Por qué GLS y 3 factores si el paralelo daba 4?** El 4.º autovalor observado es 0,127 (simulado 0,036), lejos de 1, y supera al azar porque n = 5.000; Kaiser reducido da 0,43; con 4 factores `ct_*` se parte en dos que correlacionan 0,62. Con 3 factores, minres, pa y ML dan Heywood en `log_spkts` (1,025; 1,095; 0,995); GLS no (máx. 0,897) y no obliga a sacar una variable. Costo: ajuste peor (RMSR 0,051 y TLI 0,609 frente a 0,033 y 0,79 con 4), por eso lo usamos descriptivamente.
4. **¿Por qué k = 6 si el silhouette está casi empatado?** Es el máximo (0,333), con k = 2, 4 y 5 entre 0,327 y 0,329, y todos < 0,5. El codo más marcado está en k = 4, que también era defendible. Elegimos 6 porque aparece el cluster 3 (147 flujos, 100 % ataque) que k = 4 perdería. Lo declaramos como debilidad: los clusters 2 y 6 están mal separados.
5. **¿Por qué terciles?** `dur` y `sbytes` son muy asimétricas (mediana de `sbytes` 918 y media 16.918); cortes de igual amplitud dejarían casi todo en una categoría. Los terciles (0,0185 s y 0,709 s; 564 y 1.580 bytes) dan 33 % por categoría, cumplen la regla del 5 % y no usan la etiqueta. Es un criterio estadístico; alternativas con sentido (< 0,01 s y < 1 s; ≤ 200 y 1.500 bytes) dan 31/45/24 y 21/43/36 %, también válidas.
6. **¿Por qué no usaron TTL en la logística?** Es un artefacto del laboratorio: genera separación perfecta y un AUC irreal. Tampoco usamos `tipo_trafico` ni `attack_cat`, porque filtran la etiqueta.
7. **¿Qué significa un OR de 375 con un IC tan ancho?** INT frente a FIN, con lo demás fijo, multiplica las chances de ataque por 375 (IC 107 a 1.318). El límite inferior > 1 respalda la dirección, pero no el valor: con otra partición dio 93, y INT tiene VIF 17,2 y coincide con «sin respuesta» en 913 de 913 casos. No hay separación (coeficiente máximo 5,9, convergió en 6 iteraciones). Se cita como «muy alto y positivo», no como número.
8. **¿Por qué la inercia ajustada es tan distinta de la cruda?** En el ACM los autovalores crudos están deprimidos por la codificación disyuntiva (inercia total cruda 2,286); la corrección de Greenacre reescala (total ajustada 0,414). El plano da 41,4 % crudo y 87,4 % ajustado; el segundo es optimista. Retenemos 2 dimensiones por el codo (la 3.ª aporta 1,8 % ajustado) y damos siempre ambos números.
9. **¿Por qué estratificar por `attack_cat` y no por `label`?** Para que cada tipo de ataque quede en la misma proporción en entrenamiento y prueba (diferencias < 0,05 puntos; Worms 4 y 2 flujos); `label` queda balanceado (51,8 % en ambos) porque es función de `attack_cat`. Con `label` el AUC era 0,878 y con `attack_cat` 0,882: la conclusión no cambia, pero el OR de INT sí se movió (93 a 375), lo que muestra la inestabilidad de los OR categóricos.
10. **¿Por qué `dns` tiene un OR de 19,1 si tiene menos ataques que «ninguno» (32 % frente a 49 %)?** Porque el OR es condicional al estado y al protocolo, con los que `dns` se solapa (udp e INT, VIF alto). El signo cambia al controlar; por eso no se leen los coeficientes categóricos de a uno.
11. *(Extra)* **¿Por qué estandarizar el ACP?** Las varianzas van de 0,002 a 13,61 y tres variables reúnen el 83,2 % de la varianza total. Sin estandarizar, CP1 sería 66,4 % (frente a 43,3 %) y reflejaría escalas.

---

## 5. Ensayo cronometrado: checklist de 5 puntos

1. **Ensayo completo con cronómetro, de pie y sin leer.** Meta: terminar entre 18:00 y 19:15. Anotar el tiempo de cada diapositiva y compararlo con la tabla de la sección 1; si un orador se pasa de su bloque más de 20 s, recortar las frases marcadas «recortable».
2. **Ensayar las tres transiciones entre oradores** (diap. 4→5, 7→8, 10→11) sin silencios: el siguiente ya tiene que estar en posición con el control remoto o el mouse.
3. **Cada orador se sabe de memoria su «dato grande» y puede explicar la cifra con otras palabras** (KMO 0,748; 74,5 %; 68,6 %; 0,333; 41,4 % crudo y 87,4 % ajustado; AUC 0,882; OR por desvío).
4. **Ensayo de preguntas:** la docente (o un compañero) tira al azar 5 de las 10 preguntas de la sección 4; responder en menos de 40 s, quien tenga el tema se anima primero y el resto completa.
5. **Prueba técnica de la sala:** abrir el PDF/PPT en la compu del aula, verificar que las figuras (08, 09, 10, 12, 15, 17, 18 y 07) se leen a 3 metros, y llevar de respaldo las diapositivas de respaldo (silhouette, heatmap de perfiles, calibración) por si preguntan.

---

## 6. Notas de consistencia (para el grupo)

- **Silhouette de k = 2 a 6:** el capítulo 5 y el doc de validación dicen que «las diferencias entre k = 2 y 6 son menores que 0,006»; según `cluster_metricas.csv`, k = 6 (0,3334) y k = 4 (0,3265) difieren en 0,0068, y k = 3 (0,3018) en 0,0316. En el guion se dice «k = 2, 4 y 5 entre 0,327 y 0,329» (0,3283; 0,3265; 0,3290 en el CSV: sería «0,327 a 0,329» con redondeo) y no se repite la frase «menos de 0,006». Conviene corregirla en el informe.
- **Atípicos:** el capítulo 2 dice 1.714 flujos (34,3 %); `atipicos_por_flujo.csv` da 1.715 con la columna `n_atipicos_revision_12` > 0 (1.607 con `n_atipicos_original` > 0). El guion usa solo «34,3 %».
- **Porcentajes de ataque en la muestra:** Exploits 18,4 + Fuzzers 15,0 + Reconnaissance 7,0 + otros 11,5 = 51,9, frente a 51,8 total (redondeo).
- **OR de PC:** `log_reg_coeficientes.csv` trae el OR por unidad (2,03; 0,70; 2,03); el informe y el guion usan el OR por desvío (5,01; 0,59; 2,54), que sale de `log_reg_or_por_desvio.csv`.
