# 05e_goals_influence.R — Week 5: residuals and diagnostics
# Owner: Zack
# Question: how much does the 8-0 home win v the rank-24 side (row 8 of
# `matches`) drive the Poisson model for Ashford's goals scored?
#   Part 1: Poisson GLM for goals_scored (all 46 matches)
#   Part 2: goodness of fit and dispersion
#   Part 3: residuals (standardised deviance, Pearson) and QQ plot
#   Part 4: leverage and Cook's distance
#   Part 5: refit without the 8-0 match and compare
#   Part 6: leave-one-out check on every match (is the 8-0 unique?)
#   Part 7: quasipoisson sensitivity check
# Lecture references: week 4 slides 3-14 (GOF and diagnostics); week 5
# slides 3, 8-13 and 16-21 (Poisson, residuals, overdispersion).
# Base R only. Run from the project folder (open the .Rproj first).
# The data are NOT changed: every refit uses `subset =`, so all 46 matches
# stay in `matches` and both fits are kept below.

source("code/00_load_data.R")

row_8nil <- which(matches$home_away == "Home" & matches$goals_scored == 8)
row_8nil                      # should be 8
matches[row_8nil, ]

# =============================================================================
# PART 1: POISSON GLM FOR GOALS SCORED
# =============================================================================
# goals_scored is a count (0, 1, 2, ...), so a Poisson GLM with the canonical
# log link is appropriate: log(E(Y)) is linear in the predictors, so fitted
# means are always positive, and exp(coefficient) is a rate ratio, the
# multiplicative change in expected goals per match (week 5, slides 3, 16).
# Same predictors as 03b and 04e. No offset is needed: every observation is one
# 90-minute match, so the exposure is the same for every row.
m_goals <- glm(goals_scored ~ home_away + opponent_rank,
               family = poisson, data = matches)
summary(m_goals)

p_goals <- length(coef(m_goals))     # p = 3 parameters
n_goals <- nrow(matches)             # n = 46 matches

# Rate ratios with 95% profile-likelihood CIs (exponentiated from the log scale)
rr_table <- function(model) {
  est <- exp(cbind(RR = coef(model), confint(model)))
  data.frame(term = rownames(est),
             RR = round(est[, 1], 3),
             lower_95 = round(est[, 2], 3),
             upper_95 = round(est[, 3], 3),
             row.names = NULL)
}
goals_rr <- rr_table(m_goals)
goals_rr
write.csv(goals_rr, "outputs/goals_poisson_rate_ratios.csv", row.names = FALSE)

# Likelihood ratio test for each term given the other (order-independent)
goals_drop1 <- drop1(m_goals, test = "Chisq")
goals_drop1

# Interpretation (all 46 matches):
# - Away v home: expected goals multiplied by 0.50 (95% CI 0.29 to 0.84),
#   holding opponent rank fixed, i.e. about half as many goals away.
#   LRT = 6.80 on 1 df, p = 0.009: strong evidence of a home/away difference.
# - Each place lower in the table for the opponent (rank +1): expected goals
#   multiplied by 1.056 (95% CI 1.017 to 1.098). Over the full range (rank 1
#   to rank 24) this is exp(23 * 0.0543) = 3.5 times as many expected goals.
#   LRT = 8.26 on 1 df, p = 0.004: strong evidence of an association.

# =============================================================================
# PART 2: GOODNESS OF FIT AND DISPERSION
# =============================================================================
# Residual deviance v chi-squared on n - p df (week 4, slides 3-6).
dev_goals <- deviance(m_goals)
df_goals  <- df.residual(m_goals)
c(deviance = dev_goals, df = df_goals,
  p_value = 1 - pchisq(dev_goals, df_goals))
# 49.8 on 43 df, p = 0.22: no evidence of misfit. BUT the chi-squared
# approximation needs fitted counts above about 5 (week 4, slide 5), and here
# every fitted mean is between 0.43 and 3.0, so this p-value is a rough guide
# only. That is why the residuals and influence measures below matter more.
range(fitted(m_goals))

# Pearson dispersion: phi_hat = X^2 / residual df (week 5, slide 12)
pearson_X2 <- function(model) sum(residuals(model, type = "pearson")^2)
phi_goals  <- pearson_X2(m_goals) / df_goals
phi_goals
# phi_hat = 0.99, so no sign of overdispersion: the Poisson assumption
# variance = mean looks reasonable once home_away and opponent_rank are in the
# model (matches 03b).

# =============================================================================
# PART 3: RESIDUALS
# =============================================================================
# Standardised deviance residuals r'_i = r_i / sqrt(1 - h_i) (week 4, slide 9)
# and Pearson residuals (y_i - mu_i) / sqrt(V(mu_i)), with V(mu) = mu for the
# Poisson (week 4, slide 10). Both are roughly N(0, 1) if the model is right.
# Signs of misfit (week 4, slide 11): |r'| > 2 or 3, curvature, or funnelling.
diag_goals <- data.frame(
  match          = seq_len(n_goals),
  home_away      = matches$home_away,
  opponent_rank  = matches$opponent_rank,
  goals_scored   = matches$goals_scored,
  fitted         = round(fitted(m_goals), 3),
  std_dev_resid  = round(rstandard(m_goals), 3),
  pearson_resid  = round(residuals(m_goals, type = "pearson"), 3),
  leverage       = round(hatvalues(m_goals), 3),
  cooks_distance = round(cooks.distance(m_goals), 3)
)
write.csv(diag_goals, "outputs/goals_diagnostics_table.csv", row.names = FALSE)

# Matches with |standardised deviance residual| > 2
diag_goals[abs(diag_goals$std_dev_resid) > 2, ]
# Two matches:
# - match 8 (8-0 v rank 24, home): r' = +2.61, Pearson = +2.89. Ashford
#   scored 8 where the model expects 3.0. The largest residual, but below 3.
# - match 7 (0-0 v rank 18, home): r' = -2.15. Ashford scored 0 where the
#   model expects 2.2. Just over 2; with 46 matches about 2 values beyond +/-2
#   are expected by chance, so on its own this is not a concern.

col_ha <- ifelse(matches$home_away == "Home", "black", "red")

png("outputs/goals_residuals.png", width = 1000, height = 900)
par(mfrow = c(2, 2))
plot(fitted(m_goals), rstandard(m_goals), pch = 19, col = col_ha,
     xlab = "Fitted values (expected goals)",
     ylab = "Standardised deviance residuals",
     main = "Standardised deviance residuals v fitted")
abline(h = c(-2, 0, 2), lty = c(3, 2, 3))
text(fitted(m_goals)[row_8nil], rstandard(m_goals)[row_8nil], "8-0", pos = 2)
legend("bottomleft", legend = c("Home", "Away"), col = c("black", "red"), pch = 19)

plot(fitted(m_goals), residuals(m_goals, type = "pearson"), pch = 19, col = col_ha,
     xlab = "Fitted values (expected goals)", ylab = "Pearson residuals",
     main = "Pearson residuals v fitted")
abline(h = c(-2, 0, 2), lty = c(3, 2, 3))
text(fitted(m_goals)[row_8nil], residuals(m_goals, type = "pearson")[row_8nil],
     "8-0", pos = 2)

qq <- qqnorm(rstandard(m_goals), pch = 19,
             main = "Normal Q-Q plot, standardised deviance residuals")
qqline(rstandard(m_goals))
text(qq$x[row_8nil], qq$y[row_8nil], "8-0", pos = 2)

plot(matches$opponent_rank, rstandard(m_goals), pch = 19, col = col_ha,
     xlab = "Opponent final rank (1 = strongest)",
     ylab = "Standardised deviance residuals",
     main = "Standardised deviance residuals v opponent rank")
abline(h = c(-2, 0, 2), lty = c(3, 2, 3))
dev.off()
# Reading the plots:
# - No curvature against fitted values or opponent rank, so the log-linear
#   effect of opponent rank looks adequate.
# - No funnelling: the spread is similar across fitted values, consistent with
#   phi_hat = 0.99.
# - The residuals form diagonal stripes, one per observed goal count. This is
#   expected for small counts (0, 1, 2, 3 goals) and is not a sign of misfit.
# - The Q-Q plot follows the line only roughly: the middle points sit above it
#   and come in steps. This is the discreteness of small counts, not a clear
#   departure from normality; with counts this small the Q-Q plot is only
#   approximate (cf. week 4, slide 7 on residuals for sparse data). The 8-0 is
#   the largest residual but sits near the line, so on residual size alone it
#   is not an outlier. Its importance shows up in leverage and Cook's distance.

# =============================================================================
# PART 4: LEVERAGE AND COOK'S DISTANCE
# =============================================================================
# Leverage h_i: diagonal of the hat matrix. In a GLM it also depends on y
# through the IWLS weights, and the average leverage is p/n (week 4, slide 13).
h_goals   <- hatvalues(m_goals)
avg_lev   <- p_goals / n_goals            # 3/46 = 0.065
mean(h_goals)                             # equals p/n
# 2p/n is a common rule of thumb for "high" leverage (not from the lecture).
high_lev <- diag_goals[h_goals > 2 * avg_lev, ]
high_lev
# Two matches exceed 2p/n = 0.130: the 8-0 v rank 24 (h = 0.162, 2.5 times the
# average) and the 2-0 home win v rank 23 (h = 0.136). Both are home games v
# the weakest sides: they sit at the edge of the opponent_rank range and have
# the largest fitted means, so they get the most weight in the IWLS fit.

# Cook's distance (week 4, slide 14): how far the estimates move when match k
# is left out. The lecture gives no fixed cut-off, so look for values that
# stand out from the rest.
cd_goals <- cooks.distance(m_goals)
head(diag_goals[order(-cd_goals), ], 5)
cd_goals[row_8nil] / max(cd_goals[-row_8nil])
# The 8-0 has Cook's distance 0.64; the next largest is 0.08 (3-1 away win v
# rank 24). The 8-0 is about 8 times more influential than any other match,
# because it combines a large residual with the highest leverage.

png("outputs/goals_leverage_cooks.png", width = 1000, height = 450)
par(mfrow = c(1, 2))
plot(h_goals, type = "h", lwd = 2, ylim = c(0, max(h_goals) * 1.1),
     xlab = "Match number", ylab = "Leverage (hat value)",
     main = "Leverage by match")
abline(h = avg_lev, lty = 2)
abline(h = 2 * avg_lev, lty = 3, col = "red")
legend("topright", legend = c("p/n (average)", "2p/n (rule of thumb)"),
       lty = c(2, 3), col = c("black", "red"))
text(row_8nil, h_goals[row_8nil], "8-0", pos = 4)

plot(cd_goals, type = "h", lwd = 2, ylim = c(0, max(cd_goals) * 1.1),
     xlab = "Match number", ylab = "Cook's distance",
     main = "Cook's distance by match")
top3 <- order(-cd_goals)[1:3]
text(top3, cd_goals[top3], top3, pos = 3, cex = 0.8)
dev.off()

# =============================================================================
# PART 5: REFIT WITHOUT THE 8-0 MATCH
# =============================================================================
# The real test of influence is whether the conclusions change when the point
# is left out. The match stays in the data; this is a sensitivity fit.
m_goals_no8 <- glm(goals_scored ~ home_away + opponent_rank,
                   family = poisson, data = matches, subset = -row_8nil)
summary(m_goals_no8)
drop1_no8 <- drop1(m_goals_no8, test = "Chisq")
drop1_no8

rr_all <- goals_rr
rr_no8 <- rr_table(m_goals_no8)
influence_8nil <- data.frame(
  term            = rr_all$term,
  RR_all46        = rr_all$RR,
  lower_95_all46  = rr_all$lower_95,
  upper_95_all46  = rr_all$upper_95,
  LRT_p_all46     = c(NA, round(goals_drop1$`Pr(>Chi)`[-1], 4)),
  RR_without8     = rr_no8$RR,
  lower_95_without8 = rr_no8$lower_95,
  upper_95_without8 = rr_no8$upper_95,
  LRT_p_without8  = c(NA, round(drop1_no8$`Pr(>Chi)`[-1], 4))
)
influence_8nil

fit_summary_8nil <- data.frame(
  fit         = c("All 46 matches", "Without 8-0 (45)"),
  deviance    = round(c(deviance(m_goals), deviance(m_goals_no8)), 2),
  df          = c(df.residual(m_goals), df.residual(m_goals_no8)),
  pearson_phi = round(c(phi_goals,
                        pearson_X2(m_goals_no8) / df.residual(m_goals_no8)), 3)
)
fit_summary_8nil

write.csv(influence_8nil, "outputs/goals_8nil_influence.csv", row.names = FALSE)
write.csv(fit_summary_8nil, "outputs/goals_8nil_fit_summary.csv", row.names = FALSE)

# What changes without the 8-0:
# - Away v home: RR 0.50 (0.29 to 0.84) -> 0.59 (0.33 to 1.02).
#   LRT p 0.009 -> 0.058. The direction and size are similar (still about 40%
#   fewer expected goals away) but the CI now just includes 1.
# - Opponent rank: RR 1.056 (1.017 to 1.098) -> 1.034 (0.993 to 1.078).
#   LRT p 0.004 -> 0.10. The slope falls by about 40%, and the CI now
#   includes 1. Rank 1 to rank 24 goes from 3.5x to about 2.2x as many goals.
# - Pearson dispersion 0.99 -> 0.78. Without the 8-0 there is, if anything,
#   less variation than the Poisson allows, so there is still no case for an
#   overdispersed model. (In the raw data the 8-0 was the only reason the
#   variance exceeded the mean; once home_away and opponent_rank are in the
#   model it no longer looks like overdispersion, but it does carry the
#   strength of both effects.)
# Conclusion: one match out of 46 decides whether the evidence for both the
# home/away effect and the opponent-rank effect is strong (p < 0.01) or only
# weak (0.05 < p < 0.11). Estimated directions do not change.

# Fitted expected goals with and without the 8-0
rank_grid <- 1:24
png("outputs/goals_8nil_fitted_curves.png", width = 900, height = 550)
plot(goals_scored ~ opponent_rank, data = matches, pch = 19, col = col_ha,
     xlab = "Opponent final rank (1 = strongest)", ylab = "Goals scored",
     main = "Poisson fitted expected goals, with and without the 8-0 match")
for (ha in c("Home", "Away")) {
  nd <- data.frame(home_away = factor(ha, levels = c("Home", "Away")),
                   opponent_rank = rank_grid)
  colr <- ifelse(ha == "Home", "black", "red")
  lines(rank_grid, predict(m_goals, newdata = nd, type = "response"),
        col = colr, lwd = 2)
  lines(rank_grid, predict(m_goals_no8, newdata = nd, type = "response"),
        col = colr, lwd = 2, lty = 2)
}
text(matches$opponent_rank[row_8nil], matches$goals_scored[row_8nil], "8-0", pos = 2)
legend("topleft",
       legend = c("Home", "Away", "All 46 matches (solid)", "Without 8-0 (dashed)"),
       col = c("black", "red", "grey40", "grey40"),
       pch = c(19, 19, NA, NA), lty = c(NA, NA, 1, 2), lwd = c(NA, NA, 2, 2))
dev.off()

pred_grid <- expand.grid(home_away = factor(c("Home", "Away"), levels = c("Home", "Away")),
                         opponent_rank = c(1, 12, 24))
pred_compare <- data.frame(
  pred_grid,
  expected_goals_all46    = round(predict(m_goals, newdata = pred_grid, type = "response"), 2),
  expected_goals_without8 = round(predict(m_goals_no8, newdata = pred_grid, type = "response"), 2)
)
pred_compare
write.csv(pred_compare, "outputs/goals_8nil_predictions.csv", row.names = FALSE)
# The largest change is for a home game v the bottom side (3.0 -> 2.1
# expected goals). Mid-table predictions barely move, and predictions v the
# top side rise slightly (home 0.86 -> 0.98, away 0.43 -> 0.57), because the
# opponent-rank slope is flatter without the 8-0.

# =============================================================================
# PART 6: LEAVE-ONE-OUT CHECK ON EVERY MATCH
# =============================================================================
# Is the 8-0 unique, or would leaving out any single match change things as
# much? Refit 46 times, each time without one match.
loo <- t(sapply(seq_len(n_goals), function(k) {
  mk <- glm(goals_scored ~ home_away + opponent_rank,
            family = poisson, data = matches, subset = -k)
  d1 <- drop1(mk, test = "Chisq")
  c(match = k,
    RR_away = exp(coef(mk)[["home_awayAway"]]),
    RR_rank = exp(coef(mk)[["opponent_rank"]]),
    p_away  = d1$`Pr(>Chi)`[2],
    p_rank  = d1$`Pr(>Chi)`[3])
}))
loo <- data.frame(loo)
loo$cooks_distance <- cd_goals
loo[, 2:5] <- round(loo[, 2:5], 4)
write.csv(loo, "outputs/goals_leave_one_out.csv", row.names = FALSE)

# Which single deletions push either LRT p-value above 0.05?
loo[loo$p_away > 0.05 | loo$p_rank > 0.05, ]
summary(loo$RR_rank[-row_8nil])
summary(loo$p_rank[-row_8nil])
# Only the 8-0. Leaving out any other single match keeps both p-values below
# 0.05, so the 8-0 is the one match the conclusions depend on.

# =============================================================================
# PART 7: QUASIPOISSON SENSITIVITY CHECK (all 46 matches)
# =============================================================================
# Quasipoisson estimates phi instead of fixing it at 1 (week 5, slides 13,
# 19-21). Estimates are unchanged; standard errors are multiplied by
# sqrt(phi_hat). Since phi_hat is estimated, t-tests / F-tests replace z / chi-sq.
m_goals_q <- glm(goals_scored ~ home_away + opponent_rank,
                 family = quasipoisson, data = matches)
summary(m_goals_q)

se_compare <- data.frame(
  term       = names(coef(m_goals)),
  estimate   = round(coef(m_goals), 4),
  se_poisson = round(sqrt(diag(vcov(m_goals))), 4),
  se_quasi   = round(sqrt(diag(vcov(m_goals_q))), 4),
  row.names  = NULL
)
se_compare$ratio <- round(se_compare$se_quasi / se_compare$se_poisson, 3)
se_compare
sqrt(summary(m_goals_q)$dispersion)   # ratio of SEs = sqrt(phi_hat)
write.csv(se_compare, "outputs/goals_poisson_vs_quasi.csv", row.names = FALSE)

# F-tests for each term, since phi is estimated (week 5, slide 13)
drop1(m_goals_q, test = "F")
# phi_hat = 0.99, so quasipoisson SEs are 0.995 times the Poisson ones and the
# conclusions are identical. A negative binomial model (week 5, slides 22-24)
# is not needed: there is no overdispersion to model.

# =============================================================================
# SUMMARY (for notes/decision-notes.md)
# =============================================================================
# Model: goals_scored ~ home_away + opponent_rank, Poisson, log link (n = 46).
# - GOF: deviance 49.8 on 43 df (p = 0.22), but fitted means are 0.4-3.0, so
#   the chi-squared approximation is rough (week 4, slide 5). Pearson phi_hat
#   = 0.99: no overdispersion; quasipoisson gives the same conclusions.
# - Residuals: no curvature or funnelling. Two |r'| > 2: the 8-0 (+2.61) and
#   a 0-0 home draw v rank 18 (-2.15). Neither exceeds 3.
# - Leverage: average p/n = 0.065. The 8-0 has the highest leverage (0.162).
# - Cook's distance: the 8-0 = 0.64; every other match is below 0.08.
# - Without the 8-0: away RR 0.50 -> 0.59 (p 0.009 -> 0.058); opponent-rank
#   RR 1.056 -> 1.034 (p 0.004 -> 0.10). Directions unchanged; strength of
#   evidence falls from strong to weak for both terms. No other single match
#   has this effect (leave-one-out, Part 6).
# Decision to record: keep the 8-0 in the data (no evidence it is an error,
# and it is a genuine result), report the main fit on all 46 matches, and
# report the without-8-0 fit alongside it as a sensitivity analysis. The
# report should say that the strength of evidence for both effects rests
# heavily on this one match. Alternatives considered: deleting the match (no
# justification), quasipoisson / negative binomial (not needed, phi_hat ~ 1).
# Caveat: the data are paired by opponent (each played home and away), which
# this model does not account for.
