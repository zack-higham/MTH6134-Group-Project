# 03_variable_roles.R — Week 3: introduction to GLMs
# Which variables are natural responses, which are explanatory, and what type
# of outcome is each response? Summary table is in notes/decision-notes.md.
source("code/00_load_data.R")

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
