# 06b_goals_scored_selection.R — Week 6: Poisson regression, model selection
# Owner: Zack
# Question: is goals_scored ~ home_away + opponent_rank (the model used in
# 03b and 05e) the right Poisson model for Ashford's goals scored? 05e fitted
# and diagnosed it but did not do model selection. Here we test:
#   Part 1: the home_away:opponent_rank interaction (LRT + AIC)
#   Part 2: log(opponent_rank) v linear opponent_rank (AIC; LRT via a model
#           containing both, since the two models are not nested)
#   Part 3: confirm the final model with drop1 LRTs, rate ratios with 95% CIs
#   Part 4: does the selection change without the 8-0 (row 8)? (link to 05e)
# Lecture references: W5 = week 5 notes (Poisson): slides 3, 16 (Poisson GLM,
# log link), 25-26 (offsets), 27-28 (rate ratios and interpretation);
# W4 slides 3-6 (deviance, LRTs for nested models). AIC as in 04b.
# Base R only. Run from the project folder (open the .Rproj first).
# Output: outputs/goals_scored_model_selection.csv

source("code/00_load_data.R")

# goals_scored is a count, so Poisson GLM with log link (W5 slides 3, 16).
# No offset: every row is one 90-minute match, so exposure is equal (W5 slides
# 25-26). Deviance and AIC are comparable across all models below because the
# response and the 46 rows are the same.

m_main <- glm(goals_scored ~ home_away + opponent_rank,
              family = poisson, data = matches)

# Helper: one row of the selection table for a comparison
sel_row <- function(step, model, comparison = NA, lrt = NULL, data_used) {
  data.frame(
    data       = data_used,
    step       = step,
    model      = deparse(formula(model)[[3]]),
    n_par      = length(coef(model)),
    deviance   = round(deviance(model), 3),
    resid_df   = df.residual(model),
    AIC        = round(AIC(model), 2),
    compared_with = comparison,
    LRT        = if (is.null(lrt)) NA else round(lrt$Deviance[2], 3),
    LRT_df     = if (is.null(lrt)) NA else lrt$Df[2],
    p_value    = if (is.null(lrt)) NA else signif(lrt[2, "Pr(>Chi)"], 3),
    stringsAsFactors = FALSE)
}

# =============================================================================
# PART 1: HOME_AWAY x OPPONENT_RANK INTERACTION
# =============================================================================
# Does the opponent-rank slope (on the log scale) differ between home and away?
m_int <- update(m_main, . ~ . + home_away:opponent_rank)
summary(m_int)
lrt_int <- anova(m_main, m_int, test = "Chisq")
lrt_int
AIC(m_main, m_int)
exp(coef(m_int)["home_awayAway:opponent_rank"])
# FINDING: interaction home_away:opponent_rank: LRT = 0.36 on 1 df, p = 0.55.
# AIC 133.43 (main effects) v 135.07 (with interaction). Estimated ratio of
# the away rank RR to the home rank RR = 0.98 per place.
# Conclusion: no evidence that the association between opponent rank and
# goals scored differs between home and away matches; the interaction is not
# needed (both the LRT and AIC agree), so the effect of venue is taken as
# multiplicative and the same at every opponent rank.

# =============================================================================
# PART 2: LOG(OPPONENT_RANK) v LINEAR OPPONENT_RANK
# =============================================================================
# With log link, linear rank means each place multiplies expected goals by the
# same factor; log(rank) means each DOUBLING of rank does, so the difference
# between ranks 1 and 2 matters as much as between 12 and 24.
m_log <- glm(goals_scored ~ home_away + log(opponent_rank),
             family = poisson, data = matches)
summary(m_log)
# The two models have the same number of parameters (3) but are NOT nested, so
# an LRT between them is not valid. Compare by AIC (equivalently deviance,
# since n_par is equal). For a formal test, fit the model containing both
# and test each version against it (each is nested in it).
m_both <- glm(goals_scored ~ home_away + opponent_rank + log(opponent_rank),
              family = poisson, data = matches)
lrt_lin_in_both <- anova(m_main, m_both, test = "Chisq")  # is log needed given linear?
lrt_log_in_both <- anova(m_log,  m_both, test = "Chisq")  # is linear needed given log?
lrt_lin_in_both
lrt_log_in_both
AIC(m_main, m_log, m_both)
# FINDING: linear rank: deviance 49.78 on 43 df, AIC 133.43.
# log(rank): deviance 52.40 on 43 df, AIC 136.05 (2.6 higher).
# Model with both: deviance 49.03 on 42 df, AIC 134.67.
#   Adding log(rank) to linear rank: LRT = 0.76 on 1 df, p = 0.38.
#   Adding linear rank to log(rank): LRT = 3.38 on 1 df, p = 0.066.
# Conclusion: linear opponent_rank fits better than log(opponent_rank) (lower
# AIC by 2.6), and once linear rank is in the model there is no evidence that
# log(rank) adds anything (p = 0.38). There is weak evidence (p = 0.066) the
# other way round. So we keep opponent_rank linear on the log scale.
# Also checked: the interaction is not needed in the log-rank version either
# (below, LRT 0.08 on 1 df, p = 0.78).
m_log_int <- update(m_log, . ~ . + home_away:log(opponent_rank))
anova(m_log, m_log_int, test = "Chisq")

# =============================================================================
# PART 3: CONFIRM THE FINAL MODEL
# =============================================================================
# Final: goals_scored ~ home_away + opponent_rank. Test each term given the
# other by LRT (order-independent).
d1_main <- drop1(m_main, test = "Chisq")
d1_main
# FINDING: home_away: LRT = 6.80 on 1 df, p = 0.009; opponent_rank:
# LRT = 8.26 on 1 df, p = 0.004. Both terms are kept. Residual deviance
# 49.78 on 43 df (p = 0.22; fitted means 0.4-3.0, so only a rough GOF check,
# see 05e); Pearson dispersion 0.99 (05e), so plain Poisson is adequate.
1 - pchisq(deviance(m_main), df.residual(m_main))

# Rate ratios with 95% profile-likelihood CIs (W5 slides 27-28)
rr <- exp(cbind(RR = coef(m_main), suppressMessages(confint(m_main))))
round(rr, 3)
exp(23 * coef(m_main)["opponent_rank"])          # rank 1 v rank 24
exp(23 * suppressMessages(confint(m_main))["opponent_rank", ])
# FINDING: Away v home: RR = 0.50 (95% CI 0.29 to 0.84): holding opponent rank
# fixed, Ashford's expected goals away are half those at home.
# Opponent rank: RR = 1.056 per place (95% CI 1.017 to 1.098): each place
# lower the opponent finished is associated with about 5.6% more expected goals.
# Over the full range (rank 1 to 24) that is a factor of 3.5 (95% CI 1.5 to 8.6).
# Intercept: expected goals at home v a (hypothetical) rank-0 side = 0.81
# (not meaningful on its own).
# These are the same as 05e, as expected (same model).

# =============================================================================
# PART 4: SENSITIVITY — THE SAME SELECTION WITHOUT THE 8-0 (row 8)
# =============================================================================
# 05e showed the 8-0 v rank 24 has Cook's distance 0.64. Check that it does
# not drive the choice of model. Data unchanged; `subset =` only.
row_8nil <- which(matches$home_away == "Home" & matches$goals_scored == 8)
m_main8 <- update(m_main, subset = -row_8nil)
m_int8  <- update(m_int,  subset = -row_8nil)
m_log8  <- update(m_log,  subset = -row_8nil)
m_both8 <- update(m_both, subset = -row_8nil)
lrt_int8         <- anova(m_main8, m_int8,  test = "Chisq")
lrt_lin_in_both8 <- anova(m_main8, m_both8, test = "Chisq")
lrt_log_in_both8 <- anova(m_log8,  m_both8, test = "Chisq")
lrt_int8; lrt_lin_in_both8; lrt_log_in_both8
AIC(m_main8, m_int8, m_log8, m_both8)
# FINDING: without the 8-0 (45 matches): interaction LRT = 0.03 on 1 df,
# p = 0.85; adding log(rank) to linear rank LRT = 0.02, p = 0.89; adding
# linear rank to log(rank) LRT = 0.51, p = 0.47. AIC: linear 122.10,
# log 122.59, interaction 124.06, both 124.08.
# Conclusion: the same final model is chosen without the 8-0. Linear and log
# rank are now almost indistinguishable (AIC difference 0.5), so the
# preference for linear rank rests partly on the 8-0; either form is
# defensible, and we keep linear for continuity with 04e and 05e. (05e
# already reports how the RRs and p-values change without the 8-0.)

# =============================================================================
# SAVE THE SELECTION TABLE
# =============================================================================
sel <- rbind(
  sel_row("Main effects (final)", m_main, data_used = "All 46"),
  sel_row("Add interaction", m_int, "Main effects", lrt_int, "All 46"),
  sel_row("Log rank instead of linear", m_log, "not nested: compare AIC",
          NULL, "All 46"),
  sel_row("Both rank forms (test log given linear)", m_both, "Main effects",
          lrt_lin_in_both, "All 46"),
  sel_row("Both rank forms (test linear given log)", m_both, "Log rank",
          lrt_log_in_both, "All 46"),
  sel_row("Main effects (final)", m_main8, data_used = "Without 8-0 (45)"),
  sel_row("Add interaction", m_int8, "Main effects", lrt_int8,
          "Without 8-0 (45)"),
  sel_row("Log rank instead of linear", m_log8, "not nested: compare AIC",
          NULL, "Without 8-0 (45)"),
  sel_row("Both rank forms (test log given linear)", m_both8, "Main effects",
          lrt_lin_in_both8, "Without 8-0 (45)"),
  sel_row("Both rank forms (test linear given log)", m_both8, "Log rank",
          lrt_log_in_both8, "Without 8-0 (45)")
)
# drop1 tests for the final model (all 46)
d1_rows <- data.frame(
  data = "All 46", step = paste("Final model: drop", rownames(d1_main)[-1]),
  model = c("opponent_rank", "home_away"), n_par = 2,
  deviance = round(d1_main$Deviance[-1], 3), resid_df = 44,
  AIC = round(d1_main$AIC[-1], 2), compared_with = "Main effects",
  LRT = round(d1_main$LRT[-1], 3), LRT_df = d1_main$Df[-1],
  p_value = signif(d1_main$`Pr(>Chi)`[-1], 3), stringsAsFactors = FALSE)
sel <- rbind(sel, d1_rows)
sel
write.csv(sel, "outputs/goals_scored_model_selection.csv", row.names = FALSE)

# =============================================================================
# SUMMARY (for decision-notes)
# =============================================================================
# FINDING (overall): final model goals_scored ~ home_away + opponent_rank,
# Poisson, log link, no offset (n = 46).
# - Interaction home_away:opponent_rank not needed: LRT 0.36 on 1 df,
#   p = 0.55; AIC 133.43 -> 135.07.
# - Linear rank preferred to log(rank): AIC 133.43 v 136.05; log(rank) adds
#   nothing given linear rank (LRT 0.76 on 1 df, p = 0.38).
# - Both terms needed: home_away LRT 6.80 (1 df, p = 0.009), opponent_rank
#   LRT 8.26 (1 df, p = 0.004).
# - Away v home RR 0.50 (0.29 to 0.84); opponent rank RR 1.056 per place
#   (1.017 to 1.098).
# - Without the 8-0 the same model is chosen, but linear v log rank is close
#   (AIC 122.10 v 122.59).
# Wording: venue and opponent rank are associated with goals scored; these
# are not causal effects. Caveat (as 05e): matches are paired by opponent.
