# 03a_variable_roles.R — Week 3: introduction to GLMs
# Which variables are natural responses, which are explanatory, and what type
# of outcome is each response? Summary table is in notes/decision-notes.md.
source("code/00_load_data.R")

# A response variable needs a probability distribution in the model. Predictor
# variables do not need to follow that distribution themselves; their entries
# below describe their observed data type and likely empirical distribution.
variable_roles <- data.frame(
  variable = c(
    "team", "position", "age", "minutes_played", "training_load",
    "prev_injuries", "bmi", "injured", "home_away", "goals_scored",
    "goals_conceded", "opponent_rank", "result"
  ),
  dataset = c(
    rep("players", 8), rep("matches", 5)
  ),
  role = c(
    "grouping variable", "explanatory", "explanatory", "response/explanatory",
    "explanatory", "explanatory", "explanatory", "response",
    "explanatory", "response", "response", "explanatory", "response"
  ),
  type = c(
    "nominal categorical", "nominal categorical", "continuous (whole years)",
    "bounded continuous", "ordinal (1-5)", "count (0-4)", "continuous",
    "binary", "binary categorical", "count", "count", "ordinal (1-24)",
    "ordered categorical (L/D/W)"
  ),
  likely_distribution = c(
    "multinomial categorical", "multinomial categorical", "empirical continuous",
    "bounded and ceiling-affected", "ordered discrete", "right-skewed count",
    "empirical continuous", "Bernoulli/binomial", "binary categorical",
    "Poisson candidate", "Poisson candidate", "ordered discrete",
    "ordinal categorical"
  )
)

variable_roles

# Binary response -> binomial GLM (week 4)
table(players$injured)
mean(players$injured)

# Count responses -> Poisson GLM, check overdispersion (week 6)
table(matches$goals_scored)
table(matches$goals_conceded)

# Ordinal response (derived) -> specialised ordinal model (week 10)
table(matches$result, matches$home_away)

# Grouping structure -> GLMM with random team effect (week 11)
sort(tapply(players$injured, players$team, mean))

# prev_injuries: a count, but more natural as a predictor of injured
table(prev_injuries = players$prev_injuries, injured = players$injured)

# Planned explanatory variables
# Injury: position, age, minutes_played, training_load, prev_injuries and bmi.
# These describe player role, exposure, workload, injury history and physiology.
# Team is considered separately as a grouping/random effect because players
# within the same club may share training and medical environments.
# Goals/result: home_away and opponent_rank capture venue and opposition
# strength. The same match predictors can later be used for the ordinal result.
