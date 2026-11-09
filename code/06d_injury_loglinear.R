# 06d_injury_loglinear.R — Week 6: three-way injury log-linear model
# Person 4 (Liri)
#
# Question: how are previous injuries, training load and current injury related
# after grouping the two predictors into the bands agreed by the group?
# Base R only. Run from the project root.

source("code/00_load_data.R")

# =============================================================================
# 1. AGREED BANDS AND THE 3 x 2 x 2 TABLE
# =============================================================================

# Create bands locally; do not change the shared data loader.
players$prev_band <- cut(
  players$prev_injuries,
  breaks = c(-Inf, 0, 1, Inf),
  labels = c("0", "1", "2+")
)
players$prev_band <- factor(players$prev_band,
                            levels = c("0", "1", "2+"),
                            ordered = FALSE)

players$load_band <- factor(
  ifelse(players$training_load <= 3, "1-3", "4-5"),
  levels = c("1-3", "4-5"),
  ordered = FALSE
)

# Injury is the response. Use an unordered factor so the coefficients use
# ordinary baseline comparisons rather than polynomial contrasts.
players$injured_f <- factor(players$injured, levels = c(0, 1),
                            ordered = FALSE)

table_data <- as.data.frame(
  xtabs(~ prev_band + load_band + injured_f, data = players)
)
names(table_data)[names(table_data) == "injured_f"] <- "injured"
print(table_data)
stopifnot(nrow(table_data) == 12, sum(table_data$Freq) == nrow(players))

write.csv(table_data, "outputs/table_prev_load_injured.csv", row.names = FALSE)

# Use an unordered factor in the models after renaming the table column.
table_data$injured <- factor(table_data$injured, levels = c("0", "1"),
                             ordered = FALSE)

# =============================================================================
# 2. LOG-LINEAR MODEL SELECTION
# =============================================================================

# Saturated model: all main effects, all two-way interactions and the
# three-way interaction. It reproduces every observed cell exactly.
m_sat <- glm(
  Freq ~ prev_band * load_band * injured,
  family = poisson,
  data = table_data
)

# Test the three-way interaction first.
m_2way <- glm(
  Freq ~ prev_band * load_band +
    prev_band * injured +
    load_band * injured,
  family = poisson,
  data = table_data
)
lrt_three_way <- anova(m_2way, m_sat, test = "Chisq")
print(lrt_three_way)

# From the all-two-way model, test each two-way term. prev_band:load_band must
# remain when injured is treated as the response because the explanatory
# margin is fixed, but its LRT is still reported to describe their association.
drop_two_way <- drop1(m_2way, test = "Chisq")
print(drop_two_way)

# Conditional-independence tests requested in the task.
# H0: injured is independent of load given previous injuries.
m_no_injury_load <- glm(
  Freq ~ prev_band * load_band + prev_band * injured,
  family = poisson,
  data = table_data
)
test_injury_load_given_prev <- anova(
  m_no_injury_load, m_2way, test = "Chisq"
)

# H0: injured is independent of previous injuries given load.
m_no_injury_prev <- glm(
  Freq ~ prev_band * load_band + load_band * injured,
  family = poisson,
  data = table_data
)
test_injury_prev_given_load <- anova(
  m_no_injury_prev, m_2way, test = "Chisq"
)

print(test_injury_load_given_prev)
print(test_injury_prev_given_load)

model_tests <- data.frame(
  test = c(
    "three-way prev_band:load_band:injured",
    "prev_band:load_band in all-two-way model",
    "injured:load_band given prev_band",
    "injured:prev_band given load_band"
  ),
  deviance = c(
    lrt_three_way$Deviance[2],
    drop_two_way["prev_band:load_band", "LRT"],
    test_injury_load_given_prev$Deviance[2],
    test_injury_prev_given_load$Deviance[2]
  ),
  df = c(
    lrt_three_way$Df[2],
    drop_two_way["prev_band:load_band", "Df"],
    test_injury_load_given_prev$Df[2],
    test_injury_prev_given_load$Df[2]
  ),
  p_value = c(
    lrt_three_way[2, "Pr(>Chi)"],
    drop_two_way["prev_band:load_band", "Pr(>Chi)"],
    test_injury_load_given_prev[2, "Pr(>Chi)"],
    test_injury_prev_given_load[2, "Pr(>Chi)"]
  )
)
print(model_tests)
write.csv(model_tests, "outputs/injury_loglinear_tests.csv", row.names = FALSE)

# The final model is chosen after the tests above. Both response interactions
# are retained if their conditional-independence tests reject at 5%; the
# three-way interaction is retained only if its LRT rejects at 5%.
keep_three_way <- model_tests$p_value[1] < 0.05
keep_injury_load <- model_tests$p_value[3] < 0.05
keep_injury_prev <- model_tests$p_value[4] < 0.05

if (keep_three_way) {
  m_final <- m_sat
} else if (keep_injury_load && keep_injury_prev) {
  m_final <- m_2way
} else if (keep_injury_prev) {
  m_final <- m_no_injury_load
} else if (keep_injury_load) {
  m_final <- m_no_injury_prev
} else {
  m_final <- glm(Freq ~ prev_band * load_band + injured,
                 family = poisson, data = table_data)
}

cat("\nFinal log-linear formula:\n")
print(formula(m_final))
cat("Residual deviance:", round(deviance(m_final), 3),
    "on", df.residual(m_final), "df; p =",
    signif(pchisq(deviance(m_final), df.residual(m_final),
                  lower.tail = FALSE), 3), "\n")

obs_fit <- table_data
obs_fit$fitted <- fitted(m_final)
obs_fit$pearson_residual <- residuals(m_final, type = "pearson")
obs_fit$deviance_residual <- residuals(m_final, type = "deviance")
print(obs_fit)
write.csv(obs_fit, "outputs/loglinear_obs_vs_fitted.csv", row.names = FALSE)

# =============================================================================
# 3. EQUIVALENT GROUPED BINOMIAL MODEL
# =============================================================================

# Collapse the table into the six prev_band x load_band groups.
grouped <- aggregate(Freq ~ prev_band + load_band, data = table_data, FUN = sum)
injured_counts <- subset(table_data, injured == "1",
                         select = c(prev_band, load_band, Freq))
names(injured_counts)[3] <- "injured"
grouped <- merge(grouped, injured_counts, by = c("prev_band", "load_band"))
names(grouped)[names(grouped) == "Freq"] <- "n"
grouped$not_injured <- grouped$n - grouped$injured

m_bin_full <- glm(
  cbind(injured, not_injured) ~ prev_band * load_band,
  family = binomial,
  data = grouped
)
m_bin_add <- glm(
  cbind(injured, not_injured) ~ prev_band + load_band,
  family = binomial,
  data = grouped
)
lrt_bin_interaction <- anova(m_bin_add, m_bin_full, test = "Chisq")
print(lrt_bin_interaction)

if (keep_three_way) {
  m_bin_final <- m_bin_full
} else if (keep_injury_load && keep_injury_prev) {
  m_bin_final <- m_bin_add
} else if (keep_injury_prev) {
  m_bin_final <- glm(cbind(injured, not_injured) ~ prev_band,
                     family = binomial, data = grouped)
} else if (keep_injury_load) {
  m_bin_final <- glm(cbind(injured, not_injured) ~ load_band,
                     family = binomial, data = grouped)
} else {
  m_bin_final <- glm(cbind(injured, not_injured) ~ 1,
                     family = binomial, data = grouped)
}

# Match each binomial coefficient to the corresponding injured term in the
# log-linear model. The remaining log-linear terms reproduce the fixed
# prev_band x load_band margins and have no binomial counterpart.
bin_terms <- names(coef(m_bin_final))
ll_terms <- c(
  "injured1",
  if ("prev_band1" %in% bin_terms) "prev_band1:injured1" else NULL,
  if ("prev_band2+" %in% bin_terms) "prev_band2+:injured1" else NULL,
  if ("load_band4-5" %in% bin_terms) "load_band4-5:injured1" else NULL,
  if ("prev_band1:load_band4-5" %in% bin_terms)
    "prev_band1:load_band4-5:injured1" else NULL,
  if ("prev_band2+:load_band4-5" %in% bin_terms)
    "prev_band2+:load_band4-5:injured1" else NULL
)

equivalence <- data.frame(
  binomial_term = bin_terms,
  loglinear_term = ll_terms,
  binomial_estimate = unname(coef(m_bin_final)[bin_terms]),
  loglinear_estimate = unname(coef(m_final)[ll_terms]),
  absolute_difference = unname(abs(
    coef(m_bin_final)[bin_terms] - coef(m_final)[ll_terms]
  )),
  row.names = NULL
)
print(equivalence)
write.csv(equivalence, "outputs/loglinear_binomial_equivalence.csv",
          row.names = FALSE)

# Odds ratios and 95% profile-likelihood CIs from the equivalent binomial model.
bin_ci <- suppressMessages(confint(m_bin_final))
or_final <- data.frame(
  term = names(coef(m_bin_final)),
  odds_ratio = unname(exp(coef(m_bin_final))),
  lower_95 = unname(exp(bin_ci[, 1])),
  upper_95 = unname(exp(bin_ci[, 2])),
  row.names = NULL
)
print(or_final)
write.csv(or_final, "outputs/injury_loglinear_odds_ratios.csv",
          row.names = FALSE)

# =============================================================================
# 4. COLLAPSIBILITY: MARGINAL V CONDITIONAL ODDS RATIOS
# =============================================================================

# Marginal models collapse over the other predictor. Conditional ORs come from
# the joint grouped model above. Similarity is checked numerically; equality is
# not assumed merely because the week 2 numeric correlation was small.
m_prev_marginal <- glm(injured ~ prev_band, family = binomial, data = players)
m_load_marginal <- glm(injured ~ load_band, family = binomial, data = players)

marginal_models <- list(prev = m_prev_marginal, load = m_load_marginal)
marginal_terms <- c("prev_band1", "prev_band2+", "load_band4-5")
marginal_est <- c(coef(m_prev_marginal)[c("prev_band1", "prev_band2+")],
                  coef(m_load_marginal)["load_band4-5"])
conditional_est <- coef(m_bin_add)[marginal_terms]

collapsibility <- data.frame(
  comparison = c("prev 1 v 0", "prev 2+ v 0", "load 4-5 v 1-3"),
  marginal_OR = unname(exp(marginal_est)),
  conditional_OR = unname(exp(conditional_est)),
  ratio_marginal_to_conditional = unname(exp(marginal_est) /
                                           exp(conditional_est)),
  row.names = NULL
)
print(collapsibility)
write.csv(collapsibility,
          "outputs/injury_marginal_vs_conditional_or.csv",
          row.names = FALSE)

# Directly test association between the two explanatory bands.
predictor_table <- xtabs(~ prev_band + load_band, data = players)
predictor_chisq <- chisq.test(predictor_table, correct = FALSE)
print(predictor_table)
print(predictor_chisq)
print(predictor_chisq$expected)

# =============================================================================
# 5. COMPARE WITH A BANDED VERSION OF THE 04b MODEL
# =============================================================================

# 04b retained age, training_load and prev_injuries as numeric predictors.
# This sensitivity model uses the agreed bands but keeps age, allowing a direct
# comparison with the table model, which cannot adjust for age.
m_04b_banded <- glm(
  injured ~ age + prev_band + load_band,
  family = binomial,
  data = players
)

band_terms <- c("prev_band1", "prev_band2+", "load_band4-5")
ci_04b_banded <- suppressMessages(confint(m_04b_banded))[band_terms, , drop = FALSE]
comparison_04b <- data.frame(
  term = band_terms,
  table_model_OR = unname(exp(coef(m_bin_add)[band_terms])),
  banded_04b_age_adjusted_OR = unname(exp(coef(m_04b_banded)[band_terms])),
  banded_04b_lower_95 = unname(exp(ci_04b_banded[, 1])),
  banded_04b_upper_95 = unname(exp(ci_04b_banded[, 2])),
  row.names = NULL
)
print(comparison_04b)
write.csv(comparison_04b, "outputs/injury_banded_04b_comparison.csv",
          row.names = FALSE)

# =============================================================================
# 6. INDEPENDENCE GRAPH
# =============================================================================

# The graph displays which pairwise interactions are retained. An edge means
# the model does not assert conditional independence for that pair.
nodes <- data.frame(
  name = c("Previous\ninjuries", "Training\nload", "Injured"),
  x = c(0.20, 0.80, 0.50),
  y = c(0.20, 0.20, 0.78)
)

png("outputs/independence_graph_injury.png",
    width = 900, height = 750, res = 130)
plot(NA, xlim = c(0, 1), ylim = c(0, 1), axes = FALSE,
     xlab = "", ylab = "", asp = 1,
     main = "Independence graph: injury table final model")

# prev_band:load_band is kept to reproduce the fixed explanatory margin.
segments(nodes$x[1], nodes$y[1], nodes$x[2], nodes$y[2], lwd = 2)
if (keep_injury_prev) {
  segments(nodes$x[1], nodes$y[1], nodes$x[3], nodes$y[3], lwd = 2)
}
if (keep_injury_load) {
  segments(nodes$x[2], nodes$y[2], nodes$x[3], nodes$y[3], lwd = 2)
}

points(nodes$x, nodes$y, pch = 21, bg = "white", cex = 7, lwd = 2)
text(nodes$x, nodes$y, labels = nodes$name, cex = 0.78)
if (!keep_three_way && keep_injury_prev && keep_injury_load) {
  mtext("All pairwise interactions retained; three-way interaction omitted",
        side = 1, line = -1, cex = 0.85)
}
dev.off()

# =============================================================================
# SUMMARY
# =============================================================================
# - The three-way interaction is not needed (G2 = 2.59, 2 df, p = 0.274).
# - Injury is associated with training-load band given previous injuries
#   (G2 = 11.39, 1 df, p < 0.001), and with previous-injury band given load
#   (G2 = 29.19, 2 df, p < 0.001). Both response interactions are retained.
# - prev_band:load_band is weak (G2 = 0.44, 2 df, p = 0.803) but remains in
#   the log-linear model because the explanatory-variable margin is fixed.
# - The final all-two-way model fits adequately (G2 = 2.59, 2 df, p = 0.274).
# - Conditional ORs: previous injuries 1 v 0 = 2.00; 2+ v 0 = 3.91;
#   training load 4-5 v 1-3 = 2.07. All profile-likelihood 95% CIs exclude 1.
# - The equivalent grouped binomial estimates match the injury interactions
#   in the log-linear model to numerical precision.

