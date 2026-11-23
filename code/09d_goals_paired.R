# 09d_goals_paired.R - Week 9: paired goals analysis
# Owner: Liri Bylykbashi
# Question: does Ashford score at a different rate away than at home when the
# same opponent is compared, and how much does the 8-0 affect that comparison?
# Lecture reference: week 9 matched-pairs material and the Bradley-Terry
# discussion. Comparison models: 05e and 06b.
# Base R only. Run from the project folder (open the .Rproj first).

source("code/00_load_data.R")

# =============================================================================
# 1. BUILD AND CHECK THE 23 MATCHED OPPONENT PAIRS
# =============================================================================

pair_counts <- table(matches$opponent_rank, matches$home_away)
stopifnot(nrow(pair_counts) == 23L,
          all(pair_counts[, "Home"] == 1L),
          all(pair_counts[, "Away"] == 1L))

home_matches <- matches[matches$home_away == "Home",
                        c("opponent_rank", "goals_scored")]
away_matches <- matches[matches$home_away == "Away",
                        c("opponent_rank", "goals_scored")]

paired_goals <- merge(home_matches, away_matches, by = "opponent_rank",
                      suffixes = c("_home", "_away"), sort = TRUE)
paired_goals$total_goals <- paired_goals$goals_scored_home +
  paired_goals$goals_scored_away
paired_goals$home_minus_away <- paired_goals$goals_scored_home -
  paired_goals$goals_scored_away

write.csv(paired_goals, "outputs/goals_paired_by_opponent.csv",
          row.names = FALSE)

# FINDING: all 23 opponents have exactly one home and one away fixture.
# Ashford scored 40 goals at home and 20 away. In two pairs both matches were
# 0-0, so those pairs contain no information about the home/away rate ratio.

png("outputs/goals_paired_home_vs_away.png", width = 850, height = 700)
plot(paired_goals$opponent_rank, paired_goals$goals_scored_home,
     pch = 19, cex = 1.1, col = "black",
     xlab = "Opponent final rank (1 = strongest)",
     ylab = "Goals scored by Ashford",
     main = "Home and away goals within opponent pairs",
     xlim = c(0.5, 24.5), ylim = c(0, 8.7), xaxt = "n")
axis(1, at = paired_goals$opponent_rank,
     labels = paired_goals$opponent_rank, cex.axis = 0.75)
segments(paired_goals$opponent_rank, paired_goals$goals_scored_home,
         paired_goals$opponent_rank, paired_goals$goals_scored_away,
         col = "grey70")
points(paired_goals$opponent_rank, paired_goals$goals_scored_away,
       pch = 17, cex = 1.1, col = "firebrick")
text(24, paired_goals$goals_scored_home[paired_goals$opponent_rank == 24],
     labels = "8-0", pos = 2, cex = 0.85)
legend("topleft", legend = c("Home", "Away", "Same opponent pair"),
       pch = c(19, 17, NA), lty = c(NA, NA, 1),
       col = c("black", "firebrick", "grey70"), bty = "n")
dev.off()

# =============================================================================
# 2. POISSON MODEL CONDITIONAL ON OPPONENT
# =============================================================================

# goals_scored is a count, so use a Poisson GLM with a log link. Treating
# opponent_rank as a factor gives every opponent its own intercept. The venue
# coefficient is therefore estimated only from home-away differences within
# the same opponent pair; it does not assume a linear rank effect.
paired_poisson <- glm(
  goals_scored ~ home_away + factor(opponent_rank),
  family = poisson,
  data = matches
)

paired_drop1 <- drop1(paired_poisson, test = "Chisq")
paired_rr <- exp(coef(paired_poisson)["home_awayAway"])

paired_deviance <- deviance(paired_poisson)
paired_df <- df.residual(paired_poisson)
paired_gof_p <- pchisq(paired_deviance, paired_df, lower.tail = FALSE)
paired_phi <- sum(residuals(paired_poisson, type = "pearson")^2) / paired_df

# FINDING: controlling separately for each opponent, the away/home rate ratio
# is 0.500 (95% profile CI 0.287 to 0.844). The venue LRT is 6.796 on 1 df,
# p = 0.0091. Ashford is estimated to score half as many goals away as at home
# against the same opponent; this is an association, not a causal claim.
# Model deviance is 20.176 on 22 df (rough GOF p = 0.572) and Pearson phi is
# 0.730. There is no indication of overdispersion, although the usual
# chi-squared approximation is only a guide because the counts are small.

# =============================================================================
# 3. EQUIVALENT CONDITIONAL BINOMIAL MODEL
# =============================================================================

# Conditional on each pair's total goals, home/away goals are binomial. Put
# away goals first so the fitted odds are away/home and directly equal the
# Poisson away/home rate ratio. Zero-total pairs contribute no information.
informative_pairs <- paired_goals[paired_goals$total_goals > 0, ]
paired_binomial <- glm(
  cbind(goals_scored_away, goals_scored_home) ~ 1,
  family = binomial,
  data = informative_pairs
)
paired_binom_ci <- exp(confint(paired_binomial))
# Use the conditional-binomial profile interval for both equivalent forms.
# Profiling the 23 opponent intercepts directly warns for the two 0-0 pairs,
# whose opponent intercepts tend to minus infinity; they contain no venue
# information and do not affect this interval.
paired_ci <- paired_binom_ci

equivalence <- data.frame(
  method = c("Poisson with opponent fixed effects",
             "Binomial conditional on pair totals"),
  log_away_home = c(unname(coef(paired_poisson)["home_awayAway"]),
                    unname(coef(paired_binomial)[1])),
  away_home_ratio = c(paired_rr, exp(coef(paired_binomial)[1])),
  lower_95 = c(paired_ci[1], paired_binom_ci[1]),
  upper_95 = c(paired_ci[2], paired_binom_ci[2])
)
equivalence[, -1] <- round(equivalence[, -1], 6)
write.csv(equivalence, "outputs/goals_paired_model_equivalence.csv",
          row.names = FALSE)

# FINDING: both formulations give the same log ratio (-0.693147), rate ratio
# (0.500000) and profile CI (0.286679 to 0.844365). This confirms that the
# opponent-factor Poisson coefficient is a within-opponent comparison.

# =============================================================================
# 4. SENSITIVITY ANALYSIS WITHOUT THE 8-0 OPPONENT PAIR
# =============================================================================

row_8nil <- which(matches$home_away == "Home" & matches$goals_scored == 8L)
stopifnot(length(row_8nil) == 1L)
rank_8nil <- matches$opponent_rank[row_8nil]

# A matched analysis needs both fixtures in a pair. Removing only the 8-0
# leaves its opponent with no home match, so the paired sensitivity analysis
# omits that opponent's home and away fixtures. The unmatched 45-match model
# from 05e is also refitted below for comparison.
matches_without_pair <- matches[matches$opponent_rank != rank_8nil, ]
pairs_without_8nil <- paired_goals[paired_goals$opponent_rank != rank_8nil, ]

paired_poisson_no8 <- glm(
  goals_scored ~ home_away + factor(opponent_rank),
  family = poisson,
  data = matches_without_pair
)
drop1_no8 <- drop1(paired_poisson_no8, test = "Chisq")
rr_no8 <- exp(coef(paired_poisson_no8)["home_awayAway"])

informative_no8 <- pairs_without_8nil[pairs_without_8nil$total_goals > 0, ]
paired_binomial_no8 <- glm(
  cbind(goals_scored_away, goals_scored_home) ~ 1,
  family = binomial,
  data = informative_no8
)
ci_no8 <- exp(confint(paired_binomial_no8))

# Earlier 05e/06b model: linear opponent-rank adjustment rather than one
# intercept per opponent. Its 8-0 sensitivity removes only that match.
rank_adjusted <- glm(goals_scored ~ home_away + opponent_rank,
                     family = poisson, data = matches)
rank_adjusted_no8 <- glm(goals_scored ~ home_away + opponent_rank,
                         family = poisson, data = matches[-row_8nil, ])
rank_ci <- exp(confint(rank_adjusted, parm = "home_awayAway"))
rank_ci_no8 <- exp(confint(rank_adjusted_no8, parm = "home_awayAway"))

model_results <- data.frame(
  analysis = c("Paired, all 23 opponents",
               "Paired, excluding rank-24 pair containing 8-0",
               "Rank-adjusted 05e/06b model, all 46 matches",
               "Rank-adjusted 05e/06b model, excluding only 8-0"),
  n_matches = c(46, 44, 46, 45),
  complete_pairs = c(23, 22, 23, 22),
  away_home_RR = c(
    paired_rr,
    rr_no8,
    exp(coef(rank_adjusted)["home_awayAway"]),
    exp(coef(rank_adjusted_no8)["home_awayAway"])
  ),
  lower_95 = c(paired_ci[1], ci_no8[1], rank_ci[1], rank_ci_no8[1]),
  upper_95 = c(paired_ci[2], ci_no8[2], rank_ci[2], rank_ci_no8[2]),
  LRT = c(paired_drop1["home_away", "LRT"],
          drop1_no8["home_away", "LRT"], NA, NA),
  df = c(paired_drop1["home_away", "Df"],
         drop1_no8["home_away", "Df"], NA, NA),
  p_value = c(paired_drop1["home_away", "Pr(>Chi)"],
              drop1_no8["home_away", "Pr(>Chi)"], NA, NA),
  stringsAsFactors = FALSE
)
model_results[, 4:9] <- round(model_results[, 4:9], 6)
write.csv(model_results, "outputs/goals_paired_results.csv", row.names = FALSE)

fit_checks <- data.frame(
  analysis = c("All 23 opponent pairs", "Without rank-24 opponent pair"),
  residual_deviance = c(deviance(paired_poisson),
                        deviance(paired_poisson_no8)),
  residual_df = c(df.residual(paired_poisson),
                  df.residual(paired_poisson_no8)),
  rough_gof_p = c(
    pchisq(deviance(paired_poisson), df.residual(paired_poisson),
           lower.tail = FALSE),
    pchisq(deviance(paired_poisson_no8), df.residual(paired_poisson_no8),
           lower.tail = FALSE)
  ),
  pearson_phi = c(
    sum(residuals(paired_poisson, type = "pearson")^2) /
      df.residual(paired_poisson),
    sum(residuals(paired_poisson_no8, type = "pearson")^2) /
      df.residual(paired_poisson_no8)
  ),
  AIC = c(AIC(paired_poisson), AIC(paired_poisson_no8))
)
fit_checks[, -1] <- round(fit_checks[, -1], 6)
write.csv(fit_checks, "outputs/goals_paired_fit_checks.csv", row.names = FALSE)

# FINDING: after excluding the complete opponent pair containing the 8-0,
# the paired away/home RR is 0.531 (95% CI 0.289 to 0.944); LRT = 4.666 on
# 1 df, p = 0.0308. The estimated away disadvantage remains. In contrast,
# the earlier model that removes only the 8-0 but assumes a linear rank effect
# gives RR 0.586 (95% CI 0.330 to 1.017). The difference is methodological:
# a matched analysis cannot use an opponent with only one remaining fixture.

# =============================================================================
# 5. BRADLEY-TERRY DECISION
# =============================================================================

# Bradley-Terry is not used for the main analysis. A standard BT model learns
# relative team abilities from win/loss contests across a network of teams.
# Here every observed contest involves Ashford, so the data cannot identify a
# full set of league-wide relative strengths. Also, 11 of the 46 matches are
# draws, which the basic BT model does not accommodate without an extension.
# A BT home/order effect would answer essentially the same venue question as
# the home_away term, while the opponent factor above already controls for the
# paired opponent. The paired Poisson/conditional-binomial approach directly
# models the observed goal counts, retains draws and matches the report's goal
# question, so it is the more appropriate and interpretable choice.

# =============================================================================
# SUMMARY
# =============================================================================
# - 23 complete opponent pairs; totals: 40 home goals and 20 away goals.
# - Paired Poisson away/home RR 0.500 (0.287 to 0.844), LRT p = 0.0091.
# - Conditional binomial gives the identical estimate and interval.
# - Excluding the full pair containing the 8-0: RR 0.531 (0.289 to 0.944),
#   LRT p = 0.0308; the conclusion is less dependent on the 8-0 after pairing.
# - Use association language: the paired data show fewer goals away, but do
#   not by themselves establish that venue causes the difference.
# - Bradley-Terry rejected for this question; paired count modelling is more
#   appropriate for the available data and preserves draw/goal information.
