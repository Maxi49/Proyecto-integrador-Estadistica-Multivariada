# ETAPA 6. Regresión logística: ¿es ataque (1) o normal (0)?
# Ejecutar desde la carpeta principal del proyecto: Rscript R/06_logistica.R
#
# Diseño (decidido por el grupo/orquestador):
#  - Validación: partición estratificada por label, 70 % entrenamiento / 30 % prueba,
#    dentro de la muestra de 5.000 flujos. El testing set original de UNSW-NB15 no está
#    en el repositorio y habría que prepararlo igual que la muestra.
#  - Predictores: los 3 puntajes del ACP + proto_g, service_g, state_g.
#  - Prohibidos: TTL (sttl, dttl, ttl_origen, perfil_estado_ttl, ct_state_ttl: separación
#    perfecta por artefacto del laboratorio), tipo_trafico, attack_cat y n_atipicos
#    (son la respuesta "disfrazada" o derivan de ella).
#  - El ACP se reajusta SOLO con el entrenamiento para que el conjunto de prueba no
#    influya en los puntajes (evita fuga de información).
library(MASS)   # confint() por verosimilitud perfilada para glm
library(pROC)
set.seed(42)

base <- readRDS("resultados/base_limpia.rds")
conjuntos <- readRDS("resultados/conjuntos_congelados.rds")
X_num <- conjuntos$X_num
acp_completo <- readRDS("resultados/acp.rds")
n_comp <- acp_completo$n_componentes   # 3 componentes (Kaiser), como en el informe
dir.create("resultados/tablas", recursive = TRUE, showWarnings = FALSE)
guardar <- function(x, nombre) write.csv(x, paste0("resultados/tablas/log_reg_", nombre, ".csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
coma <- function(x, d = 3) formatC(x, format = "f", digits = d)

# 1. Respuesta: ataque = 1, normal = 0 (en la base label es texto "ataque"/"normal").
stopifnot(all(base$label %in% c("ataque", "normal")))
base$y <- as.integer(base$label == "ataque")

# 2. Partición estratificada 70/30 por label: se sortea dentro de cada clase para que
# ambos conjuntos conserven ~51,8 % de ataques.
idx_train <- unlist(lapply(split(seq_len(nrow(base)), base$y), function(i)
  sample(i, size = round(0.7 * length(i)))))
idx_train <- sort(idx_train)
idx_test <- setdiff(seq_len(nrow(base)), idx_train)
stopifnot(length(intersect(idx_train, idx_test)) == 0)
particion <- data.frame(conjunto = c("entrenamiento", "prueba"),
  n = c(length(idx_train), length(idx_test)),
  n_ataques = c(sum(base$y[idx_train]), sum(base$y[idx_test])),
  pct_ataques = c(100 * mean(base$y[idx_train]), 100 * mean(base$y[idx_test])))
guardar(particion, "particion")
guardar(data.frame(id = base$id, conjunto = ifelse(seq_len(nrow(base)) %in% idx_train,
  "entrenamiento", "prueba")), "particion_ids")
print(particion)

# 3. ACP reajustado SOLO con el entrenamiento; la prueba se proyecta con predict(), que
# usa las medias y desvíos del entrenamiento.
acp_tr <- prcomp(X_num[idx_train, ], scale. = TRUE)
# Los signos de una componente son arbitrarios. Se alinean con el ACP del informe (5.000):
# si la carga de entrenamiento apunta al lado contrario, se invierte la componente.
signos <- sapply(1:n_comp, function(k)
  sign(sum(acp_tr$rotation[, k] * acp_completo$modelo$rotation[, k])))
cat("Signo relativo al ACP completo (1 = igual, -1 = invertido):", signos, "\n")
acp_tr$rotation[, 1:n_comp] <- sweep(acp_tr$rotation[, 1:n_comp, drop = FALSE], 2, signos, "*")
# Se recalculan los puntajes de entrenamiento con la rotación ya corregida.
nombres_cp <- paste0("PC", 1:n_comp)
P_tr <- predict(acp_tr, X_num[idx_train, ])[, 1:n_comp]
P_te <- predict(acp_tr, X_num[idx_test, ])[, 1:n_comp]
colnames(P_tr) <- colnames(P_te) <- nombres_cp

# Comparación de cargas: entrenamiento vs. ACP con los 5.000.
dif_cargas <- acp_tr$rotation[, 1:n_comp] - acp_completo$modelo$rotation[, 1:n_comp]
comp_cargas <- data.frame(variable = rownames(acp_tr$rotation),
  setNames(as.data.frame(acp_tr$rotation[, 1:n_comp]), paste0(nombres_cp, "_entrenamiento")),
  setNames(as.data.frame(acp_completo$modelo$rotation[, 1:n_comp]), paste0(nombres_cp, "_completo")))
guardar(comp_cargas, "acp_cargas_comparacion")
resumen_cargas <- data.frame(componente = nombres_cp, signo_invertido = signos == -1,
  max_dif_absoluta = apply(abs(dif_cargas), 2, max),
  correlacion = sapply(1:n_comp, function(k)
    cor(acp_tr$rotation[, k], acp_completo$modelo$rotation[, k])),
  pct_varianza_entrenamiento = 100 * acp_tr$sdev[1:n_comp]^2 / sum(acp_tr$sdev^2))
guardar(resumen_cargas, "acp_cargas_resumen")
print(resumen_cargas)

# 4. Categóricas con categoría de referencia explícita: la más frecuente de cada una,
# así las demás se comparan contra la situación "típica" y el error estándar de la
# referencia es el menor posible: tcp (70,8 %), ninguno (60,0 %), FIN (69,3 %).
ref <- function(x, nivel) relevel(factor(x), ref = nivel)
datos <- data.frame(y = base$y, id = base$id, P = rbind(P_tr, P_te)[order(c(idx_train, idx_test)), ],
  proto_g = ref(base$proto_g, "tcp"), service_g = ref(base$service_g, "ninguno"),
  state_g = ref(base$state_g, "FIN"))
names(datos) <- sub("^P\\.", "", names(datos))
train <- datos[idx_train, ]
test <- datos[idx_test, ]
stopifnot(identical(train$id, base$id[idx_train]))

# 5. Dos modelos anidados. M1: solo los puntajes. M2: M1 + categóricas.
M1 <- glm(y ~ PC1 + PC2 + PC3, data = train, family = binomial)
aviso <- NULL
M2 <- withCallingHandlers(
  glm(y ~ PC1 + PC2 + PC3 + proto_g + service_g + state_g, data = train, family = binomial),
  warning = function(w) { aviso <<- c(aviso, conditionMessage(w)); invokeRestart("muffleWarning") })
if (!is.null(aviso)) cat("AVISO al ajustar M2:", aviso, "\n")

# 6. Comparación: AIC, devianza, test de razón de verosimilitud y AUC en prueba.
auc_prueba <- function(m) auc(roc(test$y, as.numeric(predict(m, test, type = "response")),
  levels = c(0, 1), direction = "<", quiet = TRUE))
mcfadden <- function(m) 1 - m$deviance / m$null.deviance
lr <- anova(M1, M2, test = "Chisq")
comparacion <- data.frame(modelo = c("M1: puntajes ACP", "M2: puntajes ACP + proto + service + state"),
  gl_residuales = c(M1$df.residual, M2$df.residual), parametros = c(length(coef(M1)), length(coef(M2))),
  AIC = c(AIC(M1), AIC(M2)), BIC = c(BIC(M1), BIC(M2)),
  devianza = c(deviance(M1), deviance(M2)),
  LR_chi2 = c(NA, lr$Deviance[2]), LR_gl = c(NA, lr$Df[2]), LR_p = c(NA, lr$`Pr(>Chi)`[2]),
  AUC_prueba = c(as.numeric(auc_prueba(M1)), as.numeric(auc_prueba(M2))),
  pseudoR2_McFadden = c(mcfadden(M1), mcfadden(M2)))
guardar(comparacion, "comparacion_modelos")
print(comparacion)

# 7. Elección: M2 si mejora el AIC y el LR es significativo (la ganancia no es azar);
# si no, M1 por parsimonia. La decisión sale de los números, no se fija a mano.
elegido <- if (AIC(M2) < AIC(M1) && lr$`Pr(>Chi)`[2] < 0.05) "M2" else "M1"
modelo <- if (elegido == "M2") M2 else M1
cat("Modelo elegido:", elegido, "\n")

# 8. Coeficientes, OR e IC 95 % por verosimilitud perfilada (más fiable que Wald cuando
# hay categorías raras o coeficientes grandes). Se incluye también el IC de Wald.
sm <- summary(modelo)$coefficients
ic_perfil <- suppressMessages(confint(modelo))
se <- sm[, 2]
coefs <- data.frame(termino = rownames(sm), estimacion = sm[, 1], error_estandar = se,
  z = sm[, 3], p = sm[, 4], OR = exp(sm[, 1]),
  OR_IC95_inf = exp(ic_perfil[, 1]), OR_IC95_sup = exp(ic_perfil[, 2]),
  OR_Wald_IC95_inf = exp(sm[, 1] - 1.96 * se), OR_Wald_IC95_sup = exp(sm[, 1] + 1.96 * se),
  tipo_IC = "verosimilitud perfilada (Wald en columnas aparte)")
guardar(coefs, "coeficientes")
# Los OR de PC1-PC3 son "por cada desvío (1 unidad estandarizada) del puntaje", porque
# el puntaje de cada componente tiene desvío = sdev de la componente: el OR por 1 desvío
# del puntaje es exp(beta * sdev). Se guarda también esa versión, que es la comparable.
sdev_tr <- acp_tr$sdev[1:n_comp]
or_desvio <- data.frame(termino = nombres_cp, desvio_puntaje = sdev_tr,
  OR_por_unidad = exp(coef(modelo)[nombres_cp]),
  OR_por_desvio = exp(coef(modelo)[nombres_cp] * sdev_tr),
  OR_desvio_IC95_inf = exp(ic_perfil[nombres_cp, 1] * sdev_tr),
  OR_desvio_IC95_sup = exp(ic_perfil[nombres_cp, 2] * sdev_tr))
guardar(or_desvio, "or_por_desvio")
print(coefs[, 1:8]); print(or_desvio)

# 9. Desempeño en prueba con umbral 0,5. AUC con IC 95 % de DeLong.
p_te <- as.numeric(predict(modelo, test, type = "response"))
roc_te <- roc(test$y, p_te, levels = c(0, 1), direction = "<", quiet = TRUE)
ic_auc <- ci.auc(roc_te, method = "delong")
guardar(data.frame(AUC = as.numeric(auc(roc_te)), IC95_inf = ic_auc[1], IC95_sup = ic_auc[3],
  metodo_IC = "DeLong", modelo = elegido), "auc")
pred <- as.integer(p_te >= 0.5)
VP <- sum(pred == 1 & test$y == 1); VN <- sum(pred == 0 & test$y == 0)
FP <- sum(pred == 1 & test$y == 0); FN <- sum(pred == 0 & test$y == 1)
guardar(data.frame(real = c("normal", "normal", "ataque", "ataque"),
  predicho = c("normal", "ataque", "normal", "ataque"), n = c(VN, FP, FN, VP)), "confusion")
metricas <- data.frame(umbral = 0.5, exactitud = (VP + VN) / length(pred),
  sensibilidad = VP / (VP + FN), especificidad = VN / (VN + FP),
  precision = VP / (VP + FP), F1 = 2 * VP / (2 * VP + FP + FN))
guardar(metricas, "metricas")
print(metricas); print(ic_auc)

# Curva ROC (puntos para graficar) y probabilidades predichas en prueba.
guardar(data.frame(umbral = roc_te$thresholds, fpr = 1 - roc_te$specificities,
  tpr = roc_te$sensitivities), "roc_curva")
guardar(data.frame(id = test$id, y = test$y, p = p_te), "predicciones_prueba")

# 10. Calibración por deciles de probabilidad predicha (en prueba).
dec <- cut(p_te, breaks = unique(quantile(p_te, seq(0, 1, .1))), include.lowest = TRUE, labels = FALSE)
calib <- do.call(rbind, lapply(sort(unique(dec)), function(d) data.frame(decil = d,
  n = sum(dec == d), p_media = mean(p_te[dec == d]), prop_observada = mean(test$y[dec == d]))))
guardar(calib, "calibracion")
print(calib)

# 11. Multicolinealidad: VIF de cada columna de la matriz de diseño y correlaciones.
# (Las dummies de un mismo factor se correlacionan entre sí por construcción.)
mm <- model.matrix(modelo)[, -1, drop = FALSE]
vif <- sapply(seq_len(ncol(mm)), function(j) 1 / (1 - summary(lm(mm[, j] ~ mm[, -j]))$r.squared))
guardar(data.frame(termino = colnames(mm), VIF = vif), "vif")
guardar(data.frame(termino = colnames(mm), round(cor(mm), 4)), "correlaciones_predictores")
print(data.frame(termino = colnames(mm), VIF = round(vif, 2)))

# 12. Separación: coeficientes enormes, EE gigantes o probabilidades ajustadas en 0/1.
ajustadas <- fitted(modelo)
separacion <- data.frame(
  max_abs_coef = max(abs(coef(modelo))), max_error_estandar = max(se),
  ajustadas_menor_1e8 = sum(ajustadas < 1e-8), ajustadas_mayor_1_menos_1e8 = sum(ajustadas > 1 - 1e-8),
  aviso_glm = ifelse(is.null(aviso), "sin avisos", paste(unique(aviso), collapse = " | ")),
  convergio = modelo$converged, iteraciones = modelo$iter)
guardar(separacion, "separacion")
print(separacion)
# Tablas cruzadas categoría x respuesta en entrenamiento: celdas vacías delatarían separación.
cruces <- do.call(rbind, lapply(c("proto_g", "service_g", "state_g"), function(v) {
  t <- table(train[[v]], train$y)
  data.frame(variable = v, categoria = rownames(t), n_normal = t[, "0"], n_ataque = t[, "1"],
    pct_ataque = 100 * t[, "1"] / rowSums(t))
}))
guardar(cruces, "cruces_categoricas")
print(cruces)

# 13. Observaciones influyentes: distancia de Cook > 4/n.
cook <- cooks.distance(modelo)
umbral_cook <- 4 / nrow(train)
influyentes <- data.frame(umbral = umbral_cook, n_influyentes = sum(cook > umbral_cook),
  pct = 100 * mean(cook > umbral_cook), cook_max = max(cook), id_cook_max = train$id[which.max(cook)],
  n_cook_mayor_1 = sum(cook > 1))
guardar(influyentes, "influyentes")
print(influyentes)

# 14. Guardar el modelo y lo necesario para reproducir las predicciones.
# Interpretación: la probabilidad predicha es relativa a ESTA base (≈ 52 % de ataques,
# sin duplicados, ataques sintéticos del laboratorio): se interpretan los odds ratios,
# no prevalencias absolutas. El OR de PCk es por cada desvío del puntaje.
saveRDS(list(modelo = modelo, elegido = elegido, M1 = M1, M2 = M2, acp_entrenamiento = acp_tr,
  idx_train = idx_train, idx_test = idx_test, ids_train = base$id[idx_train],
  ids_test = base$id[idx_test], semilla = 42), "resultados/logistica.rds")
cat("Listo. Modelo", elegido, "| AUC prueba:", coma(as.numeric(auc(roc_te))),
  "IC95 [", coma(ic_auc[1]), ",", coma(ic_auc[3]), "]\n")
