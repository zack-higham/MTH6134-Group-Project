# 05d_grouped_diagnostics.R — Week 5: grouped binomial diagnostics
# Person 4 (Liri)
#
# Grouped binomial residuals are informative because each observation contains
# several players rather than a single 0/1 outcome. No rows are deleted: the
# final section is a sensitivity refit that keeps the original model as well.

source("code/00_load_data.R")

# =============================================================================
# PART 1: TEAM-LEVEL MODEL FROM 04d
# =============================================================================

team_injured <- aggregate(injured ~ team, data = players, FUN = sum)
team_size <- aggregate(injured ~ team, data = players, FUN = length)
names(team_size)[2] <- "n"
team_data <- merge(team_injured, team_size, by = "team")
team_data$not_injured <- team_data$n - team_data$injured
team_data$injury_rate <- team_data$injured / team_data$n

# Same common-probability grouped model as 04d.
m_team <- glm(
  cbind(injured, not_injured) ~ 1,
  family = binomial,
  data = team_data
)

team_data$fitted_rate <- fitted(m_team)
team_data$std_deviance_residual <- rstandard(m_team)
team_data$pearson_residual <- residuals(m_team, type = "pearson")
team_data$leverage <- hatvalues(m_team)
team_data$cooks_distance <- cooks.distance(m_team)
team_data$flag_abs_std_residual_gt_2 <-
  abs(team_data$std_deviance_residual) > 2

team_data <- team_data[order(team_data$std_deviance_residual), ]
print(team_data)

cat("\nTeam model residual deviance:", round(deviance(m_team), 3),
    "on", df.residual(m_team), "df; p =",
    signif(pchisq(deviance(m_team), df.residual(m_team),
                  lower.tail = FALSE), 3), "\n")
cat("Teams with |standardised deviance residual| > 2:\n")
print(team_data[team_data$flag_abs_std_residual_gt_2,
                c("team", "n", "injured", "injury_rate",
                  "std_deviance_residual")])

write.csv(team_data, "outputs/team_grouped_diagnostics.csv", row.names = FALSE)

png("outputs/team_residuals.png", width = 1100, height = 750, res = 130)
par(mar = c(9, 5, 4, 1) + 0.1)
plot(seq_len(nrow(team_data)), team_data$std_deviance_residual,
     type = "h", lwd = 2,
     col = ifelse(team_data$flag_abs_std_residual_gt_2, "red", "black"),
     xaxt = "n", xlab = "", ylab = "Standardised deviance residual",
     main = "Grouped injury model: standardised residuals by team")
axis(1, at = seq_len(nrow(team_data)), labels = team_data$team,
     las = 2, cex.axis = 0.62)
mtext("Team", side = 1, line = 7.5)
abline(h = c(-2, 0, 2), lty = c(2, 1, 2),
       col = c("red", "grey40", "red"))
dev.off()

# =============================================================================
# PART 2: POSITION x TRAINING-LOAD CELLS
# =============================================================================

# Cross position (4 levels) with training load (5 levels): up to 20 grouped
# observations. The additive model has p = 5: intercept, three position
# contrasts and one numeric training-load slope.
cell_injured <- aggregate(
  injured ~ position + training_load,
  data = players,
  FUN = sum
)
cell_size <- aggregate(
  injured ~ position + training_load,
  data = players,
  FUN = length
)
names(cell_size)[3] <- "n"
cell_data <- merge(cell_injured, cell_size,
                   by = c("position", "training_load"))
cell_data$not_injured <- cell_data$n - cell_data$injured
cell_data$observed_rate <- cell_data$injured / cell_data$n

m_cells <- glm(
  cbind(injured, not_injured) ~ position + training_load,
  family = binomial,
  data = cell_data
)

p_cells <- length(coef(m_cells))
n_cells <- nrow(cell_data)
average_leverage <- p_cells / n_cells

cell_data$fitted_rate <- fitted(m_cells)
cell_data$std_deviance_residual <- rstandard(m_cells)
cell_data$pearson_residual <- residuals(m_cells, type = "pearson")
cell_data$leverage <- hatvalues(m_cells)
cell_data$cooks_distance <- cooks.distance(m_cells)
cell_data$flag_abs_std_residual_gt_2 <-
  abs(cell_data$std_deviance_residual) > 2
cell_data$flag_leverage_above_average <-
  cell_data$leverage > average_leverage
cell_data$flag_leverage_above_2x_average <-
  cell_data$leverage > 2 * average_leverage
cell_data$cell_label <- paste0(cell_data$position, "/load", cell_data$training_load)

print(cell_data)
cat("\nPosition x load cells:", n_cells,
    " parameters:", p_cells,
    " average leverage p/n:", round(average_leverage, 3), "\n")
cat("Cells with |standardised deviance residual| > 2:",
    sum(cell_data$flag_abs_std_residual_gt_2), "\n")
cat("Cells with leverage > 2p/n:",
    sum(cell_data$flag_leverage_above_2x_average), "\n")

most_influential <- which.max(cell_data$cooks_distance)
cat("Most influential cell:\n")
print(cell_data[most_influential, ])

write.csv(cell_data, "outputs/position_load_cell_diagnostics.csv",
          row.names = FALSE)

png("outputs/position_load_diagnostics.png",
    width = 1200, height = 1000, res = 130)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))

plot(cell_data$fitted_rate, cell_data$std_deviance_residual,
     pch = 19,
     col = ifelse(cell_data$flag_abs_std_residual_gt_2, "red", "black"),
     ylim = range(cell_data$std_deviance_residual) + c(-0.25, 0.35),
     xlab = "Fitted injury proportion",
     ylab = "Standardised deviance residual",
     main = "Residuals vs fitted")
abline(h = c(-2, 0, 2), lty = c(2, 1, 2),
       col = c("red", "grey40", "red"))
label_residual <- abs(cell_data$std_deviance_residual) > 1
text(cell_data$fitted_rate[label_residual],
     cell_data$std_deviance_residual[label_residual],
     labels = cell_data$cell_label[label_residual], pos = 3, cex = 0.65)

qqnorm(cell_data$std_deviance_residual, pch = 19,
       main = "Normal Q-Q: grouped residuals")
qqline(cell_data$std_deviance_residual, col = "red")

plot(seq_len(n_cells), cell_data$leverage, type = "h", lwd = 2,
     xlab = "Cell index", ylab = "Leverage",
     main = "Leverage by cell")
abline(h = average_leverage, lty = 2, col = "blue")
abline(h = 2 * average_leverage, lty = 2, col = "red")

plot(seq_len(n_cells), cell_data$cooks_distance, type = "h", lwd = 2,
     ylim = c(0, 1.25 * max(cell_data$cooks_distance)),
     xlab = "Cell index", ylab = "Cook's distance",
     main = "Cook's distance by cell")
top_cooks <- order(cell_data$cooks_distance, decreasing = TRUE)[1:3]
text(top_cooks, cell_data$cooks_distance[top_cooks],
     labels = cell_data$cell_label[top_cooks], pos = 3, cex = 0.7)

par(mfrow = c(1, 1))
dev.off()

# =============================================================================
# PART 3: SENSITIVITY REFIT WITHOUT THE MOST INFLUENTIAL CELL
# =============================================================================

# The original data and model remain unchanged. This refit only checks whether
# the conclusions depend on the cell with the largest Cook's distance.
m_cells_sensitivity <- glm(
  cbind(injured, not_injured) ~ position + training_load,
  family = binomial,
  data = cell_data,
  subset = -most_influential
)

coef_ci <- function(model) {
  se <- sqrt(diag(vcov(model)))
  data.frame(
    term = names(coef(model)),
    estimate = unname(coef(model)),
    lower_95 = unname(coef(model) - qnorm(0.975) * se),
    upper_95 = unname(coef(model) + qnorm(0.975) * se),
    odds_ratio = unname(exp(coef(model))),
    or_lower_95 = unname(exp(coef(model) - qnorm(0.975) * se)),
    or_upper_95 = unname(exp(coef(model) + qnorm(0.975) * se)),
    row.names = NULL
  )
}

full_cmp <- coef_ci(m_cells)
sensitivity_cmp <- coef_ci(m_cells_sensitivity)
names(full_cmp)[-1] <- paste0(names(full_cmp)[-1], "_full")
names(sensitivity_cmp)[-1] <- paste0(names(sensitivity_cmp)[-1], "_without_cell")
influence_comparison <- merge(full_cmp, sensitivity_cmp, by = "term", sort = FALSE)
influence_comparison$excluded_cell <- cell_data$cell_label[most_influential]
influence_comparison$excluded_n <- cell_data$n[most_influential]
influence_comparison$excluded_cooks_distance <-
  cell_data$cooks_distance[most_influential]

print(influence_comparison)
write.csv(influence_comparison,
          "outputs/position_load_influence_comparison.csv",
          row.names = FALSE)

