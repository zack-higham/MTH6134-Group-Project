source("code/00_load_data.R")

# From 04e: model evaluates log odds of winning a match 
# as a function of playing location and opponent rank.
matches$win <- as.integer(matches$result == "W")
table(win = matches$win, home_away = matches$home_away)   # 15/23 home, 7/23 away
m_win <- glm(win ~ home_away + opponent_rank, family = binomial, data = matches)
summary(m_win)

# plot(fitted(m_win))
# plot(m_win)
rstandard(m_win)

# Export Residuals vs Fitted / Diagnostic Plots
png("outputs/win_diagnostics.png", width = 800, height = 800)
par(mfrow = c(2, 2))
plot(m_win)
dev.off()

# FINDING: Residuals vs fitted shows a distinct 2-band pattern due to binary (0/1) response data;
# outcomes are strictly 0 or 1 so a smooth curve of best fit is not useful. Q-Q residuals follow 
# the reference line except at the upper tail, reflecting discrete binomial data rather than a 
# Gaussian distribution.

# Measuring leverage (hat values)
hatvalues(m_win)
print(which(hatvalues(m_win) > 3 / 46))
matches[hatvalues(m_win) > 3 / 46, c("home_away", "opponent_rank", "win")]

# FINDING: Average leverage threshold is p/n = 3/46 = 0.0652. 19 matches exceed 0.0652, 
# driven by extreme opponent ranks (e.g., Game 1 at home vs rank 1 has the highest leverage).

# Cook's distance: measuring individual observation influence
png("outputs/win_cooks.png", width = 800, height = 800)
plot(m_win, which = 4)
dev.off()

# FINDING: All matches have Cook's distance < 0.10 (well below 2p/n = 0.1304), 
# indicating no single match severely distorts coefficient estimates.

# Refit model excluding top Cook's distance point (Match 27) and the 8-0 match (Match 8)
m_win_no27 <- update(m_win, subset = -27)
m_win_no8  <- update(m_win, subset = -8)

# Helper function to extract Odds Ratios and 95% Profile-Likelihood Confidence Intervals
get_or_ci <- function(model) {
  or <- exp(coef(model))
  ci <- exp(confint(model))
  sprintf("%.3f (%.3f, %.3f)", or, ci[, 1], ci[, 2])
}

# Compare coefficient estimates using Odds Ratios and 95% CIs
coef_comparison <- data.frame(
  Term               = names(coef(m_win)),
  Full_Model_OR_95CI = get_or_ci(m_win),
  No_Match27_OR_95CI = get_or_ci(m_win_no27),
  No_Match8_OR_95CI  = get_or_ci(m_win_no8)
)

print(coef_comparison)
write.csv(coef_comparison, "outputs/win_influence_comparison.csv", row.names = FALSE)

# Inspect Row 8 (8-0 Match) influence metrics directly
cat("Row 8 Leverage:", hatvalues(m_win)[8], "\n")
cat("Row 8 Cook's Distance:", cooks.distance(m_win)[8], "\n")

# FINDING: Refitting without Match 27 (highest Cook's D = 0.0367) or Match 8 (8-0 win; 
# leverage = 0.0772, Cook's D = 0.00558) produces minimal parameter perturbation (see 
# outputs/win_influence_comparison.csv for exact ORs and 95% profile-likelihood CIs) and 
# leaves the sign, magnitude, and statistical inference of both predictors unchanged at 
# alpha = 0.05. Because the response is binary (0/1), the 8-0 scoreline carries no additional 
# weight over any other win, so m_win is retained on all 46 fixtures.
