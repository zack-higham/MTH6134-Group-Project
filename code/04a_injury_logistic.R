# 04a_injury_logistic.R — Week 4: full logistic regression model for injury
# Author: Yousuf (Person 1). The model, the code and the comments below are his
# work, originally uploaded by him as `code/Statistical Modelling week4.R`
# (commit 8144dbc, 19/10/2026). His original version is preserved unchanged in
# the git history at that commit.
#
# Edit by Zack (19/10/2026) so it runs from the project folder and is picked up
# by run_all.R. No analysis was changed. Changes:
#   - renamed to 04a_injury_logistic.R, the agreed name for this task (rename
#     committed on its own, so the history shows it is the same file);
#   - added source("code/00_load_data.R") at the top (the original read from an
#     object `league_players` that is never created, so it stopped at line 5);
#   - replaced `league_players` with `players` throughout, the name the loader
#     uses. Nothing else in the code was altered;
#   - added SECTION 5 at the end: drop1() likelihood ratio tests and a written
#     interpretation of each term, which the week 4 task asked for. It uses only
#     Yousuf's fitted model m_full. Marked [Zack] so it isn't mistaken for his
#     text; Yousuf to review and reword in his own words.
# Note: 00_load_data.R already makes GK the baseline position, so the first
# and second fits of m_full below give identical results.

source("code/00_load_data.R")

# ============================================================================
# Yousuf's original code (unchanged apart from league_players -> players)
# ============================================================================

# Week 4 person 1
# Full logisitc regression model for injury

# Check the data set
names(players)
head(players)
str(players)

# Check the injury outcome
table(players$injured, useNA = "ifany")

# Check for missing values in the model variables
colSums(is.na(players[, c(
  "injured", "position", "age", "minutes_played",
  "training_load", "prev_injuries", "bmi"
)]))


# Rescale minutes played to units of 1,000
players$minutes_per_1000 <-
  players$minutes_played / 1000

# Fit the full logistic regression model
m_full <- glm(
  injured ~ position + age + minutes_per_1000 +
    training_load + prev_injuries + bmi,
  data = players,
  family = binomial(link = "logit")
)

# Display the model results
summary(m_full)


# Set goalkeeper (GK) as the reference category
players$position <- relevel(
  factor(players$position),
  ref = "GK"
)

# Refit the full model
players$minutes_per_1000 <-
  players$minutes_played / 1000

m_full <- glm(
  injured ~ position + age + minutes_per_1000 +
    training_load + prev_injuries + bmi,
  data = players,
  family = binomial(link = "logit")
)

summary(m_full)


# Calculate odds ratios and 95% confidence intervals

or_ci <- exp(cbind(
  OR = coef(m_full),
  confint(m_full)
))

# Create a table with clear column names
or_table <- data.frame(
  term = rownames(or_ci),
  OR = or_ci[, 1],
  lower_95 = or_ci[, 2],
  upper_95 = or_ci[, 3],
  row.names = NULL
)

# Display the table in R
print(or_table)

# Save the table to the outputs folder
write.csv(
  or_table,
  "outputs/injury_full_odds_ratios.csv",
  row.names = FALSE
)


# Test the contribution of each term in the model
anova(m_full, test = "Chisq")


# Refit the same model with predictors in a different order
m_reordered <- glm(
  injured ~ prev_injuries + training_load + age +
    bmi + minutes_per_1000 + position,
  data = players,
  family = binomial(link = "logit")
)

# Test terms sequentially in the new order
anova(m_reordered, test = "Chisq")



# 1. Raw injury rate by position
aggregate(injured ~ position, data = players, FUN = mean)

# 2. Raw injury rate by number of previous injuries
aggregate(injured ~ prev_injuries, data = players, FUN = mean)

# 3. Summarise training load into low, medium and high groups
players$load_group <- cut(
  players$training_load,
  breaks = quantile(
    players$training_load,
    probs = c(0, 1/3, 2/3, 1),
    na.rm = TRUE
  ),
  include.lowest = TRUE,
  labels = c("Low", "Medium", "High")
)

aggregate(injured ~ load_group, data = players, FUN = mean)


# ============================================================================
# SECTION 5 [Zack, 19/10/2026]: term-by-term tests and interpretation
# Uses Yousuf's m_full only. Yousuf to review and reword.
# ============================================================================

# anova() above tests terms sequentially, so each p-value depends on the order
# (position: p = 0.25 when entered first, p = 0.51 when entered last).
# drop1() tests each term given all the others, so it doesn't depend on order.
drop1(m_full, test = "Chisq")

# Interpretation of the full model (odds ratios with 95% profile CIs, and
# drop1 likelihood ratio test p-values). Each is "holding the other terms fixed":
# - prev_injuries: each extra injury in the prior three seasons is associated
#   with the odds of injury being multiplied by 1.66 (95% CI 1.39 to 1.99),
#   p < 0.001. Strong evidence of association; the largest effect in the model.
# - age: each extra year is associated with the odds being multiplied by 1.11
#   (95% CI 1.05 to 1.18), p < 0.001. Strong evidence.
# - training_load: each one-point rise in weekly load (1-5) is associated with
#   the odds being multiplied by 1.35 (95% CI 1.08 to 1.69), p = 0.008.
# - minutes_per_1000: OR 1.01 per 1,000 minutes (95% CI 0.70 to 1.45),
#   p = 0.96. No evidence that playing time is associated with injury.
# - bmi: OR 0.96 per unit (95% CI 0.83 to 1.11), p = 0.58. No evidence.
# - position (vs GK): DEF OR 0.56 (0.27 to 1.20), MID 0.65 (0.30 to 1.44),
#   FWD 0.59 (0.25 to 1.42); joint test on 3 df p = 0.51. Goalkeepers have the
#   highest raw injury rate (27%), but once the other variables are accounted
#   for there is no evidence of a position effect, and every CI includes 1.
# - Intercept: log-odds for a GK aged 0 with zero load, minutes, injuries and
#   bmi; not meaningful in context, so not interpreted.
# Conclusion: prev_injuries, age and training_load are associated with injury
# risk; minutes, bmi and position are candidates to drop. This matches the
# final model selected in 04b (Liha): injured ~ age + training_load + prev_injuries.
