# 03b_lm_vs_glm.R — Week 3: why a normal linear model is not ideal for our
# count and binary responses, and what the GLM version looks like.
# Base R only. Run from the project folder (open the .Rproj first).

source("code/00_load_data.R")

# =============================================================================
# PART 1: COUNT RESPONSE — goals_scored (Ashford matches)
# =============================================================================

# ---- 1a. Normal linear model ----
lm_goals <- lm(goals_scored ~ home_away + opponent_rank, data = matches)
summary(lm_goals)

fit_lm_goals <- fitted(lm_goals)
range(fit_lm_goals)        # lowest fitted value is very close to 0
sum(fit_lm_goals < 0)      # how many negative fitted values?

# Goals are whole numbers >= 0, but the normal model treats them as continuous
# and its prediction intervals happily go below zero:
predict(lm_goals,
        newdata = data.frame(home_away = factor("Away", levels = c("Home", "Away")),
                             opponent_rank = 1),
        interval = "prediction")

# ---- 1b. Constant-variance check ----
# A normal LM assumes the same residual variance everywhere. For counts the
# variance usually grows with the mean (Poisson: variance = mean).
tapply(residuals(lm_goals), matches$home_away, var)   # home vs away spread

png("outputs/lm_goals_residuals.png", width = 900, height = 450)
par(mfrow = c(1, 2))
plot(fitted(lm_goals), residuals(lm_goals), pch = 19,
     col = matches$home_away,
     xlab = "Fitted goals (LM)", ylab = "Residual",
     main = "LM for goals: residuals vs fitted")
abline(h = 0, lty = 2)
legend("topleft", legend = levels(matches$home_away), col = 1:2, pch = 19)
qqnorm(residuals(lm_goals), main = "LM for goals: normal Q-Q")
qqline(residuals(lm_goals))
dev.off()

# ---- 1c. Poisson GLM (log link) ----
glm_goals <- glm(goals_scored ~ home_away + opponent_rank,
                 family = poisson, data = matches)
summary(glm_goals)
exp(coef(glm_goals))       # rate ratios: multiplicative effect on expected goals

# Quick overdispersion check: should be close to 1 for a Poisson model
sum(residuals(glm_goals, type = "pearson")^2) / df.residual(glm_goals)

# ---- 1d. Compare LM and GLM predictions ----
new_matches <- expand.grid(
  home_away     = factor(c("Home", "Away"), levels = c("Home", "Away")),
  opponent_rank = c(1, 12, 24)
)
goals_compare <- data.frame(
  new_matches,
  lm_pred  = round(predict(lm_goals,  newdata = new_matches), 2),
  glm_pred = round(predict(glm_goals, newdata = new_matches, type = "response"), 2)
)
goals_compare
write.csv(goals_compare, "outputs/goals_lm_vs_glm_predictions.csv", row.names = FALSE)

# Plot: data with both fitted curves, home and away
rank_grid <- 1:24
png("outputs/goals_lm_vs_glm.png", width = 900, height = 500)
plot(goals_scored ~ opponent_rank, data = matches, pch = 19,
     col = ifelse(matches$home_away == "Home", "black", "red"),
     xlab = "Opponent final rank (1 = strongest)", ylab = "Goals scored",
     main = "Goals scored: linear model vs Poisson GLM")
for (ha in c("Home", "Away")) {
  nd <- data.frame(home_away = factor(ha, levels = c("Home", "Away")),
                   opponent_rank = rank_grid)
  colr <- ifelse(ha == "Home", "black", "red")
  lines(rank_grid, predict(lm_goals, newdata = nd), col = colr, lty = 2)
  lines(rank_grid, predict(glm_goals, newdata = nd, type = "response"), col = colr, lwd = 2)
}
legend("topleft",
       legend = c("Home", "Away", "LM (dashed)", "Poisson GLM (solid)"),
       col = c("black", "red", "grey40", "grey40"),
       pch = c(19, 19, NA, NA), lty = c(NA, NA, 2, 1), lwd = c(NA, NA, 1, 2))
dev.off()

# =============================================================================
# PART 2: BINARY RESPONSE — injured (league players)
# =============================================================================

# ---- 2a. Linear probability model (normal LM on a 0/1 outcome) ----
lm_inj <- lm(injured ~ prev_injuries + training_load + position, data = players)
summary(lm_inj)

fit_lm_inj <- fitted(lm_inj)
range(fit_lm_inj)
sum(fit_lm_inj < 0)        # impossible "probabilities" below 0
sum(fit_lm_inj > 1)        # impossible "probabilities" above 1
players[fit_lm_inj < 0, c("team", "position", "prev_injuries", "training_load")]

# ---- 2b. Logistic (binomial) GLM ----
glm_inj <- glm(injured ~ prev_injuries + training_load + position,
               family = binomial, data = players)
summary(glm_inj)
exp(coef(glm_inj))         # odds ratios
range(fitted(glm_inj))     # always strictly between 0 and 1

# ---- 2c. Compare fitted probabilities ----
png("outputs/injured_lm_vs_glm.png", width = 900, height = 450)
par(mfrow = c(1, 2))
plot(fitted(lm_inj), residuals(lm_inj), pch = 19, col = players$injured + 1,
     xlab = "Fitted value (LM)", ylab = "Residual",
     main = "LM for injured: residuals vs fitted")
abline(h = 0, lty = 2)   # two bands of residuals = binary response, not normal
plot(fitted(lm_inj), fitted(glm_inj), pch = 19, col = "grey30",
     xlab = "LM fitted 'probability'", ylab = "Logistic GLM fitted probability",
     main = "Fitted probabilities: LM vs GLM")
abline(0, 1, lty = 2)
abline(v = 0, col = "red")     # LM values left of this line are impossible
dev.off()

# Extreme players, where the two models differ most
extreme_players <- data.frame(
  prev_injuries = c(0, 4),
  training_load = c(1, 5),
  position      = factor(c("DEF", "GK"), levels = levels(players$position))
)
data.frame(extreme_players,
           lm_pred  = round(predict(lm_inj,  newdata = extreme_players), 3),
           glm_pred = round(predict(glm_inj, newdata = extreme_players, type = "response"), 3))

# =============================================================================
# SUMMARY (copy into notes/decision-notes.md)
# =============================================================================
# - Goals: the LM gives no negative fitted values here, but for an away game
#   v the top side it predicts only ~0.08 goals (Poisson GLM: ~0.43), and its
#   prediction intervals go below zero. Residual variance is about 3x larger
#   at home than away, breaking the constant-variance assumption. The Poisson
#   GLM respects that goals are non-negative counts whose variance rises with
#   the mean. Pearson dispersion is ~1, so plain Poisson looks adequate once
#   home_away and opponent_rank are in the model.
# - Injured: the LM produces 3 fitted "probabilities" below 0, and its
#   residuals fall in two bands, so they cannot be normal. The logistic GLM
#   keeps every fitted probability in (0, 1) and gives interpretable odds ratios.
# - Conclusion: GLMs (Poisson for counts, binomial for binary) are the
#   appropriate framework for the main responses in this project.