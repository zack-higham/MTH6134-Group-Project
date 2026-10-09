# 01_explore.R — Week 2: read in, summarise and plot both datasets
source("code/00_load_data.R")

# ---- Structure and summaries ----
str(players)
summary(players)
str(matches)
summary(matches)

colSums(is.na(players))   # check for missing values
colSums(is.na(matches))

# ---- Players ----
table(players$position)
tapply(players$injured, players$position, mean)   # injury rate by position
table(players$minutes_played == 3960)              # ceiling at max minutes?

png("outputs/players_histograms.png", width = 1000, height = 700)
par(mfrow = c(2, 2))
hist(players$age, main = "Age", xlab = "Age (years)")
hist(players$bmi, main = "BMI", xlab = "BMI")
hist(players$minutes_played, main = "Minutes played", xlab = "Minutes")
barplot(table(players$training_load), main = "Training load", xlab = "Load (1-5)")
dev.off()

png("outputs/injury_rate_by_position.png", width = 700, height = 500)
barplot(tapply(players$injured, players$position, mean),
        main = "Proportion injured by position", ylab = "Proportion injured")
dev.off()

# ---- Matches ----
aggregate(cbind(goals_scored, goals_conceded) ~ home_away, data = matches, FUN = mean)
c(mean = mean(matches$goals_scored), var = var(matches$goals_scored))  # overdispersion hint
matches[matches$goals_scored >= 5, ]                                    # the 8-0 game

png("outputs/goals_vs_opponent_rank.png", width = 900, height = 450)
par(mfrow = c(1, 2))
plot(goals_scored ~ opponent_rank, data = matches, col = home_away, pch = 19,
     main = "Goals scored", xlab = "Opponent final rank")
legend("topleft", legend = levels(matches$home_away), col = 1:2, pch = 19)
plot(goals_conceded ~ opponent_rank, data = matches, col = home_away, pch = 19,
     main = "Goals conceded", xlab = "Opponent final rank")
dev.off()
