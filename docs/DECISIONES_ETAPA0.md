# Decisiones y alcance · Etapa 0 · 24/10/2026

## Acuerdos previos respetados

Se utilizó el archivo muestra_estratificada-simulado-de-ataques.xlsx confirmado por
el usuario. CONTEXTO_PROYECTO.md nombra otra versión: no se supuso su existencia.
El contexto histórico se conserva sin reescribir sus afirmaciones ni convertir sus
pendientes en acuerdos del grupo. Este documento y los resultados describen la nueva entrega.

X_num mantiene exactamente las 12 versiones log_ acordadas en la sección 6 del
contexto; no se reintroducen dpkts ni rate. Ninguna etiqueta o TTL se usa en ese
conjunto. Las columnas originales y n_atipicos permanecen intactas.

## Preparación aplicada en esta entrega

No se eliminan filas ni se imputan o recodifican valores del Excel.
El CSV y RDS comunes conservan 5.000 × 68. El código de FTP 4 se registra como
discrepancia con el diccionario, sin inventar una corrección; la variable no forma
parte de X_num ni X_cat.

El control de atípicos usa bisagras de Tukey y límites de 1,5 RIC en las 12 log_.
Se conserva cada observación y se separa ese resultado del indicador previo.
Las razones de limpieza anterior y muestreo proceden del contexto recibido;
esta ejecución no rehace ni certifica ese proceso.

## Propuestas operativas que requieren revisión del grupo

La pregunta, el objetivo y las tres hipótesis del capítulo son propuestas de redacción
que contemplan la posterior regresión logística. Se formularon con conocimiento de
la exploración previa, por lo que no se las presenta como hipótesis preregistradas.

Para cumplir la consigna de ACM se congela una propuesta de X_cat con:

- tipo_trafico, proto_g, service_g y state_g, ya agrupadas en la base.
- respuesta_destino: dpkts = 0 frente a dpkts > 0, interpretable como ausencia/presencia de respuesta.
- duracion_banda: terciles de dur, quantile tipo 7.
- bytes_origen_banda: terciles de sbytes, quantile tipo 7.

Los cortes se definen sin consultar label y quedan guardados para reproducibilidad.
No se agrega ninguna columna al Excel; las derivadas van en categoricas_acm.csv
y en conjuntos_congelados.rds. Todas las modalidades superan 5%.
En Etapa 4 se revisarán redundancias (en especial estado/respuesta) y si tipo_trafico
conviene como activa o suplementaria. Una decisión posterior debe versionarse y
explicarse: no debe sobreescribir silenciosamente el conjunto congelado.

## Pendientes fuera de esta entrega

- Revisión y aceptación grupal de hipótesis, decisiones previas y propuesta X_cat.
- Aprobación académica de la base por la docente y eventual reenvío.
- Ejecución de ACP, AF, clustering, ACS y ACM.
- Elección del par para ACS, variable para colorear y papel activo/suplementario en ACM.
- Diseño de validación de la futura logística; excluir TTL y variables que revelan la etiqueta.

Los resultados de Bartlett/KMO no certifican normalidad ni independencia.
No se afirma que los grupos esperados ni las hipótesis ya estén confirmados.
