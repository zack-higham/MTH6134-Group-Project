# 08d_age_prev_injury_table.R — Week 8: contingency tables with a response
# Owner: Zack
# Question: in the 4 x 4 x 2 table age band x previous-injury band x injured,
# with injured as the response, is injury associated with age band and with
# previous injuries, and does a log-linear model give exactly the same answer
# as the grouped binomial (logistic) model?
#   Part 1: the three-way table of counts and injury proportions
#   Part 2: log-linear model with age_band*prev_band fixed and all two-way
#           interactions with injured; matching grouped binomial model
#   Part 3: show the estimates, SEs and deviances are identical
#   Part 4: the three-way term age:prev:injured = the age x prev interaction
#           in the logistic model (LRT, identical in both)
#   Part 5: odds ratios with 95% CIs; compare with 04b (numeric age and
#           prev_injuries)
# Lecture references: W6/8 = weeks 6 and 8 notes (contingency tables):
#   slides 26-31 (three-way tables, sub-models); 35-39 (log-linear v logistic,
#   identical estimates); 40 (when one variable is a response, the margin of
#   the explanatory variables stays in every model).
# Base R only. Run from the project folder (open the .Rproj first).
# Bands are made here, not in 00_load_data.R. Age bands are the same as 05b.
# Outputs: outputs/table_age_prev_injury.csv,
#          outputs/age_prev_loglinear_vs_logistic.csv

source("code/00_load_data.R")

players$age_band  <- cut(players$age, breaks = c(-Inf, 22, 26, 30, Inf),
                         labels = c("<=22", "23-26", "27-30", "31+"))
players$prev_band <- cut(players$prev_injuries, breaks = c(-Inf, 0, 1, 2, Inf),
                         labels = c("0", "1", "2", "3+"))
# injured as a factor with 0 (not injured) as the baseline, for the table
players$injured_f <- factor(players$injured, levels = c(0, 1))

# =============================================================================
# PART 1: THE THREE-WAY TABLE
# =============================================================================
tab <- xtabs(~ age_band + prev_band + injured_f, data = players)
ftable(tab)
sum(tab)                                   # 620 players

# One row per age band x prev band cell: n, injured, proportion injured
d_grp <- as.data.frame(xtabs(~ age_band + prev_band, data = players),
                       responseName = "n")
d_grp$injured     <- as.vector(tab[, , "1"])
d_grp$not_injured <- as.vector(tab[, , "0"])
d_grp$prop_injured <- round(d_grp$injured / d_grp$n, 3)
d_grp
min(d_grp$n); min(d_grp$injured)
# FINDING: 16 age x prev cells, n from 3 (31+, 3+ previous) to 109 (23-26, 0
# previous). No empty cells and every cell has at least 2 injured players, so
# every estimate below is finite. Injury proportion rises with previous
# injuries in every age band except a dip at 2 previous in the <=22 band
# (3 of 21): e.g. 23-26: 8% (0), 16% (1), 27% (2), 37% (3+); 27-30: 15%, 22%,
# 33%, 57%. It also rises with age within each prev band: 0 previous: 7%
# (<=22), 8% (23-26), 15% (27-30), 19% (31+); 3+ previous: 23%, 37%, 57%, 67%.
round(prop.table(xtabs(~ age_band + injured_f, players), 1)[, "1"], 3)
round(prop.table(xtabs(~ prev_band + injured_f, players), 1)[, "1"], 3)
# FINDING: marginal injury proportions by age band: 12% (<=22), 17% (23-26),
# 24% (27-30), 30% (31+); by prev band: 11% (0), 19% (1), 28% (2), 40% (3+).

# =============================================================================
# PART 2: LOG-LINEAR MODEL AND GROUPED BINOMIAL MODEL
# =============================================================================
# Long format: one row per cell of the 4 x 4 x 2 table, count in Freq.
d_ll <- as.data.frame(tab)
names(d_ll)[names(d_ll) == "injured_f"] <- "injured"
nrow(d_ll)                                 # 32 cells

# injured is the response, so the age_band x prev_band margin (how many
# players are in each age x prev cell) is treated as fixed: age_band*prev_band
# stays in every log-linear model (slide 40). The questions about injury are
# the interactions WITH injured.
#   No three-way term:  Freq ~ age_band*prev_band + age_band*injured
#                               + prev_band*injured
#   Saturated:          Freq ~ age_band*prev_band*injured
m_ll  <- glm(Freq ~ age_band * prev_band + age_band * injured
                    + prev_band * injured,
             family = poisson, data = d_ll)
m_ll3 <- glm(Freq ~ age_band * prev_band * injured,
             family = poisson, data = d_ll)

# Matching grouped binomial models on the 16 age x prev cells (slides 35-39)
m_bin  <- glm(cbind(injured, n - injured) ~ age_band + prev_band,
              family = binomial, data = d_grp)
m_bin3 <- glm(cbind(injured, n - injured) ~ age_band * prev_band,
              family = binomial, data = d_grp)
summary(m_ll)
summary(m_bin)

# =============================================================================
# PART 3: THE ESTIMATES ARE IDENTICAL
# =============================================================================
# Correspondence (slides 35-39), with injured = 0 as the log-linear baseline:
#   log-linear injured1               <-> logistic (Intercept)
#   log-linear age_bandX:injured1     <-> logistic age_bandX
#   log-linear prev_bandX:injured1    <-> logistic prev_bandX
# The other log-linear terms (age_band*prev_band) only reproduce the fixed
# cell totals n and have no counterpart in the logistic model.
ll_terms  <- c("injured1",
               paste0("age_band", levels(players$age_band)[-1], ":injured1"),
               paste0("prev_band", levels(players$prev_band)[-1], ":injured1"))
bin_terms <- c("(Intercept)",
               paste0("age_band", levels(players$age_band)[-1]),
               paste0("prev_band", levels(players$prev_band)[-1]))

ci_bin <- suppressMessages(confint(m_bin))
cmp <- data.frame(
  quantity         = c("intercept (log odds, <=22 and 0 previous)",
                       paste("age", levels(players$age_band)[-1], "v <=22"),
                       paste("prev", levels(players$prev_band)[-1], "v 0")),
  loglinear_term   = ll_terms,
  logistic_term    = bin_terms,
  loglinear_est    = round(coef(m_ll)[ll_terms], 5),
  logistic_est     = round(coef(m_bin)[bin_terms], 5),
  loglinear_se     = round(summary(m_ll)$coefficients[ll_terms, 2], 5),
  logistic_se      = round(summary(m_bin)$coefficients[bin_terms, 2], 5),
  OR               = round(exp(coef(m_bin)[bin_terms]), 3),
  OR_lower_95      = round(exp(ci_bin[bin_terms, 1]), 3),
  OR_upper_95      = round(exp(ci_bin[bin_terms, 2]), 3),
  row.names = NULL, stringsAsFactors = FALSE)
cmp$abs_difference <- signif(abs(cmp$loglinear_est - cmp$logistic_est), 2)
cmp
max(abs(coef(m_ll)[ll_terms] - coef(m_bin)[bin_terms]))
max(abs(summary(m_ll)$coefficients[ll_terms, 2] -
        summary(m_bin)$coefficients[bin_terms, 2]))
c(deviance_ll = deviance(m_ll), df_ll = df.residual(m_ll),
  deviance_bin = deviance(m_bin), df_bin = df.residual(m_bin))
# FINDING: every estimate and SE agrees to within rounding error (largest
# absolute difference 9e-16 for the estimates, 2.5e-9 for the SEs, i.e. only
# the IWLS convergence tolerance). Residual deviance is also identical:
# 2.15 on 9 df in both models (32 - 23 = 9 for the log-linear model,
# 16 - 7 = 9 for the binomial).
# Conclusion: the log-linear model with age_band*prev_band fixed and the
# interactions with injured is the same model as the grouped logistic model,
# because the binomial is the Poisson conditional on the fixed cell totals
# (slides 35-39). The main-effect and age x prev terms of the log-linear
# model are nuisance parameters.
# Goodness of fit: deviance 2.15 on 9 df, p = 0.99 (below): no evidence of
# lack of fit (if anything the cells agree with the model more closely than
# chance would suggest). 7 of the 32 fitted counts are below 5, so this
# p-value is approximate.
1 - pchisq(deviance(m_bin), df.residual(m_bin))
sum(fitted(m_ll) < 5)

# =============================================================================
# PART 4: THE THREE-WAY TERM IS THE AGE x PREV INTERACTION
# =============================================================================
lrt_ll  <- anova(m_ll,  m_ll3,  test = "Chisq")
lrt_bin <- anova(m_bin, m_bin3, test = "Chisq")
lrt_ll
lrt_bin
# FINDING: three-way term age_band:prev_band:injured: LRT = 2.15 on 9 df,
# p = 0.99, identical to the age_band:prev_band interaction in the logistic
# model (LRT = 2.15 on 9 df, p = 0.99). (The saturated model has deviance 0,
# so this LRT is the goodness-of-fit deviance from Part 3.)
# Conclusion: no evidence that the association between previous injuries and
# injury differs between age bands (or vice versa), so the three-way term /
# logistic interaction is dropped. Then test each two-way term with injured:
drop1(m_ll, test = "Chisq")
d1_bin <- drop1(m_bin, test = "Chisq")
d1_bin
# FINDING: age_band:injured (= age_band in the logistic): LRT = 14.91 on
# 3 df, p = 0.002. prev_band:injured (= prev_band): LRT = 34.34 on 3 df,
# p < 0.001 (1.7e-7). Same values in both models. (drop1 on the log-linear
# model also lists age_band:prev_band, LRT 8.28 on 9 df, p = 0.51, but that
# term is the fixed margin of the explanatory variables and stays in
# whatever its p-value, slide 40.)
# Conclusion: injury is associated with both age band and previous-injury
# band, each adjusted for the other; neither can be dropped. In the
# log-linear language, injured is not conditionally independent of age band
# given previous injuries, nor of previous injuries given age band. Final
# log-linear model: Freq ~ age_band*prev_band + age_band*injured
# + prev_band*injured (no three-way term); its independence graph is a
# triangle (all three pairs joined), so nothing is collapsible.

# =============================================================================
# PART 5: ODDS RATIOS AND COMPARISON WITH 04b
# =============================================================================
cmp[, c("quantity", "OR", "OR_lower_95", "OR_upper_95")]
# FINDING (odds ratios from the final model, 95% profile-likelihood CIs,
# each adjusted for the other banded variable):
# - Age 23-26 v <=22: OR 1.34 (0.74 to 2.49); 27-30: OR 2.30 (1.25 to 4.35);
#   31+: OR 3.66 (1.69 to 7.96).
# - 1 previous injury v 0: OR 2.04 (1.19 to 3.49); 2: OR 3.16 (1.74 to 5.72);
#   3+: OR 6.08 (3.17 to 11.71).
# - Baseline (<=22, 0 previous): odds of injury 0.072 (0.039 to 0.125), i.e.
#   a fitted probability of about 7%.
# Conclusion: the odds of injury are associated with both age and previous
# injuries, rising steadily across the bands. The 23-26 v <=22 interval
# includes 1, but the older bands do not.
#
# Comparison with 04b (age and prev_injuries numeric, plus training_load):
# 04b gave OR 1.11 per year of age and 1.67 per previous injury. Banding
# gives a similar picture. The prev-band log ORs (0.71, 1.15, 1.81) rise
# roughly evenly, consistent with 04b's one OR per previous injury, and the
# age-band log ORs (0.29, 0.83, 1.30) rise roughly in line with the mean
# ages of the bands (20.2, 24.6, 28.2, 32.2 years). Rough check of size:
# 31+ v <=22 is about 12 years apart on average, and 04b gives 1.11^12 = 3.5
# (here 3.66); the 3+ band averages 3.35 previous injuries, and 04b gives
# 1.67^3.35 = 5.6 (here 6.08). So the numeric terms in 04b describe these
# data well, with 2 parameters instead of 6 and no information lost to
# banding. Here training_load is not adjusted for (it is only weakly
# correlated with age and prev_injuries, see 01a).
write.csv(cmp, "outputs/age_prev_loglinear_vs_logistic.csv", row.names = FALSE)

# Table output: cells with observed and fitted injured counts from the final
# model, and Pearson residuals for the injured count in each cell.
d_grp$fitted_injured <- round(fitted(m_bin) * d_grp$n, 2)
d_grp$pearson_resid  <- round(residuals(m_bin, type = "pearson"), 2)
d_grp$expected_below_5 <- d_grp$fitted_injured < 5 |
                          (d_grp$n - d_grp$fitted_injured) < 5
d_grp
max(abs(d_grp$pearson_resid))
# FINDING: largest |Pearson residual| = 0.68 (<=22, 1 previous: 7 observed v
# 5.52 fitted); no cell is near 2, so the additive model (no three-way term)
# fits every cell well. 5 of the 16 cells have an expected injured count
# below 5 (31+ with 1, 2 or 3+ previous; <=22 with 2 or 3+ previous), so the
# chi-squared approximations above are rough.
write.csv(d_grp, "outputs/table_age_prev_injury.csv", row.names = FALSE)

# =============================================================================
# SUMMARY (for decision-notes)
# =============================================================================
# FINDING (overall): 4 x 4 x 2 table, 620 players.
# - Log-linear Freq ~ age*prev + age*injured + prev*injured gives exactly the
#   same estimates, SEs and deviance (2.15 on 9 df) as the grouped binomial
#   cbind(injured, n - injured) ~ age_band + prev_band.
# - Three-way term = age x prev interaction in the logistic model:
#   LRT 2.15 on 9 df, p = 0.99 -> dropped.
# - Age band (LRT 14.91, 3 df, p = 0.002) and prev band (LRT 34.34, 3 df,
#   p < 0.001) both associated with injury, each adjusted for the other.
# - ORs v <=22: 1.34, 2.30, 3.66; v 0 previous: 2.04, 3.16, 6.08 (CIs in
#   the output); rising across bands, consistent with 04b's numeric terms.
# Caveats: many small expected counts; bands lose information; training_load
# not included; associations, not causal effects.
