# code/00_load_data.R
# Reads both datasets and sets variable types. Source this at the top of every
# other script with: source("code/00_load_data.R")

players <- read.csv("data/league_players.csv")
matches <- read.csv("data/ashford_matches.csv")

# Categorical variables as factors
players$team     <- factor(players$team)
players$position <- factor(players$position, levels = c("GK", "DEF", "MID", "FWD"))
matches$home_away <- factor(matches$home_away, levels = c("Home", "Away"))

# training_load is ordinal (1-5). Kept numeric for now; a factor version is
# added so we can compare both. See decision-notes.md.
players$training_load_f <- factor(players$training_load, ordered = TRUE)

# Derived match variables
matches$goal_diff <- matches$goals_scored - matches$goals_conceded
matches$result <- factor(
  ifelse(matches$goal_diff > 0, "W", ifelse(matches$goal_diff < 0, "L", "D")),
  levels = c("L", "D", "W"), ordered = TRUE
)
