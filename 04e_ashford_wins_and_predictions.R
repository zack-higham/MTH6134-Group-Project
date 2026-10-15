# 04e_ashford_wins_and_predictions.R — Week 4: binomial regression
# Owner: Zack
#   Part 1: logistic model for Ashford United wins
#   Part 2: grouped check of the win model (observed vs fitted by cell)
#   Part 3: predicted win probability v opponent rank, with 95% bands
#   Part 4: predicted injury probability from the final injury model (04b)
# Base R only. Run from the project folder (open the .Rproj first).

source("code/00_load_data.R")

# =============================================================================
# PART 1: WIN MODEL
# =============================================================================
# win is binary (1 = Ashford won, 0 = draw or loss), so a binomial GLM with a
# logit link is appropriate: it keeps fitted probabilities in (0, 1) and its
# coefficients exponentiate to odds ratios.
matches$win <- as.integer(matches$result == "W")
table(win = matches$win, home_away = matches$home_away)   # 15/23 home, 7/23 away

m_win <- glm(win ~ home_away + opponent_rank, family = binomial, data = matches)
summary(m_win)

# Odds ratios with 95% profile-likelihood CIs (exponentiated from log-odds scale)
win_or <- exp(cbind(OR = coef(m_win), confint(m_win)))
win_or_table <- data.frame(term = rownames(win_or),
                           OR = round(win_or[, 1], 3),
                           lower_95 = round(win_or[, 2], 3),
                           upper_95 = round(win_or[, 3], 3),
                           row.names = NULL)
win_or_table
write.csv(win_or_table, "outputs/win_odds_ratios.csv", row.names = FALSE)

# Likelihood ratio test for each term, given the other (order-independent)
win_drop1 <- drop1(m_win, test = "Chisq")
win_drop1
win_lrt_table <- data.frame(term = rownames(win_drop1)[-1],
                            df = win_drop1$Df[-1],
                            LRT = round(win_drop1$LRT[-1], 3),
                            p_value = round(win_drop1$`Pr(>Chi)`[-1], 4))
write.csv(win_lrt_table, "outputs/win_drop1_lrt.csv", row.names = FALSE)

# Interpretation (see decision-notes.md):
# - Away v home: odds of winning multiplied by ~0.20 (95% CI 0.05 to 0.72),
#   holding opponent rank fixed. LRT = 6.15 on 1 df, p = 0.013.
# - Each place lower in the table for the opponent (rank +1): odds multiplied
#   by ~1.09 (95% CI 1.00 to 1.21). LRT = 3.58 on 1 df, p = 0.059, so weak
#   evidence only at the 5% level.

# =============================================================================
# PART 2: GROUPED CHECK (0/1 data, so residual deviance is NOT a GOF test)
# =============================================================================
# Group by home/away and opponent-rank band and compare observed with fitted
# win counts. Bands: 1-8 (strong), 9-16 (middle), 17-24 (weak).
matches$rank_band <- cut(matches$opponent_rank, breaks = c(0, 8, 16, 24),
                         labels = c("1-8", "9-16", "17-24"))
matches$fitted_win <- fitted(m_win)

n_cell   <- aggregate(win ~ home_away + rank_band, data = matches, FUN = length)
obs_cell <- aggregate(win ~ home_away + rank_band, data = matches, FUN = sum)
fit_cell <- aggregate(fitted_win ~ home_away + rank_band, data = matches, FUN = sum)

win_grouped <- data.frame(home_away = n_cell$home_away,
                          rank_band = n_cell$rank_band,
                          n = n_cell$win,
                          observed_wins = obs_cell$win,
                          fitted_wins = round(fit_cell$fitted_win, 2))
win_grouped$observed_prop <- round(win_grouped$observed_wins / win_grouped$n, 3)
win_grouped$fitted_prop   <- round(win_grouped$fitted_wins / win_grouped$n, 3)
# Pearson residual per cell (binomial, using the average fitted probability)
p_bar <- fit_cell$fitted_win / n_cell$win
win_grouped$pearson_resid <- round((obs_cell$win - fit_cell$fitted_win) /
                                     sqrt(n_cell$win * p_bar * (1 - p_bar)), 2)
win_grouped
write.csv(win_grouped, "outputs/win_grouped_check.csv", row.names = FALSE)

# Pearson X^2 over the 6 cells. Only ~7-8 matches per cell, so the chi-squared
# approximation is rough; treat this as descriptive.
X2_win <- sum(win_grouped$pearson_resid^2)
X2_win
any(abs(win_grouped$pearson_resid) > 2)

# =============================================================================
# PART 3: PREDICTED WIN PROBABILITY v OPPONENT RANK, WITH 95% BANDS
# =============================================================================
# Bands computed on the link (log-odds) scale, then transformed with plogis(),
# so they stay inside (0, 1).
rank_grid <- 1:24
win_pred <- do.call(rbind, lapply(c("Home", "Away"), function(ha) {
  nd <- data.frame(home_away = factor(ha, levels = c("Home", "Away")),
                   opponent_rank = rank_grid)
  pr <- predict(m_win, newdata = nd, type = "link", se.fit = TRUE)
  data.frame(nd,
             prob  = plogis(pr$fit),
             lower = plogis(pr$fit - 1.96 * pr$se.fit),
             upper = plogis(pr$fit + 1.96 * pr$se.fit))
}))
write.csv(transform(win_pred, prob = round(prob, 3), lower = round(lower, 3),
                    upper = round(upper, 3)),
          "outputs/win_predicted_probabilities.csv", row.names = FALSE)

png("outputs/win_prob_by_rank.png", width = 900, height = 550)
cols <- c(Home = "black", Away = "red")
plot(NA, xlim = c(1, 24), ylim = c(0, 1),
     xlab = "Opponent final rank (1 = strongest)",
     ylab = "Predicted probability of an Ashford win",
     main = "Predicted win probability with 95% confidence bands")
for (ha in c("Home", "Away")) {
  d <- win_pred[win_pred$home_away == ha, ]
  polygon(c(d$opponent_rank, rev(d$opponent_rank)), c(d$lower, rev(d$upper)),
          col = adjustcolor(cols[ha], alpha.f = 0.15), border = NA)
  lines(d$opponent_rank, d$prob, col = cols[ha], lwd = 2)
}
# observed results, jittered slightly so home and away points don't overlap
points(matches$opponent_rank,
       matches$win + ifelse(matches$home_away == "Home", 0.02, -0.02),
       pch = 19, col = cols[as.character(matches$home_away)])
legend("left", legend = c("Home", "Away"), col = cols, lwd = 2, pch = 19, bty = "n")
dev.off()

# =============================================================================
# PART 4: PREDICTED INJURY PROBABILITY (final injury model from 04b)
# =============================================================================
# Final injury model from 04b (Liha, 14/10/2026): backward elimination by LRT
# and step() by AIC both select age + training_load + prev_injuries.
# If 04b's final model changes, update this formula to match.
players$minutes_1000 <- players$minutes_played / 1000
injury_final_formula <- injured ~ age + training_load + prev_injuries
m_inj_final <- glm(injury_final_formula, family = binomial, data = players)
summary(m_inj_final)

# Grid: prev_injuries 0-4 for each training load 1-5. Every other variable in
# the model is held at a typical value (median for numeric, GK for position).
typical <- data.frame(
  age = median(players$age),
  minutes_1000 = median(players$minutes_1000),
  bmi = median(players$bmi),
  position = factor("GK", levels = levels(players$position))
)
inj_grid <- expand.grid(prev_injuries = 0:4, training_load = 1:5)
inj_grid <- cbind(inj_grid, typical[rep(1, nrow(inj_grid)), ], row.names = NULL)
pr <- predict(m_inj_final, newdata = inj_grid, type = "link", se.fit = TRUE)
inj_grid$prob  <- plogis(pr$fit)
inj_grid$lower <- plogis(pr$fit - 1.96 * pr$se.fit)
inj_grid$upper <- plogis(pr$fit + 1.96 * pr$se.fit)
write.csv(transform(inj_grid, prob = round(prob, 3), lower = round(lower, 3),
                    upper = round(upper, 3)),
          "outputs/injury_predicted_probabilities.csv", row.names = FALSE)

png("outputs/injury_prob_by_prev_injuries.png", width = 900, height = 550)
load_cols <- hcl.colors(5, "viridis")
plot(NA, xlim = c(0, 4), ylim = c(0, 1),
     xlab = "Number of previous injuries (prior three seasons)",
     ylab = "Predicted probability of injury",
     main = paste0("Predicted injury probability by training load (age ",
                   median(players$age), ")"))
for (tl in 1:5) {
  d <- inj_grid[inj_grid$training_load == tl, ]
  lines(d$prev_injuries, d$prob, col = load_cols[tl], lwd = 2, type = "b", pch = 19)
}
# 95% bands for the lowest and highest loads only, to keep the plot readable
for (tl in c(1, 5)) {
  d <- inj_grid[inj_grid$training_load == tl, ]
  polygon(c(d$prev_injuries, rev(d$prev_injuries)), c(d$lower, rev(d$upper)),
          col = adjustcolor(load_cols[tl], alpha.f = 0.15), border = NA)
}
legend("topleft", title = "Training load", legend = 1:5, col = load_cols,
       lwd = 2, pch = 19, bty = "n")
mtext("Shaded: 95% confidence bands for loads 1 and 5. Few players have 4 previous injuries.",
      side = 1, line = 4, cex = 0.8)
dev.off()
