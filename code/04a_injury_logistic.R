# Week 4 person 1
# Full logisitc regression model for injury 

# Check the data set 
names(league_players)
head(league_players)
str(league_players) 

# Check the injury outcome
table(league_players$injured, useNA = "ifany") 

# Check for missing values in the model variables 
colSums(is.na(league_players[, c(
  "injured", "position", "age", "minutes_played",
  "training_load", "prev_injuries", "bmi"
)]))


# Rescale minutes played to units of 1,000
league_players$minutes_per_1000 <-
  league_players$minutes_played / 1000

# Fit the full logistic regression model
m_full <- glm(
  injured ~ position + age + minutes_per_1000 +
    training_load + prev_injuries + bmi,
  data = league_players,
  family = binomial(link = "logit")
)

# Display the model results
summary(m_full)


# Set goalkeeper (GK) as the reference category
league_players$position <- relevel(
  factor(league_players$position),
  ref = "GK"
)

# Refit the full model
league_players$minutes_per_1000 <-
  league_players$minutes_played / 1000

m_full <- glm(
  injured ~ position + age + minutes_per_1000 +
    training_load + prev_injuries + bmi,
  data = league_players,
  family = binomial(link = "logit")
)

summary(m_full)


# Calculate odds ratios and 95% confidence intervals

or_ci <- exp(cbind(
  OR = coef(m_full),
  confint(m_full)
))

# Create a table with clear column names
or_table <- data.frame(
  term = rownames(or_ci),
  OR = or_ci[, 1],
  lower_95 = or_ci[, 2],
  upper_95 = or_ci[, 3],
  row.names = NULL
)

# Display the table in R
print(or_table)

# Save the table to the outputs folder
write.csv(
  or_table,
  "outputs/injury_full_odds_ratios.csv",
  row.names = FALSE
)


# Test the contribution of each term in the model
anova(m_full, test = "Chisq")


# Refit the same model with predictors in a different order
m_reordered <- glm(
  injured ~ prev_injuries + training_load + age +
    bmi + minutes_per_1000 + position,
  data = league_players,
  family = binomial(link = "logit")
)

# Test terms sequentially in the new order
anova(m_reordered, test = "Chisq")



# 1. Raw injury rate by position
aggregate(injured ~ position, data = league_players, FUN = mean)

# 2. Raw injury rate by number of previous injuries
aggregate(injured ~ prev_injuries, data = league_players, FUN = mean)

# 3. Summarise training load into low, medium and high groups
league_players$load_group <- cut(
  league_players$training_load,
  breaks = quantile(
    league_players$training_load,
    probs = c(0, 1/3, 2/3, 1),
    na.rm = TRUE
  ),
  include.lowest = TRUE,
  labels = c("Low", "Medium", "High")
)

aggregate(injured ~ load_group, data = league_players, FUN = mean)



