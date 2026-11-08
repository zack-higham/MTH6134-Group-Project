source("code/00_load_data.R")

#1: Refit lm1 with GK as baseline ---
players$position = relevel(factor(players$position), ref = "GK")
lm1 = lm(minutes_played ~ position + age + training_load + bmi + prev_injuries, data = players)

# Identify the 16 players at the 3960-minute ceiling (12 are GKs, )
players$at_ceiling = players$minutes_played >= 3960

#2: Diagnostics Plot with Ceiling Highlighted ---
png("outputs/lm1_diagnostics_ceiling.png", width = 900, height = 900)
par(mfrow = c(2, 2))
# Residuals vs Fitted with ceiling players highlighted in red
plot(fitted(lm1), residuals(lm1), 
     xlab = "Fitted Values (model prediction of mins played)", ylab = "Residuals (dist. from model's predicted values)", 
     main = "Residuals vs Fitted (Ceiling Highlighted)",
     col = ifelse(players$at_ceiling, "red", "black"),
     pch = ifelse(players$at_ceiling, 19, 1))
abline(h = 0, lty = 2, col = "gray")

# Normal Q-Q
qqnorm(residuals(lm1), main = "Normal Q-Q")
qqline(residuals(lm1), col = "red")

# Scale-Location
scale_sqrt = sqrt(abs(rstandard(lm1)))
plot(fitted(lm1), scale_sqrt, xlab = "Fitted Values", ylab = "Root Standardised Residuals", main = "Scale-Location")
abline(h = sqrt(0.5), lty = 2, col = "gray")

# Residuals vs Leverage
plot(lm1, which = 5)
dev.off()

# FINDING: Residual diagnostics show an S-shaped pattern in the Normal Q-Q plot, 
# indicating heavy tails or bounded constraints rather than standard skewness. 
# This is driven by the 16 players (12 GKs) hitting the 3960-minute hard ceiling, 
# where actual values are artificially capped, violating OLS normality assumptions 
# and demonstrating that minutes played are censored.
# e.g. GKs might have the physical capacity to have played 4000 mins if there was no ceiling. 

#3: Leverage (p/n = 8/620) and Cook's Distance ---
p = length(coef(lm1)) # 8 parameters
n = nrow(players)      # 620 observations
leverage_threshold = p / n # 8 / 620 = 0.0129
4/n

lev = hatvalues(lm1)
cooks = cooks.distance(lm1)

png("outputs/lm1_leverage_cooks.png", width = 900, height = 500)
par(mfrow = c(1, 2))
plot(lev, main = "Leverage Values", ylab = "Hat Value")
abline(h = leverage_threshold, col = "red", lty = 2)
plot(cooks, main = "Cook's Distance", ylab = "Cook's D")
dev.off()

# Quick check to see exactly which rows correspond to those spikes (> 0.02)
which(cooks > 0.02)
players[which(cooks > 0.02), c("position", "age", "training_load", "minutes_played")]

# FINDING: Cook's distance index plot reveals two isolated influential points (> 0.02) 
# Both are not at the 3960-minute ceiling. Instead, they represent unusual player usage profiles: 
# Row 531 is a GK who played only 1,705 minutes (defying the high baseline of GK mins played), 
# and Row 43 is a Fwd with only 105 minutes. These create large residuals and pull on 
# model coefficients due to unexpected outcome-predictor combinations.

#4: Sensitivity Analysis (Refitting without the 16 ceiling players) ---
players_sub = players[!players$at_ceiling, ]
lm1_sub = lm(minutes_played ~ position + age + training_load + bmi + prev_injuries, data = players_sub)

# Compare coefficients with 95% CIs
coef_orig_ci = confint(lm1)
coef_sub_ci = confint(lm1_sub)

sensitivity_df = data.frame(
  Term = names(coef(lm1)),
  Full_Estimate = coef(lm1),
  Full_CI_Lower = coef_orig_ci[, 1],
  Full_CI_Upper = coef_orig_ci[, 2],
  NoCeiling_Estimate = coef(lm1_sub),
  NoCeiling_CI_Lower = coef_sub_ci[, 1],
  NoCeiling_CI_Upper = coef_sub_ci[, 2]
)

print(sensitivity_df)
write.csv(sensitivity_df, "outputs/lm1_ceiling_sensitivity.csv", row.names = FALSE)

# FINDING: Excluding the 16 ceiling players shifts coefficient estimates and narrows confidence intervals 
# for positional effects, confirming that the 3960 minute cap distorts OLS estimates. 
# The minutes limit represents a structural ceiling (censored data) rather than a true unconstrained maximum. 

