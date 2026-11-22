# 08a_position_injury_table.R — Yousuf
# Position x injury contingency table (week 8): chi-squared test, grouped
# logistic v log-linear model, three-way table with previous-injury band, and
# marginal v partial (within-band) position odds ratios.
#
# Split from code/drafts/Week4 and Week5.R (Part 2, 09/11/2026), which didn't
# run from a fresh session. Changes (22/11/2026):
#   - source the data loader; use `players` (from 00_load_data.R), not
#     `league_players`;
#   - create `injury_counts` (injured / not injured by position) before the
#     grouped logistic model, which used it without creating it;
#   - removed repeated model fits and repeated print()/drop1() calls, and a
#     stray formula line; the analysis is unchanged.
# 00_load_data.R already makes GK the first (baseline) position level.

source("code/00_load_data.R")

# ==========================================
# SECTION 1: POSITION x INJURY TABLE
# ==========================================

# Create contingency table
tab <- as.data.frame(
  xtabs(~ position + injured, data = players)
)
print(tab)

write.csv(
  tab,
  "outputs/table_position_injured.csv",
  row.names = FALSE
)

# ==========================================
# SECTION 2: CHI-SQUARED TEST
# ==========================================

chi_result <- chisq.test(
  xtabs(~ position + injured, data = players),
  correct = FALSE
)
print(chi_result)

# Expected counts
print(chi_result$expected)

write.csv(
  chi_result$expected,
  "outputs/expected_counts_position_injured.csv"
)

# ==========================================
# SECTION 3: GROUPED LOGISTIC REGRESSION
# ==========================================

# Injured and not-injured counts for each position
injury_counts <- aggregate(injured ~ position, data = players, FUN = sum)
injury_counts$n <- as.vector(table(players$position))
injury_counts$not_injured <- injury_counts$n - injury_counts$injured
injury_counts

logistic_model <- glm(
  cbind(injured, not_injured) ~ position,
  family = binomial,
  data = injury_counts
)
summary(logistic_model)

# Odds ratios
exp(coef(logistic_model))

# ==========================================
# SECTION 4: LOGISTIC VS LOG-LINEAR MODEL
# ==========================================

loglinear_tab <- as.data.frame(
  xtabs(~ position + injured, data = players)
)

# Make sure injury is an unordered factor
loglinear_tab$injured <- factor(
  loglinear_tab$injured,
  ordered = FALSE
)

# Saturated Poisson log-linear model
loglinear_model <- glm(
  Freq ~ position * injured,
  family = poisson,
  data = loglinear_tab
)
summary(loglinear_model)

levels(injury_counts$position)
levels(loglinear_tab$position)
levels(loglinear_tab$injured)

# Logistic coefficients match the position:injured1 terms of the
# log-linear model (and the intercept matches injured1)
coef(logistic_model)
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
# SECTION 5: PARTIAL TABLES
# ==========================================

# Previous injury bands
players$prev_band <- cut(
  players$prev_injuries,
  breaks = c(-Inf, 0, 1, Inf),
  labels = c("0", "1", "2+")
)

# Make sure bands are unordered factors
players$prev_band <- factor(
  players$prev_band,
  levels = c("0", "1", "2+"),
  ordered = FALSE
)

# Number of players in each band
table(players$prev_band)

# Three-way contingency table
partial_tab <- as.data.frame(
  xtabs(
    ~ position + prev_band + injured,
    data = players
  )
)

write.csv(
  partial_tab,
  "outputs/table_position_injured_by_prev_band.csv",
  row.names = FALSE
)
print(partial_tab)

# Partial tables for each band
subset(partial_tab, prev_band == "0")
subset(partial_tab, prev_band == "1")
subset(partial_tab, prev_band == "2+")

# Saturated three-way model
partial_model <- glm(
  Freq ~ position * prev_band * injured,
  family = poisson,
  data = partial_tab
)
summary(partial_model)

# Test which terms can be removed
drop1(partial_model, test = "Chisq")

# Remove three-way interaction
partial_model_2 <- glm(
  Freq ~ position * prev_band +
    position * injured +
    prev_band * injured,
  family = poisson,
  data = partial_tab
)
drop1(partial_model_2, test = "Chisq")

# Remove position:injured interaction
partial_model_3 <- glm(
  Freq ~ position + prev_band + injured +
    position:prev_band +
    prev_band:injured,
  family = poisson,
  data = partial_tab
)
drop1(partial_model_3, test = "Chisq")

# ==========================================
# SECTION 6: MARGINAL V PARTIAL POSITION ODDS RATIOS
# ==========================================

str(players$injured)
table(players$injured, useNA = "ifany")
levels(players$position)

# Marginal (ignoring previous injuries)
marginal_model <- glm(
  injured ~ position,
  family = binomial,
  data = players
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

# Partial (within each previous-injury band)
partial_OR_results <- data.frame()

for (band in c("0", "1", "2+")) {

  band_data <- subset(players, prev_band == band)

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

# Marginal and partial ORs side by side
comparison_results <- merge(
  marginal_results,
  partial_OR_results,
  by.x = "row.names",
  by.y = "position",
  all = FALSE
)
print(comparison_results)
