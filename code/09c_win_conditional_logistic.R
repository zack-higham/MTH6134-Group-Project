source("code/00_load_data.R")
library(survival)

#Step 1: Prepare binary win outcome & inspect discordant pairs ---
matches$win = as.integer(matches$result == "W")

# Reshape to wide format by opponent_rank to see discordant pairs directly
#discordant pairs are where the two outcomes disagree (1 win & 1 loss either home/away) 
wide_matches = reshape(
  matches[, c("opponent_rank", "home_away", "win")],
  idvar = "opponent_rank",
  timevar = "home_away",
  direction = "wide"
)
pair_tab = table(Home_Win = wide_matches$win.Home, Away_Win = wide_matches$win.Away)
print(pair_tab)

# FINDING: Cross-tabulating the 23 pairs shows how many opponents had discordant outcomes. 
# (won at home but lost/drew away, or vice versa) vs concordant outcomes
# (won/failed to win both). Only discordant pairs contribute info to the conditional likelihood.

#Step 2: Fit Conditional Logistic Regression (stratified by opponent_rank) ---
# Ensure Home is the baseline reference level so home_awayAway gives Away vs Home OR
matches$home_away = relevel(factor(matches$home_away), ref = "Home")

m_clogit <- clogit(win ~ home_away + strata(opponent_rank), 
                   method = "exact", 
                   data = matches)
summary(m_clogit)

# Extract Odds Ratio, 95% Wald CIs (normal way to do binomial CI), and LRT statistic
or_est <- exp(coef(m_clogit))
ci_est <- exp(confint(m_clogit))
lrt_stat <- summary(m_clogit)$logtest["test"]
lrt_df   <- summary(m_clogit)$logtest["df"]
lrt_pval <- summary(m_clogit)$logtest["pvalue"]

# Extract both LRT and Score test (Score test = McNemar's chi-squared without continuity correction)
lrt_stat   <- as.numeric(summary(m_clogit)$logtest["test"])
lrt_pval   <- as.numeric(summary(m_clogit)$logtest["pvalue"])
score_stat <- as.numeric(summary(m_clogit)$sctest["test"])
score_pval <- as.numeric(summary(m_clogit)$sctest["pvalue"])

results_df <- data.frame(
  Term        = names(coef(m_clogit)),
  OR          = or_est,
  CI_Lower    = ci_est[1],
  CI_Upper    = ci_est[2],
  LRT_Chisq   = lrt_stat,
  LRT_p       = lrt_pval,
  Score_Chisq = score_stat,
  Score_p     = score_pval,
  df          = 1
)

print(results_df)
write.csv(results_df, "outputs/win_conditional_logistic.csv", row.names = FALSE)


# FINDING: Conditional on opponent (strata = opponent_rank), playing away is associated with 
# an odds ratio of 0.273 (95% CI: 0.076, 0.978; LRT chi-sq = 4.86 on 1 df, p = 0.0275) 
# compared to playing at home. Only the 14 discordant opponent pairs (11 home-only wins vs 3 away-only wins) 
# contribute to this estimate, yielding the same OR (3/11 = 0.273) as Liha's uncorrected McNemar test in 09b. 
# The RAO score statistic (chi-sq = 4.57 on 1 df, p = 0.0325) differ slightly in finite samples due to using 
# deviance rather than the exact binomial formulation, but yields the same inference at alpha = 0.05.  
# Compared to the unconditional logistic model in 04e (OR = 0.20, 95% CI: 0.05 to 0.72; LRT = 6.15 on 1 df, p = 0.013), 
# the conditional OR is slightly attenuated toward 1 with a wider interval due to the reduced effective sample size, 
# but confirms that lower odds of winning away persist when accounting for opponent pairing without assuming a linear rank effect.
