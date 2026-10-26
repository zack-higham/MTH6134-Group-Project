# 06e_venue_result_table.R — Week 6: contingency tables and log-linear models
# Owner: Zack
# Question: is Ashford's match result (W/D/L) associated with playing at home
# or away, and does that association hold once opponent strength is allowed for?
#   Part 1: 2 x 3 table of home_away by result, chi-squared test of association
#   Part 2: the same question as a log-linear (Poisson) model
#   Part 3: odds ratios for W v L and D v L, home v away, with 95% CIs
#   Part 4: link to the binomial win model (win v not win)
#   Part 5: exploratory three-way table, rank_band x home_away x result
#   Part 6: collapsibility: conditional v marginal odds ratios
#   Part 7: plot of result proportions by venue, overall and by rank band
# Lecture references: weeks 6 and 8 slides (contingency tables):
#   7-9 chi-squared test; 10-19 sampling schemes and the logistic / log-linear
#   connection; 21-23 log-linear model selection and interpretation;
#   26-31 three-way tables and sub-models; 40 tables with a response;
#   41-45 partial / marginal tables and collapsibility; 46-49 independence graphs.
# Base R only. Run from the project folder (open the .Rproj first).
# The data are not changed: bands and the unordered result factor are made
# here, in this script, and are not added to 00_load_data.R.

source("code/00_load_data.R")

# result is an ORDERED factor in 00_load_data.R, so glm() would code it with
# polynomial contrasts (.L, .Q). For tables we want ordinary comparisons with
# a baseline, so use an unordered copy with L (loss) as the baseline.
matches$result_u <- factor(matches$result, levels = c("L", "D", "W"),
                           ordered = FALSE)

# Opponent-rank bands, the same cut points as the grouped check in 04e.
matches$rank_band <- cut(matches$opponent_rank, breaks = c(0, 8, 16, 24),
                         labels = c("1-8", "9-16", "17-24"))

# Helper: odds ratios with 95% profile-likelihood CIs for chosen terms
or_table <- function(model, terms) {
  ci <- suppressMessages(confint(model))
  data.frame(term     = terms,
             OR       = round(exp(coef(model)[terms]), 3),
             lower_95 = round(exp(ci[terms, 1]), 3),
             upper_95 = round(exp(ci[terms, 2]), 3),
             p_wald   = signif(summary(model)$coefficients[terms, 4], 3),
             row.names = NULL)
}

# =============================================================================
# PART 1: TWO-WAY TABLE AND CHI-SQUARED TEST (slides 7-9)
# =============================================================================
tab_vr <- xtabs(~ home_away + result_u, data = matches)
tab_vr
#           L  D  W
#   Home    3  5 15
#   Away   10  6  7

# Row proportions: the result distribution at each venue
round(prop.table(tab_vr, 1), 3)
# Home: 13% L, 22% D, 65% W.  Away: 43% L, 26% D, 30% W.

# correct = FALSE: no continuity correction, as on slide 9 (R only applies
# one to 2 x 2 tables, but we set it explicitly so all our tables match).
chi_vr <- chisq.test(tab_vr, correct = FALSE)
chi_vr
chi_vr$expected
# X^2 = 6.77 on (2 - 1)(3 - 1) = 2 df, p = 0.034.
# Expected counts are 6.5 (L), 5.5 (D) and 11 (W) at each venue: all at least 5,
# so the chi-squared approximation is reasonable here (the "at least 5" rule
# is a standard guideline, not from the slides).
# Conclusion: at the 5% level there is evidence that result and venue are not
# independent, i.e. the distribution of W/D/L differs between home and away.
# Largest Pearson residuals (chi_vr$residuals): home losses below expected
# (-1.37), away losses above (+1.37), home wins above (+1.21), away wins below
# (-1.21). Draws are close to expected (+/-0.21), so the association is
# mainly wins v losses.

# Save the table with expected counts and Pearson residuals
vr_out <- data.frame(home_away = rep(rownames(tab_vr), times = ncol(tab_vr)),
                     result    = rep(colnames(tab_vr), each = nrow(tab_vr)),
                     observed  = as.vector(tab_vr),
                     expected  = round(as.vector(chi_vr$expected), 2),
                     pearson_resid = round(as.vector(chi_vr$residuals), 2))
vr_out
write.csv(vr_out, "outputs/table_venue_result.csv", row.names = FALSE)

# =============================================================================
# PART 2: THE SAME QUESTION AS A LOG-LINEAR MODEL (slides 16-18, 21)
# =============================================================================
# One row per cell, count in Freq. Ashford play 23 home and 23 away matches by
# design (every opponent twice), so the home_away margin is fixed and the
# home_away main effect must stay in every model (slide 16). Result is the
# response, so the association is tested by the home_away:result interaction.
d_vr <- as.data.frame(tab_vr)
d_vr

m_sat_vr <- glm(Freq ~ home_away * result_u, family = poisson, data = d_vr)
m_ind_vr <- glm(Freq ~ home_away + result_u, family = poisson, data = d_vr)
summary(m_sat_vr)            # saturated: 6 parameters, 6 cells, deviance 0

lrt_vr <- anova(m_ind_vr, m_sat_vr, test = "Chisq")
lrt_vr
# Deviance (G^2) of the independence model = 7.04 on 2 df, p = 0.030.
# The independence model's Pearson X^2 is the chi-squared statistic from
# Part 1 exactly (6.77): the chi-squared test of association is a test of the
# independence log-linear model. The LRT and X^2 are asymptotically
# equivalent and agree here (p = 0.030 v 0.034).
sum(residuals(m_ind_vr, type = "pearson")^2)     # 6.769, same as chi_vr

test_vr <- data.frame(
  test      = c("Pearson chi-squared (chisq.test)",
                "Likelihood ratio, home_away:result (log-linear)"),
  statistic = round(c(unname(chi_vr$statistic), lrt_vr$Deviance[2]), 3),
  df        = c(unname(chi_vr$parameter), lrt_vr$Df[2]),
  p_value   = signif(c(chi_vr$p.value, lrt_vr[2, "Pr(>Chi)"]), 3))
test_vr
write.csv(test_vr, "outputs/venue_result_tests.csv", row.names = FALSE)

# =============================================================================
# PART 3: ODDS RATIOS (slides 17, 23)
# =============================================================================
# In the saturated model exp(home_awayAway:result_uW) is the odds ratio
#   (odds of W rather than L away) / (odds of W rather than L at home)
#   = (7 x 3) / (15 x 10) = 0.14,
# and it reads both ways ("and vice versa", slide 23): the odds of a match
# being away rather than at home are 0.14 times as high for wins as for losses.
or_vr <- or_table(m_sat_vr, c("home_awayAway:result_uD",
                              "home_awayAway:result_uW"))
or_vr$comparison <- c("D v L, away v home", "W v L, away v home")
or_vr
# W v L: OR 0.14 (95% CI 0.02 to 0.62). Away matches are associated with much
#   lower odds of a win rather than a loss. The interval excludes 1, but it is
#   wide: only 46 matches.
# D v L: OR 0.36 (95% CI 0.06 to 2.01). The interval includes 1, so there is
#   no clear evidence that the draw-v-loss split differs by venue.
c(check_W_v_L = (7 * 3) / (15 * 10))             # 0.14, matches exp(coef)
write.csv(or_vr, "outputs/venue_result_odds_ratios.csv", row.names = FALSE)

# =============================================================================
# PART 4: LINK TO THE BINOMIAL WIN MODEL (slides 13-18)
# =============================================================================
# Collapse D and L into "not win". The log-linear interaction for the 2 x 2
# table should equal the home_away coefficient of a logistic model for win,
# because the binomial is the Poisson conditioned on the row totals (slide 19).
matches$win_f <- factor(ifelse(matches$result_u == "W", "W", "notW"),
                        levels = c("notW", "W"))
d_win <- as.data.frame(xtabs(~ home_away + win_f, data = matches))
m_win_ll  <- glm(Freq ~ home_away * win_f, family = poisson, data = d_win)
m_win_bin <- glm(I(win_f == "W") ~ home_away, family = binomial, data = matches)

win_link <- data.frame(
  model    = c("log-linear: home_awayAway:win_fW", "logistic: home_awayAway"),
  estimate = round(c(coef(m_win_ll)["home_awayAway:win_fW"],
                     coef(m_win_bin)["home_awayAway"]), 4),
  se       = round(c(summary(m_win_ll)$coefficients["home_awayAway:win_fW", 2],
                     summary(m_win_bin)$coefficients["home_awayAway", 2]), 4))
win_link$OR <- round(exp(win_link$estimate), 3)
win_link
# Identical estimates and SEs: OR 0.23 for a win away v home (venue alone).
# 04e gave OR 0.20 for away once opponent_rank is in the model as a number;
# the two answer slightly different questions (marginal v adjusted for rank).
write.csv(win_link, "outputs/venue_win_loglinear_vs_logistic.csv",
          row.names = FALSE)

# =============================================================================
# PART 5: EXPLORATORY THREE-WAY TABLE, rank_band x home_away x result
# (slides 26-31, 40)
# =============================================================================
tab_rvr <- xtabs(~ rank_band + home_away + result_u, data = matches)
ftable(tab_rvr)
# 18 cells for 46 matches. Each rank band holds the same opponents home and
# away (8 / 7 / 8 matches at each venue), so the rank_band x home_away margin
# is fixed by design and rank_band:home_away must stay in every model (slides
# 16 and 40). With result as the response, the questions are the two
# interactions with result_u.
d_rvr <- as.data.frame(tab_rvr)

# Step 1: saturated model, test the three-way interaction
m3_sat <- glm(Freq ~ rank_band * home_away * result_u, family = poisson,
              data = d_rvr)
drop1(m3_sat, test = "Chisq")
# Three-way term: LRT 1.48 on 4 df, p = 0.83. No evidence that the venue-result
# association differs between rank bands, so the three-way term is dropped.

# Step 2: all two-way interactions
m3_two <- update(m3_sat, . ~ . - rank_band:home_away:result_u)
drop1(m3_two, test = "Chisq")
# home_away:result_u: LRT 7.92 on 2 df, p = 0.019 -> keep.
# rank_band:result_u: LRT 7.97 on 4 df, p = 0.093 -> weak evidence only.
# rank_band:home_away: fixed by design, kept whatever its p-value (0.64).

# Step 3: drop rank_band:result_u (p = 0.093 > 0.05). This model says rank
# band and result are conditionally independent given venue.
m3_final <- update(m3_two, . ~ . - rank_band:result_u)
drop1(m3_final, test = "Chisq")
# home_away:result_u still needed: LRT 7.04 on 2 df, p = 0.030 (the same as
# the 2 x 3 table in Part 2, as expected once rank_band:result_u is gone).
# rank_band:home_away shows LRT 0 here because the design makes it exact; it
# stays in regardless. AIC: 76.06 v 76.09 for the all-two-way model, so the
# simpler model costs nothing on AIC either.
c(deviance = deviance(m3_final), df = df.residual(m3_final),
  p_gof = 1 - pchisq(deviance(m3_final), df.residual(m3_final)))
# Final model: Freq ~ rank_band*home_away + home_away*result_u,
# deviance 9.45 on 8 df (p = 0.31): no evidence of lack of fit.

# Conditional independence of venue and result given rank band (slide 29):
m3_ci <- glm(Freq ~ rank_band * home_away + rank_band * result_u,
             family = poisson, data = d_rvr)
anova(m3_ci, m3_two, test = "Chisq")
# Deviance 9.40 on 6 df for the conditional-independence model; adding
# home_away:result_u reduces it by 7.92 on 2 df (p = 0.019). So venue and
# result are NOT conditionally independent given opponent strength: the home
# advantage in results is still there within rank bands.

sel_tab <- data.frame(
  step  = c("Saturated", "Drop three-way",
            "Drop rank_band:result (final)",
            "Conditional independence of venue and result given rank"),
  model = c("rank_band*home_away*result",
            "all two-way interactions",
            "rank_band*home_away + home_away*result",
            "rank_band*home_away + rank_band*result"),
  deviance = round(c(deviance(m3_sat), deviance(m3_two),
                     deviance(m3_final), deviance(m3_ci)), 3),
  df       = c(df.residual(m3_sat), df.residual(m3_two),
               df.residual(m3_final), df.residual(m3_ci)),
  AIC      = round(c(AIC(m3_sat), AIC(m3_two), AIC(m3_final), AIC(m3_ci)), 2))
sel_tab$p_gof <- signif(ifelse(sel_tab$df > 0,
                               1 - pchisq(sel_tab$deviance, sel_tab$df), NA), 3)
sel_tab
write.csv(sel_tab, "outputs/venue_result_loglinear_selection.csv",
          row.names = FALSE)

# Small cells: how reliable is the chi-squared approximation here?
fit3 <- fitted(m3_final)
c(cells = length(fit3), expected_below_5 = sum(fit3 < 5),
  expected_below_1 = sum(fit3 < 1), min_expected = round(min(fit3), 2))
# 16 of 18 expected counts are below 5 (smallest 0.91), so the deviance / LRT
# p-values above are approximate and should be read as exploratory, not as
# firm tests.

rvr_out <- cbind(d_rvr[, c("rank_band", "home_away", "result_u")],
                 observed = d_rvr$Freq,
                 fitted_final = round(fit3, 2),
                 std_dev_resid = round(rstandard(m3_final), 2))
names(rvr_out)[3] <- "result"
rvr_out
max(abs(rvr_out$std_dev_resid))
# Largest |standardised deviance residual| = 2.02 (one cell of 18), so no cell
# is badly fitted by the final model.
write.csv(rvr_out, "outputs/table_rank_venue_result.csv", row.names = FALSE)

# Interpretation, rank_band:result (dropped, p = 0.093): the directions are as
# expected (fewer losses against weaker opponents), but with 3 bands and 46
# matches the evidence is weak. 04e, with rank as a number, also found only
# weak evidence for opponent rank (p = 0.059). Banding throws information
# away, so this is not evidence that rank does not matter.

# =============================================================================
# PART 6: COLLAPSIBILITY (slides 41-45, 46-49)
# =============================================================================
# Independence graph of the final model:  rank_band --- home_away --- result
# (graph 2 on slide 49): home_away separates rank_band from result. So
# collapsing over rank_band does not change the venue-result odds ratios
# (slides 45 and 49): the conditional ORs equal the marginal ORs from Part 3.
# In the all-two-way model (rank_band:result kept), rank is not conditionally
# independent of either venue or result, so collapsibility is not guaranteed.
or_marg  <- or_table(m_sat_vr, c("home_awayAway:result_uD",
                                 "home_awayAway:result_uW"))
or_final <- or_table(m3_final, c("home_awayAway:result_uD",
                                 "home_awayAway:result_uW"))
or_two   <- or_table(m3_two,   c("home_awayAway:result_uD",
                                 "home_awayAway:result_uW"))
coll_tab <- data.frame(
  comparison = c("D v L, away v home", "W v L, away v home"),
  marginal_OR          = or_marg$OR,
  marginal_95CI        = paste(or_marg$lower_95, "to", or_marg$upper_95),
  final_model_OR       = or_final$OR,
  final_model_95CI     = paste(or_final$lower_95, "to", or_final$upper_95),
  all_two_way_OR       = or_two$OR,
  all_two_way_95CI     = paste(or_two$lower_95, "to", or_two$upper_95))
coll_tab
# Final model: identical to the marginal ORs (0.36 and 0.14), as collapsibility
# says. All-two-way model (adjusting for rank band): W v L OR 0.10 (CI excludes
# 1), D v L 0.27. Allowing for opponent strength makes the away effect on
# wins slightly stronger, not weaker, so the marginal 2 x 2 x 3 summary does
# not overstate the home advantage.
write.csv(coll_tab, "outputs/venue_result_marginal_vs_conditional_or.csv",
          row.names = FALSE)

# =============================================================================
# PART 7: PLOT — result proportions by venue, overall and within rank bands
# =============================================================================
# 100% stacked bars. Result is ordinal, so it uses a diverging scheme:
# loss (orange) - draw (neutral grey) - win (blue). Counts are written in
# each segment, so the plot does not rely on colour alone.
res_cols <- c(L = "#eb6834", D = "#b8b7b0", W = "#2a78d6")
panels <- c("All matches", "Rank 1-8", "Rank 9-16", "Rank 17-24")
cnt <- list(tab_vr,
            tab_rvr["1-8", , ], tab_rvr["9-16", , ], tab_rvr["17-24", , ])

png("outputs/venue_result_by_rank.png", width = 1600, height = 900, res = 150)
par(mfrow = c(1, 4), mar = c(4, 2.5, 3, 0.5), oma = c(3.5, 2, 2.5, 0),
    las = 1, cex.axis = 0.9, col.axis = "grey30", fg = "grey60")
for (k in seq_along(cnt)) {
  ct <- t(cnt[[k]])                    # rows L, D, W; columns Home, Away
  pr <- prop.table(ct, 2)
  bp <- barplot(pr, col = res_cols[rownames(ct)], border = "white", lwd = 2,
                ylim = c(0, 1), axes = FALSE, space = 0.35,
                names.arg = rep("", ncol(ct)))
  mtext(paste0(colnames(ct), "\n(n = ", colSums(ct), ")"), side = 1,
        at = bp, line = 1.8, cex = 0.8, col = "grey25")
  axis(2, at = seq(0, 1, 0.25), labels = if (k == 1)
       paste0(seq(0, 100, 25), "%") else FALSE, col = "grey80")
  mids <- apply(pr, 2, function(p) cumsum(p) - p / 2)
  for (j in seq_len(ncol(ct))) {
    for (i in seq_len(nrow(ct))) {
      if (ct[i, j] > 0) text(bp[j], mids[i, j], ct[i, j],
                             col = ifelse(rownames(ct)[i] == "D", "grey15",
                                          "white"), font = 2)
    }
  }
  title(main = panels[k], font.main = 1, cex.main = 1.1, col.main = "grey15")
}
mtext("Ashford United results by venue: share of matches (counts in bars)",
      side = 3, outer = TRUE, line = 0.8, cex = 1.05, col = "grey15")
par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("bottom", legend = c("Loss", "Draw", "Win"), fill = res_cols,
       border = "white", horiz = TRUE, bty = "n", cex = 0.95,
       text.col = "grey20", inset = 0.01)
dev.off()

# =============================================================================
# SUMMARY (for decision-notes)
# =============================================================================
# - Venue x result (46 matches): X^2 = 6.77 on 2 df, p = 0.034 (all expected
#   counts >= 5.5). Evidence that the result distribution differs by venue.
# - Odds of a win rather than a loss away are 0.14 times those at home
#   (95% CI 0.02 to 0.62). Draw v loss: OR 0.36 (0.06 to 2.01), no clear
#   difference.
# - Three-way table with opponent-rank band: no three-way interaction
#   (p = 0.83); venue and result are not conditionally independent given rank
#   band (LRT 7.92 on 2 df, p = 0.019); rank band and result only weakly
#   associated (p = 0.093). Final model rank*venue + venue*result has
#   independence graph rank - venue - result, so the 2 x 3 venue-result table
#   can be analysed on its own (collapsibility).
# - Caveats: small sample and many tiny cells in the three-way table, so the
#   p-values are approximate; matches are paired by opponent; the log-linear
#   model ignores the L < D < W ordering (week 10 ordinal model). These are
#   associations, not causal effects.
