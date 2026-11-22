# 05a_injury_diagnostics.R — Yousuf
# Player-level diagnostics for the final injury model from 04b:
#   injured ~ age + training_load + prev_injuries
# Residuals, leverage, Cook's distance, a refit without the five most
# influential players, and a binned residual plot.
#
# Split from code/drafts/Week4 and Week5.R (Part 1, 09/11/2026), which didn't
# run from a fresh session. Changes (22/11/2026):
#   - source the data loader; use `players` (from 00_load_data.R), not
#     `league_players`;
#   - removed the duplicate write.csv of injury_unusual_players.csv and the
#     interactive checks (head(), dir.exists(), list.files());
#   - added the binned residual plot (section 6).
# Liha's 05b covers grouped goodness of fit for the same model.

source("code/00_load_data.R")

# ==========================================
# SECTION 1: FINAL INJURY MODEL
# ==========================================

injury_model <- glm(
  injured ~ age + training_load + prev_injuries,
  data = players,
  family = binomial
)
summary(injury_model)

nobs(injury_model)
length(coef(injury_model))

# ==========================================
# SECTION 2: RESIDUALS
# ==========================================

# Standardised deviance residuals
dev_res <- rstandard(injury_model)

# Pearson residuals
pearson_res <- residuals(injury_model, type = "pearson")

# Fitted probabilities
fitted_values <- fitted(injury_model)

# Save residual diagnostic plots
png("outputs/injury_final_residuals.png",
    width = 1200, height = 1200)

par(mfrow = c(3, 1))

# Plot 1: Standardised deviance residuals
plot(fitted_values, dev_res,
     xlab = "Fitted values",
     ylab = "Standardised deviance residuals",
     main = "Deviance Residuals vs Fitted Values",
     pch = 19)
abline(h = c(-2, 0, 2), lty = c(2, 1, 2))

# Plot 2: Pearson residuals
plot(fitted_values, pearson_res,
     xlab = "Fitted values",
     ylab = "Pearson residuals",
     main = "Pearson Residuals vs Fitted Values",
     pch = 19)
abline(h = c(-2, 0, 2), lty = c(2, 1, 2))

# Plot 3: Normal Q-Q plot
qqnorm(dev_res,
       main = "Normal Q-Q Plot of Deviance Residuals",
       pch = 19)
qqline(dev_res, col = "red")

dev.off()

# Identify players with large standardised deviance residuals
unusual_players <- which(abs(dev_res) > 2)
unusual_players
dev_res[unusual_players]

# Summary table of unusual players
unusual_summary <- data.frame(
  player_row = unusual_players,
  injured = players$injured[unusual_players],
  age = players$age[unusual_players],
  training_load = players$training_load[unusual_players],
  prev_injuries = players$prev_injuries[unusual_players],
  fitted_probability = fitted_values[unusual_players],
  deviance_residual = dev_res[unusual_players]
)
unusual_summary

write.csv(
  unusual_summary,
  "outputs/injury_unusual_players.csv",
  row.names = FALSE
)

# Interpretation of unusual residuals:
# 26 players had standardised deviance residuals
# greater than 2 in absolute value.
#
# All 26 players were injured, despite having relatively
# low predicted injury probabilities (approximately 4.1%
# to 13.2%).
#
# This suggests that the model underestimated injury
# probabilities for these players.
#
# Their ages ranged from 17 to 31, training loads from
# 1 to 4, and previous injuries from 0 to 1.
#
# These observations should be investigated, but large
# residuals alone do not justify removing players.

# ==========================================
# SECTION 3: LEVERAGE
# ==========================================

leverage <- hatvalues(injury_model)

# Average leverage p/n
p <- length(coef(injury_model))
n <- nobs(injury_model)
average_leverage <- p / n
average_leverage

# Players with leverage above 2p/n
high_leverage <- which(leverage > 2 * average_leverage)
high_leverage
leverage[high_leverage]

high_leverage_summary <- data.frame(
  player_row = high_leverage,
  age = players$age[high_leverage],
  training_load = players$training_load[high_leverage],
  prev_injuries = players$prev_injuries[high_leverage],
  leverage = leverage[high_leverage]
)

# Sort from highest to lowest leverage
high_leverage_summary <- high_leverage_summary[
  order(-high_leverage_summary$leverage), ]

# The 10 highest leverage players
head(high_leverage_summary, 10)

write.csv(
  high_leverage_summary,
  "outputs/injury_high_leverage.csv",
  row.names = FALSE
)

# ==========================================
# SECTION 4: COOK'S DISTANCE
# ==========================================

cooks <- cooks.distance(injury_model)

png("outputs/injury_final_cooks.png",
    width = 1200,
    height = 800)

plot(cooks,
     type = "h",
     main = "Cook's Distance – Final Injury Model",
     xlab = "Player (row number)",
     ylab = "Cook's Distance")

dev.off()

# Five most influential players
top5_influential <- order(cooks, decreasing = TRUE)[1:5]
top5_influential
cooks[top5_influential]

influential_summary <- data.frame(
  player_row = top5_influential,
  injured = players$injured[top5_influential],
  age = players$age[top5_influential],
  training_load = players$training_load[top5_influential],
  prev_injuries = players$prev_injuries[top5_influential],
  fitted_probability = fitted_values[top5_influential],
  cooks_distance = cooks[top5_influential]
)
influential_summary

write.csv(
  influential_summary,
  "outputs/injury_top5_influential.csv",
  row.names = FALSE
)

# Cook's distance interpretation:
# The five most influential players were rows 238, 281,
# 546, 169 and 101.
#
# All five players were injured despite having relatively
# low predicted injury probabilities.
#
# Players 238 and 281 have identical predictor values.
# The five players also appeared among those with large
# standardised deviance residuals.
#
# We will investigate their influence by refitting the
# model without these five observations.
# No observations are permanently deleted.

# ==========================================
# SECTION 5: REFIT WITHOUT THE FIVE MOST INFLUENTIAL PLAYERS
# ==========================================

injury_model_reduced <- glm(
  injured ~ age + training_load + prev_injuries,
  data = players,
  family = binomial,
  subset = -top5_influential
)
summary(injury_model_reduced)

nobs(injury_model)
nobs(injury_model_reduced)

# Odds ratios and 95% profile likelihood CIs
original_or <- exp(coef(injury_model))
original_ci <- exp(confint(injury_model))

reduced_or <- exp(coef(injury_model_reduced))
reduced_ci <- exp(confint(injury_model_reduced))

influence_comparison <- data.frame(
  variable = names(original_or),

  OR_original = original_or,
  CI_lower_original = original_ci[, 1],
  CI_upper_original = original_ci[, 2],

  OR_reduced = reduced_or,
  CI_lower_reduced = reduced_ci[, 1],
  CI_upper_reduced = reduced_ci[, 2]
)
influence_comparison

write.csv(
  influence_comparison,
  "outputs/injury_influence_comparison.csv",
  row.names = FALSE
)

# Influence analysis interpretation:
#
# The model was refitted after excluding the five most
# influential players using subset = -top5_influential.
#
# The original model contained 620 observations, while
# the reduced model contained 615 observations.
#
# All three predictor odds ratios remained above 1.
# Their 95% confidence intervals also remained entirely
# above 1 in both models.
#
# The estimated associations became somewhat stronger
# in the reduced model, particularly for training load.
#
# However, the overall conclusions did not change.
#
# Decision: Retain all 620 players. The five influential
# observations affect the estimated effect sizes but do
# not change the main conclusions.
#
# Caveat: the five removed players were all injured with low
# fitted probability, so removing them is bound to push the
# odds ratios up. This refit is a weak check on its own; the
# binned residual plot below is the better check of fit.

# ==========================================
# SECTION 6: BINNED RESIDUAL PLOT (added 22/11/2026)
# ==========================================

# With a binary response each residual can only take one of two
# values for a given fitted probability, so the plots above show
# two bands of points and |residual| > 2 mostly picks out injured
# low-risk players. Averaging the response residuals (y - p_hat)
# within bins of fitted probability gives a check that can
# actually show misfit: if the model is right, each bin's average
# is close to 0 and about 95% of bins fall inside
# +/- 2 * sqrt(p_bar * (1 - p_bar) / n_bin).

response_res <- players$injured - fitted_values

# About sqrt(620) ~ 25 bins of equal size, cut at quantiles of
# the fitted probability. Many players share the same predictor
# values (and so the same fitted value), so unique() removes any
# tied break points and some bins are larger than others.
n_bins <- floor(sqrt(n))
breaks <- unique(quantile(fitted_values,
                          probs = seq(0, 1, length.out = n_bins + 1)))
bin <- cut(fitted_values, breaks = breaks, include.lowest = TRUE)

binned <- data.frame(
  n_players     = as.vector(table(bin)),
  mean_fitted   = as.vector(tapply(fitted_values, bin, mean)),
  observed_rate = as.vector(tapply(players$injured, bin, mean)),
  mean_residual = as.vector(tapply(response_res, bin, mean))
)
binned$se <- sqrt(binned$mean_fitted * (1 - binned$mean_fitted) /
                    binned$n_players)
binned$outside_2se <- abs(binned$mean_residual) > 2 * binned$se
binned

nrow(binned)
sum(binned$outside_2se)
mean(binned$outside_2se)

write.csv(
  binned,
  "outputs/injury_binned_residuals.csv",
  row.names = FALSE
)

png("outputs/injury_binned_residuals.png",
    width = 1200, height = 800, res = 150)

# Order bins by fitted probability so the +/- 2 SE bands draw cleanly
ord <- order(binned$mean_fitted)
y_lim <- range(c(binned$mean_residual, 2 * binned$se, -2 * binned$se))
y_lim[2] <- y_lim[2] + 0.25 * diff(y_lim)  # headroom for the legend

plot(binned$mean_fitted, binned$mean_residual,
     ylim = y_lim,
     xlab = "Average fitted probability in bin",
     ylab = "Average residual (observed - fitted)",
     main = "Binned Residuals - Final Injury Model",
     pch = 19)
abline(h = 0, lty = 1)
lines(binned$mean_fitted[ord],  2 * binned$se[ord], lty = 2, col = "grey40")
lines(binned$mean_fitted[ord], -2 * binned$se[ord], lty = 2, col = "grey40")
legend("top", bty = "n", horiz = TRUE,
       legend = c("Bin average", "+/- 2 SE"),
       pch = c(19, NA), lty = c(NA, 2), col = c("black", "grey40"))

dev.off()

# Binned residual interpretation (draft from the run on 22/11/2026;
# Yousuf to check and reword):
# 24 bins of 21-30 players (fewer than 25 because of tied fitted
# values). 2 of the 24 bin averages (8%) lie outside +/- 2 SE,
# both at fitted probabilities below 0.10 and both positive
# (more injuries than predicted). About 1 in 20 would be expected
# by chance, so this is close to what a well-fitting model gives.
# There is no systematic curve: averages sit either side of 0
# across the whole range, so there is no sign that the logit link
# or the linear terms are wrong. The two highest-risk bins (fitted
# 0.44 and 0.53) are both above 0 but inside the bands.
# Conclusion: the binned residuals give no evidence of lack of fit,
# which agrees with Liha's grouped goodness-of-fit check in 05b.
