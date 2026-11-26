# 09a_result_ordinal.R — Week 9: proportional-odds model for Ashford's results
# Owner: Zack
# Question (report Q3): how do venue and opponent strength shift Ashford's
# chances of losing, drawing and winning?
#   Part 1: why an ordinal model, and the sign convention in MASS::polr
#   Part 2: model selection (LRTs and AIC): venue, rank, interaction, log rank
#   Part 3: final model: cumulative odds ratios with 95% profile CIs
#   Part 4: proportional-odds check: empirical cumulative logits, separate
#           binary logits, and an LRT against the multinomial model (nnet)
#   Part 5: goodness of fit: observed v fitted counts by venue x rank band;
#           link functions; leave-one-out influence (incl. the 8-0)
#   Part 6: fitted P(L), P(D), P(W) home and away at ranks 1, 12, 24, and plot
#   Part 7: comparison with 06e (table), 04e (binary win), 09c (matched pairs)
# Lecture references: week 9 slides (ordinal responses, proportional odds,
#   cumulative logits, the multinomial comparison).
# Packages: MASS (polr) and nnet (multinom), both come with R.
# Run from the project folder (open the .Rproj first).

source("code/00_load_data.R")
library(MASS)
library(nnet)

# opponent_rank is the opponent's final league position: 1 = strongest,
# 24 = weakest. Ashford play each of the 23 opponents once home, once away.
# result is the ordered factor L < D < W made in 00_load_data.R.

# =============================================================================
# PART 1: WHY AN ORDINAL MODEL, AND THE SIGN CONVENTION
# =============================================================================
table(matches$home_away, matches$result)
#        L  D  W
#   Home 3  5 15
#   Away 10 6  7
# 06e treated result as nominal (two ORs per term: D v L, W v L) and 04e
# collapsed it to win / not win (throws away the L v D distinction). The
# outcome is ordered, so a proportional-odds (cumulative logit) model uses the
# ordering with ONE coefficient per term:
#   logit P(result <= j) = zeta_j - (b1 * Away + b2 * opponent_rank),  j = L, D
# MASS::polr uses this "minus" parameterisation. So a POSITIVE coefficient
# moves results UP the scale (towards W), and exp(b) is the odds ratio for a
# BETTER result: the odds of (W) v (D or L), and equally of (D or W) v (L).
# An away OR below 1 means worse results away.

# =============================================================================
# PART 2: MODEL SELECTION
# =============================================================================
m_null  <- polr(result ~ 1, data = matches, Hess = TRUE)
m_venue <- polr(result ~ home_away, data = matches, Hess = TRUE)
m_rank  <- polr(result ~ opponent_rank, data = matches, Hess = TRUE)
m_main  <- polr(result ~ home_away + opponent_rank, data = matches, Hess = TRUE)
m_int   <- polr(result ~ home_away * opponent_rank, data = matches, Hess = TRUE)
m_log   <- polr(result ~ home_away + log(opponent_rank), data = matches,
                Hess = TRUE)

lrt <- function(small, big, label) {
  stat <- deviance(small) - deviance(big)
  df   <- big$edf - small$edf
  data.frame(test = label, LRT = round(stat, 3), df = df,
             p_value = signif(pchisq(stat, df, lower.tail = FALSE), 3))
}

selection <- data.frame(
  model    = c("1", "home_away", "opponent_rank", "home_away + opponent_rank",
               "home_away * opponent_rank", "home_away + log(opponent_rank)"),
  n_par    = sapply(list(m_null, m_venue, m_rank, m_main, m_int, m_log),
                    function(m) m$edf),
  deviance = round(sapply(list(m_null, m_venue, m_rank, m_main, m_int, m_log),
                          deviance), 3),
  AIC      = round(sapply(list(m_null, m_venue, m_rank, m_main, m_int, m_log),
                          AIC), 2)
)
selection
#   model                          n_par deviance    AIC
#   1                                  2   96.787 100.79
#   home_away                          3   89.816  95.82
#   opponent_rank                      3   90.498  96.50
#   home_away + opponent_rank          4   82.873  90.87   <- lowest AIC
#   home_away * opponent_rank          5   82.597  92.60
#   home_away + log(opponent_rank)     4   83.138  91.14

tests <- rbind(
  lrt(m_rank,  m_main, "drop home_away from main effects"),
  lrt(m_venue, m_main, "drop opponent_rank from main effects"),
  lrt(m_main,  m_int,  "add home_away:opponent_rank")
)
tests
#   drop home_away        LRT 7.625 on 1 df, p = 0.0058
#   drop opponent_rank    LRT 6.943 on 1 df, p = 0.0084
#   add interaction       LRT 0.275 on 1 df, p = 0.60
# Decision: both main effects are needed (each LRT p < 0.01) and the
# interaction is not (p = 0.60, AIC rises 90.87 -> 92.60): there is no
# evidence that the venue effect changes with opponent strength. Linear rank
# is preferred to log rank (AIC 90.87 v 91.14; not nested, so AIC only), the
# same choice as for goals scored in 06b. Final model: m_main.

write.csv(cbind(selection,
                rbind(NA, NA, NA, NA,
                      tests[3, c("LRT", "df", "p_value")],
                      NA)),
          "outputs/result_ordinal_selection.csv", row.names = FALSE)
write.csv(tests, "outputs/result_ordinal_lrt.csv", row.names = FALSE)

# =============================================================================
# PART 3: FINAL MODEL — CUMULATIVE ODDS RATIOS
# =============================================================================
summary(m_main)
#                 Value  Std. Error t value
#   home_awayAway -1.659   0.627    -2.647
#   opponent_rank  0.118   0.047     2.518
#   L|D           -0.481   0.712
#   D|W            0.827   0.712

ci_main <- suppressMessages(confint(m_main))   # profile likelihood
or_main <- data.frame(
  term     = names(coef(m_main)),
  estimate = round(coef(m_main), 4),
  se       = round(sqrt(diag(vcov(m_main)))[names(coef(m_main))], 4),
  OR       = round(exp(coef(m_main)), 3),
  lower_95 = round(exp(ci_main[, 1]), 3),
  upper_95 = round(exp(ci_main[, 2]), 3),
  LRT_p    = tests$p_value[1:2],
  row.names = NULL
)
or_main
#   home_awayAway  OR 0.190 (0.052-0.625)
#   opponent_rank  OR 1.125 (1.030-1.240) per place down the table
# Interpretation (association, not cause): for a given opponent rank, the
# odds of a better result away are about 0.19 times those at home, i.e. the
# odds of a worse result away are about 1/0.19 = 5.3 times higher (95% CI
# 1.6 to 19). Each place further down the table the opponent finished
# multiplies the odds of a better result by 1.125 (CI 1.03 to 1.24), so
# 10 places is about 1.125^10 = 3.2 times. Under proportional odds the same
# OR applies to "W v D or L" and to "D or W v L".
write.csv(or_main, "outputs/result_ordinal_odds_ratios.csv", row.names = FALSE)

# =============================================================================
# PART 4: PROPORTIONAL-ODDS CHECK
# =============================================================================
# (a) Empirical cumulative logits by venue (week 9 slides): under PO the
# home - away difference should be the same at both cut points.
# cumulative proportions P(L), P(L or D) in each row of a table (each row
# divided by its own total), then logits
cum_logits <- function(tab) {
  cp <- t(apply(tab, 1, cumsum)) / rowSums(tab)
  qlogis(cp[, 1:2, drop = FALSE])
}
cl_venue <- cum_logits(table(matches$home_away, matches$result))
colnames(cl_venue) <- c("logit P(L)", "logit P(L or D)")
cl_venue
#          logit P(L)  logit P(L or D)
#   Home     -1.897        -0.629
#   Away     -0.262         0.827
cl_venue["Home", ] - cl_venue["Away", ]
# Differences -1.63 and -1.46: very close, consistent with one venue
# coefficient (the model's -1.66 sits between them).

matches$rank_band <- cut(matches$opponent_rank, breaks = c(0, 8, 16, 24),
                         labels = c("1-8", "9-16", "17-24"))
cl_band <- cum_logits(table(matches$rank_band, matches$result))
colnames(cl_band) <- c("logit P(L)", "logit P(L or D)")
cl_band
#           logit P(L)  logit P(L or D)
#   1-8        0.000         0.511
#   9-16      -1.299         0.288
#   17-24     -1.946        -0.511
# Both columns fall as opponents get weaker, in the same direction. The drop
# from band 1-8 to 17-24 is 1.95 at the first cut and 1.02 at the second:
# less parallel than for venue, but each band has only 14-16 matches (and
# band 1-8 has 2 draws), so this is weak evidence either way. (b) and (c) test it.

# (b) Separate binary logistic models at each cut point. Under PO the slopes
# should be similar (the intercepts differ).
b_LD <- glm(I(result >= "D") ~ home_away + opponent_rank, family = binomial,
            data = matches)   # D or W v L
b_DW <- glm(I(result == "W") ~ home_away + opponent_rank, family = binomial,
            data = matches)   # W v D or L (the 04e win model)
cut_slopes <- rbind(`D or W v L` = coef(b_LD)[-1],
                    `W v D or L` = coef(b_DW)[-1],
                    `polr (common)` = coef(m_main))
round(cut_slopes, 3)
#                  home_awayAway  opponent_rank
#   D or W v L        -2.010         0.163
#   W v D or L        -1.587         0.088
#   polr (common)     -1.659         0.118
# The separate slopes have the same signs and the common estimate sits
# between them. The binary fits have SEs of 0.67-0.86 (venue) and
# 0.049-0.064 (rank), so the differences between cut points (0.42 and 0.075)
# are about one standard error or less: no clear sign of non-proportionality.

# (c) LRT of proportional odds against the multinomial (baseline-category)
# model with the same predictors, which lets every term differ by category.
# polr is not strictly nested in multinom, but this is the comparison used
# in the lecture: 2 extra parameters.
m_multi <- multinom(result ~ home_away + opponent_rank, data = matches,
                    trace = FALSE)
po_stat <- deviance(m_main) - deviance(m_multi)
po_df   <- (length(coef(m_multi)) - 2) - length(coef(m_main))  # 6 - 2 - 2 = 2
po_test <- data.frame(
  model    = c("polr (proportional odds)", "multinom (nominal)"),
  n_par    = c(m_main$edf, length(coef(m_multi))),
  deviance = round(c(deviance(m_main), deviance(m_multi)), 3),
  AIC      = round(c(AIC(m_main), AIC(m_multi)), 2),
  LRT      = c(NA, round(po_stat, 3)),
  df       = c(NA, po_df),
  p_value  = c(NA, signif(pchisq(po_stat, po_df, lower.tail = FALSE), 3))
)
po_test
#   polr      4 par  deviance 82.873  AIC 90.87
#   multinom  6 par  deviance 81.115  AIC 93.11   LRT 1.758 on 2 df, p = 0.42
# Decision: no evidence against proportional odds (p = 0.42), and the
# multinomial model's AIC is higher. Keep polr: it is simpler (one OR per
# term) and uses the ordering. All three checks agree.
write.csv(po_test, "outputs/result_ordinal_po_check.csv", row.names = FALSE)
write.csv(data.frame(cut = rownames(cut_slopes), round(cut_slopes, 4),
                     row.names = NULL),
          "outputs/result_ordinal_cut_slopes.csv", row.names = FALSE)

# =============================================================================
# PART 5: GOODNESS OF FIT, LINK, INFLUENCE
# =============================================================================
# (a) Observed v fitted counts in the 6 venue x rank-band groups (same bands
# as 04e and 06e). Expected counts are small (0.4-6.6), so the Pearson
# statistic is only a rough guide; df ~ 6 groups x 2 free cells - 4 par = 8.
grp      <- interaction(matches$home_away, matches$rank_band, sep = " ")
fitted_c <- rowsum(fitted(m_main), grp)
obs_c    <- as.matrix(as.data.frame.matrix(table(grp, matches$result)))
gof <- data.frame(group = rownames(obs_c),
                  obs_L = obs_c[, "L"], fit_L = round(fitted_c[, "L"], 2),
                  obs_D = obs_c[, "D"], fit_D = round(fitted_c[, "D"], 2),
                  obs_W = obs_c[, "W"], fit_W = round(fitted_c[, "W"], 2),
                  row.names = NULL)
gof
X2_grp <- sum((obs_c - fitted_c)^2 / fitted_c)
c(X2 = round(X2_grp, 2), df = 8,
  p = round(pchisq(X2_grp, 8, lower.tail = FALSE), 2))
# X2 = 4.65 on about 8 df, p = 0.79. Observed and fitted counts agree in
# every group (largest gap: 5 home wins v 3.4 fitted against ranks 1-8).
# No evidence of lack of fit, with the small-count caveat.
write.csv(gof, "outputs/result_ordinal_obs_vs_fitted.csv", row.names = FALSE)

# (b) Link function (polr method): logit is the default and gives ORs.
links <- c("logistic", "probit", "cloglog", "loglog")
link_aic <- sapply(links, function(l)
  AIC(polr(result ~ home_away + opponent_rank, data = matches, method = l)))
round(link_aic, 2)
#   logistic 90.87  probit 90.42  cloglog 92.10  loglog 89.44
# All within 2.7 AIC of each other: the data can't distinguish the links.
# Keep the logit, which gives interpretable cumulative ORs.

# (c) Leave-one-out influence: refit without each match in turn.
loo <- t(sapply(seq_len(nrow(matches)), function(i)
  coef(polr(result ~ home_away + opponent_rank, data = matches[-i, ]))))
loo_or <- data.frame(match = seq_len(nrow(matches)),
                     home_away = matches$home_away,
                     opponent_rank = matches$opponent_rank,
                     score = paste(matches$goals_scored, matches$goals_conceded,
                                   sep = "-"),
                     result = matches$result,
                     OR_away = round(exp(loo[, "home_awayAway"]), 3),
                     OR_rank = round(exp(loo[, "opponent_rank"]), 3))
range(loo_or$OR_away)   # 0.152 to 0.210
range(loo_or$OR_rank)   # 1.111 to 1.146
loo_or[which.min(loo_or$OR_away), ]
# Most influential: match 15, home 0-1 v rank 11 (a home loss); without it
# the away OR is 0.15. Dropping any single match leaves the away OR between
# 0.15 and 0.21 and the rank OR between 1.11 and 1.15: no single match drives
# the result.
loo_or[matches$goals_scored == 8, ]
# The 8-0 (home v rank 24): without it the away OR is 0.197 (0.190 with it).
# An ordinal model only uses W/D/L, so a big margin counts as one win; the
# 8-0 that dominated the Poisson goals model (05e: Cook's 0.64) has almost no
# influence here. Useful contrast for the report.
write.csv(loo_or, "outputs/result_ordinal_leave_one_out.csv", row.names = FALSE)

# =============================================================================
# PART 6: FITTED PROBABILITIES AND PLOT
# =============================================================================
nd <- expand.grid(home_away = factor(c("Home", "Away"),
                                     levels = levels(matches$home_away)),
                  opponent_rank = c(1, 12, 24))
pred_tab <- cbind(nd, round(predict(m_main, nd, type = "probs"), 3))
pred_tab
#   Home rank  1: L 0.355  D 0.316  W 0.330
#   Away rank  1: L 0.743  D 0.172  W 0.086
#   Home rank 12: L 0.130  D 0.226  W 0.643
#   Away rank 12: L 0.441  D 0.304  W 0.255
#   Home rank 24: L 0.035  D 0.084  W 0.881
#   Away rank 24: L 0.161  D 0.254  W 0.586
# Against a mid-table side (rank 12), the fitted chance of winning is 64% at
# home v 26% away, and of losing 13% v 44%. Draws change least (23% v 30%).
write.csv(pred_tab, "outputs/result_ordinal_predicted_probs.csv",
          row.names = FALSE)

# Plot: fitted P(L), P(D), P(W) v opponent rank, home and away, with observed
# proportions by rank band. Saved for report Figure 3.
grid <- expand.grid(opponent_rank = 1:24,
                    home_away = factor(c("Home", "Away"),
                                       levels = levels(matches$home_away)))
grid_p <- cbind(grid, predict(m_main, grid, type = "probs"))
band_mid <- c(`1-8` = 4.5, `9-16` = 12.5, `17-24` = 20.5)
obs_prop <- as.data.frame(prop.table(table(matches$home_away,
                                           matches$rank_band,
                                           matches$result), c(1, 2)))
names(obs_prop) <- c("home_away", "rank_band", "result", "prop")
cols <- c(L = "firebrick", D = "grey45", W = "darkgreen")

png("outputs/result_ordinal_fitted_probs.png", width = 1100, height = 520)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
for (v in c("Home", "Away")) {
  plot(NA, xlim = c(1, 24), ylim = c(0, 1),
       xlab = "Opponent final rank (1 = strongest)",
       ylab = "Probability", main = paste("Ashford", tolower(v), "matches"))
  for (r in c("L", "D", "W")) {
    gv <- grid_p[grid_p$home_away == v, ]
    lines(gv$opponent_rank, gv[[r]], col = cols[r], lwd = 2.5,
          lty = match(r, c("L", "D", "W")))
    ov <- obs_prop[obs_prop$home_away == v & obs_prop$result == r, ]
    points(band_mid[as.character(ov$rank_band)], ov$prop, col = cols[r],
           pch = 19, cex = 1.3)
  }
  legend("top", horiz = TRUE, bty = "n", legend = c("Loss", "Draw", "Win"),
         col = cols, lty = 1:3, lwd = 2.5, cex = 0.9)
}
dev.off()
# Lines: fitted probabilities from the proportional-odds model. Points:
# observed proportions in rank bands 1-8, 9-16, 17-24 (7-8 matches per venue
# in each band, so each point is noisy).

# =============================================================================
# PART 7: COMPARISON ACROSS THE Q3 ANALYSES (report Table 3)
# =============================================================================
# Away v home odds ratio for a better result / a win, from each analysis.
# 06e and 04e/09c values are read from their committed outputs, so this
# table updates if they change.
or_06e <- read.csv("outputs/venue_result_odds_ratios.csv")
or_04e <- read.csv("outputs/win_odds_ratios.csv")
or_09c <- read.csv("outputs/win_conditional_logistic.csv")
or_06e
or_04e
or_09c

comparison <- data.frame(
  analysis = c("09a proportional odds: better result (adj. for rank)",
               "04e logistic: win v not win (adj. for rank)",
               "09c conditional logistic: win, opponent as stratum"),
  OR_away  = c(or_main$OR[1],
               round(or_04e[grep("Away", or_04e[, 1]), 2], 3),
               round(or_09c$OR[1], 3)),
  lower_95 = c(or_main$lower_95[1],
               round(or_04e[grep("Away", or_04e[, 1]), 3], 3),
               round(or_09c$CI_Lower[1], 3)),
  upper_95 = c(or_main$upper_95[1],
               round(or_04e[grep("Away", or_04e[, 1]), 4], 3),
               round(or_09c$CI_Upper[1], 3))
)
comparison
#   09a polr      0.190 (0.052-0.625)
#   04e logistic  0.205 (0.050-0.723)
#   09c clogit    0.273 (0.076-0.978)
# The three analyses agree: away results are worse. polr gives the narrowest
# interval because it also uses the L v D distinction (draws are
# information, not lost by collapsing to win / not win). 09c is wider
# because only the 14 discordant opponent pairs contribute, but it does not
# assume a linear rank effect. 06e's two nominal ORs (W v L and D v L, no
# rank adjustment) are in venue_result_odds_ratios.csv; 09b (McNemar and the
# 3 x 3 square table, Liha) will be added here when it is committed.
write.csv(comparison, "outputs/result_away_or_comparison.csv",
          row.names = FALSE)
