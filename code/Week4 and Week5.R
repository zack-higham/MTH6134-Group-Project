source("code/00_load_data.R")

injury_model <- glm(
  injured ~ age + training_load + prev_injuries,
  data = league_players,
  family = binomial
)
summary(injury_model)

nobs(injury_model)
length(coef(injury_model))

# Calculate standardised deviance residuals

dev_res <- rstandard(injury_model)

# Calculate Pearson residuals

pearson_res <- residuals(injury_model, type = "pearson")
# Extract fitted values

fitted_values <- fitted(injury_model)

head(dev_res)
head(pearson_res)
head(fitted_values)
dir.exists("outputs")
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

# Reset plotting layout
par(mfrow = c(1, 1))
file.exists("outputs/injury_final_residuals.png")

# Identify players with large standardised deviance residuals

unusual_players <- which(abs(dev_res) > 2)

# Display their row numbers
unusual_players

# Display their residual values
dev_res[unusual_players]

# Display unusual players and their characteristics

league_players[unusual_players, ]

# Create summary table of unusual players

unusual_summary <- data.frame(
  player_row = unusual_players,
  injured = league_players$injured[unusual_players],
  age = league_players$age[unusual_players],
  training_load = league_players$training_load[unusual_players],
  prev_injuries = league_players$prev_injuries[unusual_players],
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

# Calculate leverage values

write.csv(
        unusual_summary,
        "outputs/injury_unusual_players.csv",
        row.names = FALSE
    )

leverage <- hatvalues(injury_model)

# Calculate average leverage
p <- length(coef(injury_model))
n <- nobs(injury_model)

average_leverage <- p / n

average_leverage

# Identify players with leverage above 2p/n

high_leverage <- which(leverage > 2 * average_leverage)

# Display high leverage players
high_leverage

# Display their leverage values
leverage[high_leverage]

# Create table of players with high leverage

high_leverage_summary <- data.frame(
  player_row = high_leverage,
  age = league_players$age[high_leverage],
  training_load = league_players$training_load[high_leverage],
  prev_injuries = league_players$prev_injuries[high_leverage],
  leverage = leverage[high_leverage]
)

# Sort from highest to lowest leverage
high_leverage_summary <- high_leverage_summary[
  order(-high_leverage_summary$leverage), ]

# Display the 10 highest leverage players
head(high_leverage_summary, 10)

write.csv(
  high_leverage_summary,
  "outputs/injury_high_leverage.csv",
  row.names = FALSE
)

# Calculate Cook's distance

cooks <- cooks.distance(injury_model)

# Save Cook's distance plot

png("outputs/injury_final_cooks.png",
    width = 1200,
    height = 800)

plot(cooks,
     type = "h",
     main = "Cook's Distance – Final Injury Model",
     xlab = "Player (row number)",
     ylab = "Cook's Distance")

dev.off()

# Identify five most influential players

top5_influential <- order(cooks, decreasing = TRUE)[1:5]

# Display their Cook's distances
top5_influential
cooks[top5_influential]

# Create table of five most influential players

influential_summary <- data.frame(
  player_row = top5_influential,
  injured = league_players$injured[top5_influential],
  age = league_players$age[top5_influential],
  training_load = league_players$training_load[top5_influential],
  prev_injuries = league_players$prev_injuries[top5_influential],
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

# Refit injury model without five influential players

injury_model_reduced <- glm(
  injured ~ age + training_load + prev_injuries,
  data = league_players,
  family = binomial,
  subset = -top5_influential
)

# View new model results
summary(injury_model_reduced)

nobs(injury_model)
nobs(injury_model_reduced)

# Extract odds ratios and confidence intervals

# Original model
original_or <- exp(coef(injury_model))
original_ci <- exp(confint(injury_model))

# Reduced model
reduced_or <- exp(coef(injury_model_reduced))
reduced_ci <- exp(confint(injury_model_reduced))

# Create comparison table
influence_comparison <- data.frame(
  variable = names(original_or),
  
  OR_original = original_or,
  CI_lower_original = original_ci[, 1],
  CI_upper_original = original_ci[, 2],
  
  OR_reduced = reduced_or,
  CI_lower_reduced = reduced_ci[, 1],
  CI_upper_reduced = reduced_ci[, 2]
)

# Display comparison
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

head(high_leverage_summary, 10)

list.files("outputs")

# week 5 
# ==========================================
# SECTION 2: POSITION x INJURY TABLE
# ==========================================

# Create contingency table
tab <- as.data.frame(
  xtabs(~ position + injured, data = league_players)
)

# View table
print(tab)

# Save table
write.csv(
  tab,
  "outputs/table_position_injured.csv",
  row.names = FALSE
)

# ==========================================
# SECTION 3: CHI-SQUARED TEST
# ==========================================

# Run chi-squared test
chi_result <- chisq.test(
  xtabs(~ position + injured, data = league_players),
  correct = FALSE
)

# Display test results
print(chi_result)

# Display expected counts
print(chi_result$expected)

# Save expected counts
write.csv(
  chi_result$expected,
  "outputs/expected_counts_position_injured.csv"
)

# Fit logistic regression
logistic_model <- glm(
  cbind(injured, not_injured) ~ position,
  family = binomial,
  data = injury_counts
)

# View model results
summary(logistic_model)

# Calculate odds ratios
exp(coef(logistic_model))

# ==========================================
# SECTION 5: LOGISTIC VS LOG-LINEAR MODEL
# ==========================================

# Create the contingency table as a dataframe
loglinear_tab <- as.data.frame(
  xtabs(~ position + injured, data = league_players)
)

# Make sure injury is an unordered factor
loglinear_tab$injured <- factor(
  loglinear_tab$injured,
  ordered = FALSE
)

# Fit Poisson log-linear model
loglinear_model <- glm(
  Freq ~ position * injured,
  family = poisson,
  data = loglinear_tab
)

# View model results
summary(loglinear_model)

Freq ~ position * injured
levels(injury_counts$position)
levels(loglinear_tab$position)
levels(loglinear_tab$injured)

# Logistic regression coefficients
coef(logistic_model)

# Log-linear model coefficients
coef(loglinear_model)

# Logistic regression: compare with intercept-only model
logistic_null <- glm(
  cbind(injured, not_injured) ~ 1,
  family = binomial,
  data = injury_counts
)

logistic_lrt <- anova(
  logistic_null,
  logistic_model,
  test = "Chisq"
)

print(logistic_lrt)

# Log-linear model: compare with independence model
loglinear_null <- glm(
  Freq ~ position + injured,
  family = poisson,
  data = loglinear_tab
)

loglinear_lrt <- anova(
  loglinear_null,
  loglinear_model,
  test = "Chisq"
)

print(loglinear_lrt)

# ==========================================
# SECTION 6: PARTIAL TABLES
# ==========================================

# Create previous injury bands
league_players$prev_band <- cut(
  league_players$prev_injuries,
  breaks = c(-Inf, 0, 1, Inf),
  labels = c("0", "1", "2+")
)

# Make sure bands are unordered factors
league_players$prev_band <- factor(
  league_players$prev_band,
  levels = c("0", "1", "2+"),
  ordered = FALSE
)

# Check the number of players in each band
table(league_players$prev_band)

# Create three-way contingency table
partial_tab <- as.data.frame(
  xtabs(
    ~ position + prev_band + injured,
    data = league_players
  )
)

# Save the table
write.csv(
  partial_tab,
  "outputs/table_position_injured_by_prev_band.csv",
  row.names = FALSE
)

# View table
print(partial_tab)

# Previous injuries = 0
subset(partial_tab, prev_band == "0")

# Previous injuries = 1
subset(partial_tab, prev_band == "1")

# Previous injuries = 2+
subset(partial_tab, prev_band == "2+")

# Fit saturated three-way model
partial_model <- glm(
  Freq ~ position * prev_band * injured,
  family = poisson,
  data = partial_tab
)

# View model summary
summary(partial_model)

# Test which terms can be removed
drop1(partial_model, test = "Chisq")

table(league_players$prev_band)

print(partial_tab)

drop1(partial_model, test = "Chisq")

# Remove three-way interaction
partial_model_2 <- glm(
  Freq ~ position * prev_band +
    position * injured +
    prev_band * injured,
  family = poisson,
  data = partial_tab
)

# Test remaining terms
drop1(partial_model_2, test = "Chisq")

# Model without the three-way interaction
partial_model_2 <- glm(
  Freq ~ position * prev_band +
    position * injured +
    prev_band * injured,
  family = poisson,
  data = partial_tab
)

# Test remaining terms
drop1(partial_model_2, test = "Chisq")

drop1(partial_model_2, test = "Chisq")

# Remove position:injured interaction
partial_model_3 <- glm(
  Freq ~ position + prev_band + injured +
    position:prev_band +
    prev_band:injured,
  family = poisson,
  data = partial_tab
)

# Test remaining terms
drop1(partial_model_3, test = "Chisq")

str(league_players$injured)
table(league_players$injured, useNA = "ifany")
levels(factor(league_players$position))

league_players$position <- relevel(
  factor(league_players$position),
  ref = "GK"
)

marginal_model <- glm(
  injured ~ position,
  family = binomial,
  data = league_players
)

summary(marginal_model)

marginal_OR <- exp(coef(marginal_model))
marginal_CI <- exp(confint(marginal_model))

marginal_results <- data.frame(
  OR = marginal_OR,
  CI_lower = marginal_CI[, 1],
  CI_upper = marginal_CI[, 2]
)

print(marginal_results)

write.csv(
  marginal_results,
  "outputs/marginal_position_odds_ratios.csv"
)

partial_OR_results <- data.frame()

for (band in c("0", "1", "2+")) {
  
  band_data <- subset(league_players, prev_band == band)
  
  band_model <- glm(
    injured ~ position,
    family = binomial,
    data = band_data
  )
  
  band_OR <- exp(coef(band_model))
  band_CI <- exp(confint(band_model))
  
  band_results <- data.frame(
    prev_band = band,
    position = names(band_OR),
    OR = as.numeric(band_OR),
    CI_lower = band_CI[, 1],
    CI_upper = band_CI[, 2]
  )
  
  partial_OR_results <- rbind(
    partial_OR_results,
    band_results
  )
}

print(partial_OR_results)

write.csv(
  partial_OR_results,
  "outputs/partial_position_odds_ratios.csv",
  row.names = FALSE
)

comparison_results <- merge(
  marginal_results,
  partial_OR_results,
  by.x = "row.names",
  by.y = "position",
  all = FALSE
)

print(comparison_results)

print(marginal_results)
print(partial_OR_results)

print(marginal_results)

