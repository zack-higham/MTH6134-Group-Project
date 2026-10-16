# 04d_grouped_binomial.R — Week 4: grouped binomial models and team effect
# Person 4 (Liri)

source("code/00_load_data.R")

# -----------------------------------------------------------------------------
# 1. Aggregate injuries by team
# -----------------------------------------------------------------------------

team_injured <- aggregate(injured ~ team, data = players, FUN = sum)
team_size <- aggregate(injured ~ team, data = players, FUN = length)
names(team_size)[2] <- "n"
team_data <- merge(team_injured, team_size, by = "team")
team_data$not_injured <- team_data$n - team_data$injured
team_data$injury_rate <- team_data$injured / team_data$n

# An intercept-only grouped binomial model assumes one common injury probability
# for all teams. Extra variation between team rates appears as overdispersion.
m_team_grouped <- glm(
  cbind(injured, not_injured) ~ 1,
  family = binomial,
  data = team_data
)

team_data$fitted_rate <- fitted(m_team_grouped)
team_data <- team_data[order(team_data$injury_rate), ]
print(team_data)

team_deviance <- deviance(m_team_grouped)
team_df <- df.residual(m_team_grouped)
team_pearson <- sum(residuals(m_team_grouped, type = "pearson")^2)

team_gof <- data.frame(
  measure = c(
    "residual_deviance", "residual_df", "deviance_df_ratio",
    "pearson_chisq", "pearson_df_ratio", "deviance_p_value"
  ),
  value = c(
    team_deviance,
    team_df,
    team_deviance / team_df,
    team_pearson,
    team_pearson / team_df,
    pchisq(team_deviance, df = team_df, lower.tail = FALSE)
  )
)
print(team_gof)

# -----------------------------------------------------------------------------
# 2. Does adding 23 fixed team effects improve Person 2's final model?
# -----------------------------------------------------------------------------

m_without_team <- glm(
  injured ~ age + training_load + prev_injuries,
  family = binomial,
  data = players
)

m_with_team <- update(m_without_team, . ~ . + team)

team_lrt_anova <- anova(m_without_team, m_with_team, test = "Chisq")
print(team_lrt_anova)

team_lrt <- data.frame(
  comparison = "Add team as a 24-level fixed effect",
  df_added = team_lrt_anova$Df[2],
  deviance_reduction = team_lrt_anova$Deviance[2],
  p_value = team_lrt_anova$`Pr(>Chi)`[2],
  AIC_without_team = AIC(m_without_team),
  AIC_with_team = AIC(m_with_team)
)
print(team_lrt)

# -----------------------------------------------------------------------------
# 3. Grouped binomial model by position
# -----------------------------------------------------------------------------

position_injured <- aggregate(injured ~ position, data = players, FUN = sum)
position_size <- aggregate(injured ~ position, data = players, FUN = length)
names(position_size)[2] <- "n"
position_data <- merge(position_injured, position_size, by = "position")
position_data$not_injured <- position_data$n - position_data$injured
position_data$observed_rate <- position_data$injured / position_data$n

# With one fitted probability per position, this model is saturated and its
# fitted probabilities reproduce the four observed position injury rates.
m_position_grouped <- glm(
  cbind(injured, not_injured) ~ position,
  family = binomial,
  data = position_data
)

position_data$fitted_rate <- fitted(m_position_grouped)
position_data$absolute_difference <- abs(
  position_data$observed_rate - position_data$fitted_rate
)
print(position_data)

# Save compact tables for the report and decision notes.
write.csv(team_data, "outputs/injury_team_grouped.csv", row.names = FALSE)
write.csv(team_gof, "outputs/injury_team_grouped_gof.csv", row.names = FALSE)
write.csv(team_lrt, "outputs/injury_team_lrt.csv", row.names = FALSE)
write.csv(position_data, "outputs/injury_position_grouped.csv", row.names = FALSE)

