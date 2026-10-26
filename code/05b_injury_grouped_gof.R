# 05b_injury_grouped_gof.R  (Person 2, Liha)
# Week 5: grouped goodness of fit for the final injury model
# Final model (from 04b): injured ~ age + training_load + prev_injuries
#
# Why grouped: for player-level 0/1 data the residual deviance is not a valid
# GOF statistic (slides 5 and 7), so we compare observed and expected counts
# within training_load x prev_injuries cells instead.

source("code/00_load_data.R")

# ---- 0. Data and final model ------------------------------------------------
# CHECK: change `players` to whatever data frame 00_load_data.R creates.
dat <- players

m_final <- glm(injured ~ age + training_load + prev_injuries,
               family = binomial, data = dat)
summary(m_final)

# Work on the rows the model actually used (a copy; the data itself is untouched)
mf <- model.frame(m_final)
stopifnot(all(mf$injured %in% c(0, 1)))      # needs 0/1 numeric, not a factor
mf$injured <- as.numeric(mf$injured)
mf$p_hat   <- fitted(m_final)
mf$var_p   <- mf$p_hat * (1 - mf$p_hat)
mf$n       <- 1

# ---- 1. Grouped table: observed vs expected per cell ------------------------
grp <- aggregate(cbind(n, injured, p_hat, var_p) ~ training_load + prev_injuries,
                 data = mf, FUN = sum)
names(grp)[names(grp) == "injured"] <- "observed"
names(grp)[names(grp) == "p_hat"]   <- "expected"      # sum of fitted probabilities
names(grp)[names(grp) == "var_p"]   <- "sum_p_1mp"     # sum of p(1 - p)

grp$obs_prop   <- grp$observed / grp$n
grp$fit_prop   <- grp$expected / grp$n
grp$pearson    <- (grp$observed - grp$expected) / sqrt(grp$sum_p_1mp)

# Flags
grp$flag_resid <- abs(grp$pearson) > 2
# Small cells: expected injured or expected not-injured below 5 (usual
# chi-squared rule of thumb, see the slide 5 caveat), or fewer than 10 players
grp$flag_small <- grp$expected < 5 | (grp$n - grp$expected) < 5 | grp$n < 10
grp$flag_prev4 <- grp$prev_injuries == 4

grp <- grp[order(grp$training_load, grp$prev_injuries), ]
print(grp, digits = 3)
cat("\nNumber of cells:", nrow(grp), "\n")
cat("Cells with |Pearson-type residual| > 2:", sum(grp$flag_resid), "\n")
cat("Small cells:", sum(grp$flag_small), "\n")

write.csv(grp, "outputs/injury_grouped_obs_vs_fitted.csv", row.names = FALSE)

# Overall summary of the cell residuals (roughly N(0,1) if the model fits and
# cells are not too small)
cat("Sum of squared cell residuals:", round(sum(grp$pearson^2), 2),
    "on", nrow(grp), "cells\n")

# ---- 2. Observed vs fitted proportion plot ----------------------------------
png("outputs/injury_grouped_fit.png", width = 900, height = 800, res = 130)
cex_pts <- 0.8 + 2.2 * sqrt(grp$n / max(grp$n))     # bigger point = more players
cols <- ifelse(grp$flag_resid, "red", ifelse(grp$flag_small, "darkorange", "black"))
lim <- range(c(grp$fit_prop, grp$obs_prop, 0, 1))
plot(grp$fit_prop, grp$obs_prop, xlim = lim, ylim = lim,
     xlab = "Fitted proportion injured (cell mean of fitted p)",
     ylab = "Observed proportion injured",
     main = "Injury model: observed vs fitted by training load x prior injuries",
     pch = 19, cex = cex_pts, col = cols)
abline(0, 1, lty = 2)                                # 45 degree line
if (any(grp$flag_resid)) {
  with(grp[grp$flag_resid, ],
       text(fit_prop, obs_prop, labels = paste0(training_load, "/", prev_injuries),
            pos = 3, cex = 0.7, col = "red"))
}
legend("topleft", bty = "n", cex = 0.8, pch = 19,
       col = c("black", "darkorange", "red"),
       legend = c("OK", "small cell", "|residual| > 2"))
mtext("Point size ~ number of players; labels = training_load/prev_injuries",
      side = 1, line = 4, cex = 0.7)
dev.off()

# ---- 3. Optional: grouped refit with age bands ------------------------------
# With grouped binomial data the residual deviance vs chi-squared on its df is
# a valid GOF test, provided cells are not too small (slide 5 caveat).
mf$age_band <- cut(mf$age, breaks = c(-Inf, 22, 26, 30, Inf),
                   labels = c("<=22", "23-26", "27-30", "31+"))

grp_age <- aggregate(cbind(n, injured) ~ age_band + training_load + prev_injuries,
                     data = mf, FUN = sum)

m_grouped <- glm(cbind(injured, n - injured) ~ age_band + training_load + prev_injuries,
                 family = binomial, data = grp_age)
summary(m_grouped)

dev_res <- deviance(m_grouped)
df_res  <- df.residual(m_grouped)
p_dev   <- pchisq(dev_res, df_res, lower.tail = FALSE)
pear_x2 <- sum(residuals(m_grouped, type = "pearson")^2)
p_pear  <- pchisq(pear_x2, df_res, lower.tail = FALSE)

grp_age$expected   <- fitted(m_grouped) * grp_age$n
grp_age$small_cell <- grp_age$expected < 5 | (grp_age$n - grp_age$expected) < 5
cat("\nGrouped refit (age bands):\n")
cat("Cells:", nrow(grp_age), " Residual deviance:", round(dev_res, 2),
    " df:", df_res, " p-value:", round(p_dev, 3), "\n")
cat("Pearson X2:", round(pear_x2, 2), " p-value:", round(p_pear, 3), "\n")
cat("Cells with expected count < 5 (either outcome):", sum(grp_age$small_cell),
    "of", nrow(grp_age), "- the chi-squared approximation is unreliable if many\n")

gof_tab <- data.frame(statistic = c("residual_deviance", "pearson_X2"),
                      value     = c(dev_res, pear_x2),
                      df        = df_res,
                      p_value   = c(p_dev, p_pear),
                      n_cells   = nrow(grp_age),
                      n_small_cells = sum(grp_age$small_cell))
write.csv(gof_tab, "outputs/injury_grouped_age_band_gof.csv", row.names = FALSE)
write.csv(grp_age, "outputs/injury_grouped_age_band_cells.csv", row.names = FALSE)

# Odds ratios with 95% CIs from the grouped model (Wald), for context
or_tab <- exp(cbind(OR = coef(m_grouped), confint.default(m_grouped)))
print(round(or_tab, 3))
write.csv(round(or_tab, 3), "outputs/injury_grouped_age_band_or.csv")

# ---- Notes for decision-notes.md (fill in after running) --------------------
# - Method: cells = training_load x prev_injuries; expected = sum of fitted p;
#   residual = (O - E) / sqrt(sum p(1 - p)). Deviance not used on 0/1 data (slides 5, 7).
# - Result: how many cells have |r| > 2, which ones, any pattern (over/under-predicting).
# - Small cells: especially prev_injuries = 4; say these residuals are unreliable.
# - Grouped age-band refit: deviance, df, p-value, and the small-cell caveat.
# - Wording: "is associated with", not "causes"; report ORs with CIs.
