# 11b_goals_opponent_glmm.R — Week 11: Poisson GLMM for goals scored with a
# random opponent effect
# Owner: Zack
# Question (report Q2): Ashford play each opponent twice (once home, once
# away), so the two matches against the same opponent may be correlated
# beyond what opponent_rank explains. Does allowing for that change the home
# v away rate ratio or the rank effect from 06b, and how does it compare with
# Liri's fixed-opponent paired analysis (09d)?
#   Part 1: the GLM (06b final model) and the GLMM with (1 | opponent)
#   Part 2: random-effect variance, and the LRT GLMM v GLM (boundary: halve p)
#   Part 3: fixed-effect rate ratios with 95% profile CIs, GLM v GLMM v 09d
#   Part 4: 8-0 sensitivity; predicted opponent effects; fit checks
# Lecture references: week 11 slides (GLMMs, random intercepts, testing a
#   variance component on the boundary).
# Packages: lme4 (install.packages("lme4") once). Run from the project folder.

source("code/00_load_data.R")
library(lme4)

matches$opponent <- factor(matches$opponent_rank)   # 23 opponents, 2 matches each
stopifnot(all(table(matches$opponent) == 2))

# =============================================================================
# PART 1: GLM AND GLMM
# =============================================================================
m_glm <- glm(goals_scored ~ home_away + opponent_rank, family = poisson,
             data = matches)                         # 06b final model

# Random intercept for opponent: log(mu_ij) = b0 + b1*Away + b2*rank + u_j,
# u_j ~ N(0, sigma^2). Adaptive Gauss-Hermite quadrature (nAGQ = 25) is used
# for the estimates, as there are only 2 observations per opponent and the
# Laplace approximation (nAGQ = 1) can be poor with so few per group.
m_glmm <- glmer(goals_scored ~ home_away + opponent_rank + (1 | opponent),
                family = poisson, data = matches, nAGQ = 25)
summary(m_glmm)
#   Random effect: opponent variance 0.108 (SD 0.329)
#   Fixed: Away -0.693 (SE 0.274), opponent_rank 0.0508 (SE 0.0217)

# =============================================================================
# PART 2: IS THE RANDOM EFFECT NEEDED? (LRT ON THE BOUNDARY)
# =============================================================================
# WARNING (found 26/11): logLik() for a glmer Poisson fit with nAGQ > 1 is NOT
# on the same scale as glm(): lme4 drops the constant -sum(log(y!)) from the
# AGQ likelihood. Comparing them directly gives logLik -24.3 v -63.7 and a
# nonsense "LRT" of 78.8. So the marginal log-likelihood at the GLMM
# estimates is computed here by numerical integration over u_j for each
# opponent, which is on the glm scale.
marginal_loglik <- function(beta, sigma, data, X) {
  eta <- drop(X %*% beta)
  sum(sapply(split(seq_len(nrow(data)), data$opponent), function(i) {
    f <- function(u) sapply(u, function(uu)
      prod(dpois(data$goals_scored[i], exp(eta[i] + uu))) * dnorm(uu, 0, sigma))
    log(integrate(f, -Inf, Inf)$value)
  }))
}
sigma_hat <- sqrt(as.numeric(VarCorr(m_glmm)$opponent))
ll_glmm <- marginal_loglik(fixef(m_glmm), sigma_hat, matches,
                           model.matrix(m_glm))
ll_glm  <- as.numeric(logLik(m_glm))
lrt_re  <- 2 * (ll_glmm - ll_glm)
p_re    <- 0.5 * pchisq(lrt_re, 1, lower.tail = FALSE)  # 50:50 chi2_0 / chi2_1

# Cross-check with the Laplace fit, whose logLik IS on the glm scale.
m_lap   <- glmer(goals_scored ~ home_away + opponent_rank + (1 | opponent),
                 family = poisson, data = matches)
lrt_lap <- as.numeric(2 * (logLik(m_lap) - logLik(m_glm)))

re_test <- data.frame(
  quantity = c("opponent variance (AGQ)", "opponent SD (AGQ)",
               "logLik GLM", "marginal logLik GLMM (AGQ, by integration)",
               "LRT GLMM v GLM", "p-value (halved, boundary)",
               "LRT using Laplace fit (check)",
               "naive lme4 logLik with nAGQ = 25 (do not use)"),
  value = round(c(sigma_hat^2, sigma_hat, ll_glm, ll_glmm, lrt_re, p_re,
                  lrt_lap, as.numeric(logLik(m_glmm))), 4)
)
re_test
#   variance 0.108, SD 0.329
#   logLik GLM -63.716; GLMM -63.145; LRT 1.14 on 1 df, halved p = 0.14
#   Laplace check: LRT 1.21 (agrees)
# The variance is tested on the boundary of its parameter space (sigma^2 = 0),
# so the LRT is referred to a 50:50 mixture of chi2_0 and chi2_1, i.e. the
# chi2_1 p-value halved (week 11 slides). p = 0.14: no evidence that
# Ashford's two matches against the same opponent are more alike than
# opponent_rank already predicts. An SD of 0.33 would mean opponent effects
# multiplying the scoring rate by about exp(+/-2 x 0.33) = 0.52 to 1.93, but
# the data are consistent with 0.
write.csv(re_test, "outputs/goals_glmm_random_effect_test.csv",
          row.names = FALSE)

# =============================================================================
# PART 3: RATE RATIOS — GLM v GLMM v 09d
# =============================================================================
ci_glmm <- suppressMessages(confint(m_glmm, parm = "beta_", method = "profile"))
ci_glm  <- suppressMessages(confint(m_glm))
paired  <- read.csv("outputs/goals_paired_results.csv")   # 09d (Liri)

rr <- data.frame(
  model = c("06b GLM", "06b GLM", "11b GLMM (1 | opponent)",
            "11b GLMM (1 | opponent)", "09d paired, opponent fixed effects"),
  term  = c("Away v Home", "opponent_rank (per place)",
            "Away v Home", "opponent_rank (per place)", "Away v Home"),
  RR    = round(c(exp(coef(m_glm))[2:3], exp(fixef(m_glmm))[2:3],
                  paired$away_home_RR[1]), 3),
  lower_95 = round(c(exp(ci_glm[2:3, 1]), exp(ci_glmm[2:3, 1]),
                     paired$lower_95[1]), 3),
  upper_95 = round(c(exp(ci_glm[2:3, 2]), exp(ci_glmm[2:3, 2]),
                     paired$upper_95[1]), 3)
)
rr
#   06b GLM   Away 0.500 (0.287-0.844)   rank 1.056 (1.017-1.098)
#   11b GLMM  Away 0.500 (0.287-0.844)   rank 1.052 (1.006-1.099)
#   09d       Away 0.500 (0.287-0.844)
# The away rate ratio is the same 0.50 in all three. That is expected, not a
# coincidence: every opponent has exactly one home and one away match, so
# venue is balanced within opponent and its estimate doesn't depend on how
# opponent is modelled (40 home goals v 20 away). The rank effect, which is
# a between-opponent comparison, is slightly smaller with a wider interval
# in the GLMM (1.052, CI 1.006-1.099), because the random effect absorbs
# some between-opponent variation. Conclusion for the report: Ashford's
# scoring rate away is half that at home (95% CI 0.29 to 0.84), whichever
# way the opponent pairing is handled.
write.csv(rr, "outputs/goals_glmm_rate_ratios.csv", row.names = FALSE)

# =============================================================================
# PART 4: 8-0 SENSITIVITY, OPPONENT EFFECTS, FIT
# =============================================================================
no8 <- matches[!(matches$goals_scored == 8 & matches$goals_conceded == 0), ]
m_glmm_no8 <- glmer(goals_scored ~ home_away + opponent_rank + (1 | opponent),
                    family = poisson, data = no8, nAGQ = 25)
isSingular(m_glmm_no8)        # TRUE
VarCorr(m_glmm_no8)           # opponent SD 0
round(exp(fixef(m_glmm_no8)), 3)
#   Away 0.586, opponent_rank 1.034: identical to the GLM without the 8-0
# (05e/06b: away 0.586, CI 0.330-1.017). Without the 8-0 the opponent
# variance is estimated as exactly 0 (a singular fit), so the GLMM reduces
# to the GLM. The non-zero variance in the full data comes from the rank-24
# pair (8-0 at home and 3-1 away: 11 goals v 4.5 expected from the GLM):
# it is the 8-0 again, not a general pattern of some opponents being easier
# to score against.

# Predicted opponent effects (conditional modes), largest first
re_opp <- ranef(m_glmm)$opponent
re_df  <- data.frame(opponent_rank = as.integer(rownames(re_opp)),
                     u = round(re_opp[, 1], 3),
                     multiplier = round(exp(re_opp[, 1]), 3))
re_df  <- re_df[order(-abs(re_df$u)), ]
head(re_df, 5)
# Rank 24 (the 8-0 opponent) has the largest predicted effect, u = 1.08
# (rate x 2.9); the next largest are about +/-0.5 (ranks 15, 5, 22, 6).
# Predictions are shrunk towards 0, as expected with 2 matches per opponent.
write.csv(re_df, "outputs/goals_glmm_opponent_effects.csv", row.names = FALSE)

# Fit check: Pearson residuals and dispersion (conditional on u)
pres <- residuals(m_glmm, type = "pearson")
disp <- sum(pres^2) / df.residual(m_glmm)
round(c(dispersion = disp, max_abs_pearson = max(abs(pres))), 3)
# Dispersion about 0.7 (below 1; no overdispersion) and no |residual| > 2
# once the opponent effect is included.

png("outputs/goals_glmm_diagnostics.png", width = 1000, height = 480)
par(mfrow = c(1, 2))
plot(fitted(m_glmm), pres, pch = 19,
     col = ifelse(matches$home_away == "Home", "black", "firebrick"),
     xlab = "Fitted goals (GLMM, conditional on opponent)",
     ylab = "Pearson residual", main = "Residuals v fitted")
abline(h = c(-2, 0, 2), lty = c(2, 1, 2), col = "grey50")
legend("topright", c("Home", "Away"), pch = 19,
       col = c("black", "firebrick"), bty = "n")
qqnorm(re_opp[, 1], pch = 19, main = "Predicted opponent effects (Q-Q)")
qqline(re_opp[, 1])
dev.off()
# Left: no pattern in residuals. Right: the opponent effects are roughly on
# a line apart from rank 24 at the top. With 23 shrunken predictions this is
# a rough check only.

# Decision: keep the GLM (06b) as the main goals-scored model. The GLMM gives
# the same away rate ratio, its variance is not needed (p = 0.14), and it
# goes to 0 without the 8-0. Report the GLMM in one sentence alongside 09d
# as confirmation that the opponent pairing doesn't change the conclusion.
