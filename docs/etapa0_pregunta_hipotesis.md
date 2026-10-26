# Etapa 0 · Pregunta guía e hipótesis (PROPUESTA para el grupo)

> Redactadas el 26/10/2026. Se fundamentan en conocimiento previo del dominio y en el diseño
> de la base (Moustafa y Slay, 2015, agrupan las variables en bloques de flujo, básicas,
> de contenido, de tiempo y "generadas"), no en los resultados de las Etapas 1 a 4.
> Aviso de honestidad: el grupo ya corrió las técnicas antes de fijarlas. En el informe se
> presentan como hipótesis de partida y se contrastan con evidencia, incluyendo las que fallan.

## Pregunta guía

¿Qué patrones de volumen, temporización y repetición de conexiones caracterizan a los flujos de
red de UNSW-NB15, y en qué medida esos patrones —y las categorías de protocolo, servicio y estado
asociadas— distinguen el tráfico normal del tráfico de ataque, al punto de permitir estimar la
probabilidad de que un flujo sea un ataque?

## Hipótesis

**H1 · Variables que se mueven juntas.** Las 12 variables de X_num se organizan en tres bloques
correlacionados entre sí y poco correlacionados con los demás: *volumen* (spkts, sbytes, dbytes),
*temporización* (dur, sinpkt, sjit, synack) y *repetición de conexiones* (las cinco ct_*).
Se espera que ACP, AF y el cluster de variables recuperen esos mismos tres bloques.

**H2 · Grupos de observaciones.** Existen grupos de flujos definidos sobre todo por la forma de la
conexión (con o sin respuesta del destino, conexiones breves frente a sostenidas). Esos grupos
separan parcialmente el tráfico normal del de ataque, pero no distinguen los tipos de ataque entre sí.

**H3 · Asociaciones entre categorías.** El tráfico de ataque se asocia con conexiones incompletas
(estado INT) y sin respuesta del destino; el tráfico normal, con conexiones cerradas o establecidas
(FIN, CON) y con servicios identificados (http, dns).

**H4 · Regresión logística (parte posterior).** Un modelo logístico con los ejes de volumen,
temporización y repetición (puntajes del ACP) más protocolo, servicio y estado discrimina
ataque de normal mejor que el azar, con un AUC mayor a 0,80 en datos de validación no usados
para ajustar el modelo. No se usan TTL ni tipo_trafico como predictores.

## Qué evidencia confirmaría o refutaría cada una

| Hipótesis | Se confirma si… | Se refuta si… |
|---|---|---|
| H1 | ACP/AF/cluster de variables muestran los tres bloques con cargas ≥ 0,40 en su bloque | Los bloques se mezclan o aparecen más/menos bloques que no se pueden interpretar |
| H2 | Algún cluster es casi todo normal y otro casi todo ataque, y los tipos de ataque se reparten entre clusters | Los clusters tienen la misma proporción de ataques, o cada cluster corresponde a un tipo de ataque |
| H3 | INT y sin_respuesta se asocian con ataques; FIN/CON y http/dns con normal (ACS/ACM y tablas cruzadas) | Las proporciones de estado y respuesta son similares entre normal y ataques |
| H4 | AUC de validación > 0,80 | AUC de validación ≤ 0,80 |
