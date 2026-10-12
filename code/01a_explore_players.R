# 01a_explore_players.R — Week 2: players dataset exploration (Yousuf)
# Summaries, distributions, the minutes ceiling, injury rates and correlations.
# Base R only. Run from the project folder (open the .Rproj first).

source("code/00_load_data.R")
dir.create("outputs", showWarnings = FALSE)

############################################################
# 1. INITIAL LOOK
############################################################

dim(players)                      # 620 rows, 9 columns (incl. training_load_f)
head(players)
str(players)
summary(players)
colSums(is.na(players))           # no missing values
table(players$team)               # players per club
nlevels(players$team)             # 24 clubs
table(players$position)

############################################################
# 2. SUMMARY STATISTICS
############################################################

num_vars <- c("age", "minutes_played", "training_load", "prev_injuries", "bmi")

summary_table <- data.frame(
  Variable = num_vars,
  Mean     = sapply(players[num_vars], mean),
  SD       = sapply(players[num_vars], sd),
  Median   = sapply(players[num_vars], median),
  Min      = sapply(players[num_vars], min),
  Max      = sapply(players[num_vars], max),
  row.names = NULL
)
summary_table[, -1] <- round(summary_table[, -1], 2)
summary_table
write.csv(summary_table, "outputs/players_summary_table.csv", row.names = FALSE)

############################################################
# 3. DISTRIBUTIONS OF VARIABLES
############################################################

png("outputs/players_distributions.png", width = 1200, height = 800)
par(mfrow = c(2, 3))
hist(players$age, main = "Age", xlab = "Age (years)",
     ylab = "Number of players", col = "lightblue", border = "white")
hist(players$bmi, main = "BMI", xlab = "BMI",
     ylab = "Number of players", col = "lightgreen", border = "white")
hist(players$minutes_played, breaks = 20, main = "Minutes played",
     xlab = "Minutes played", ylab = "Number of players",
     col = "lightpink", border = "white")
barplot(table(players$training_load), main = "Training load",
        xlab = "Training load (1-5)", ylab = "Number of players", col = "lightblue")
barplot(table(players$prev_injuries), main = "Previous injuries",
        xlab = "Injuries in prior 3 seasons", ylab = "Number of players",
        col = "lightgreen")
barplot(table(players$position), main = "Position",
        xlab = "Position", ylab = "Number of players", col = "lightpink")
dev.off()

############################################################
# 4. MINUTES-PLAYED CEILING
############################################################

at_ceiling <- players$minutes_played == 3960
sum(at_ceiling)                                   # 16 players at the maximum
table(players$position[at_ceiling])               # 12 of them goalkeepers
players[at_ceiling, c("team", "position", "minutes_played")]

############################################################
# 5. INJURY RATES
############################################################

mean(players$injured) * 100                       # overall injury rate (%)

# Injury rate table for one grouping variable: n, number injured, rate (%)
injury_rate_table <- function(group, name) {
  out <- data.frame(
    level    = names(table(group)),
    n        = as.vector(table(group)),
    injured  = as.vector(tapply(players$injured, group, sum)),
    rate_pct = round(100 * as.vector(tapply(players$injured, group, mean)), 1)
  )
  names(out)[1] <- name
  out
}

inj_position <- injury_rate_table(players$position,      "position")
inj_training <- injury_rate_table(players$training_load, "training_load")
inj_prev     <- injury_rate_table(players$prev_injuries, "prev_injuries")
inj_team     <- injury_rate_table(players$team,          "team")
inj_team     <- inj_team[order(inj_team$rate_pct, decreasing = TRUE), ]

inj_position
inj_training
inj_prev
inj_team

write.csv(inj_position, "outputs/injury_rates_position.csv",      row.names = FALSE)
write.csv(inj_training, "outputs/injury_rates_training_load.csv", row.names = FALSE)
write.csv(inj_prev,     "outputs/injury_rates_prev_injuries.csv", row.names = FALSE)
write.csv(inj_team,     "outputs/injury_rates_team.csv",          row.names = FALSE)

# Bar chart of injury rate (%) for one table
rate_barplot <- function(tab, file, xlab, main, col) {
  png(file, width = 800, height = 600)
  barplot(tab$rate_pct, names.arg = tab[[1]],
          ylim = c(0, max(tab$rate_pct) * 1.2),
          main = main, xlab = xlab, ylab = "Injured players (%)", col = col)
  invisible(dev.off())
}

rate_barplot(inj_position, "outputs/injury_rate_position.png",
             "Position", "Injury rate by position", "steelblue")
rate_barplot(inj_training, "outputs/injury_rate_training_load.png",
             "Training load", "Injury rate by training load", "darkseagreen")
rate_barplot(inj_prev, "outputs/injury_rate_prev_injuries.png",
             "Number of previous injuries", "Injury rate by previous injuries",
             "goldenrod")

# Team chart needs room for long club names
png("outputs/injury_rate_team.png", width = 1200, height = 700)
par(mar = c(10, 4, 4, 2))
barplot(inj_team$rate_pct, names.arg = inj_team$team, las = 2,
        ylim = c(0, max(inj_team$rate_pct) * 1.2), cex.names = 0.8,
        main = "Injury rate by team", ylab = "Injured players (%)",
        col = "mediumpurple")
abline(h = 100 * mean(players$injured), lty = 2)   # league-wide rate
dev.off()

############################################################
# 6. RELATIONSHIPS BETWEEN VARIABLES
############################################################

png("outputs/players_relationships.png", width = 1200, height = 450)
par(mfrow = c(1, 3))
plot(minutes_played ~ age, data = players, pch = 19, col = "steelblue",
     main = "Age vs minutes played", xlab = "Age (years)", ylab = "Minutes played")
abline(lm(minutes_played ~ age, data = players), col = "red", lwd = 2)
boxplot(bmi ~ position, data = players, main = "BMI by position",
        xlab = "Position", ylab = "BMI", col = "lightgreen")
boxplot(minutes_played ~ position, data = players, main = "Minutes played by position",
        xlab = "Position", ylab = "Minutes played", col = "lightblue")
dev.off()

cor(players$age, players$minutes_played)

############################################################
# 7. CORRELATIONS BETWEEN NUMERIC EXPLANATORY VARIABLES
############################################################

correlation_matrix <- round(cor(players[num_vars]), 2)
correlation_matrix

off_diag <- correlation_matrix
diag(off_diag) <- NA
max(abs(off_diag), na.rm = TRUE)    # largest |r| (training_load vs minutes_played)

write.csv(correlation_matrix, "outputs/correlation_matrix.csv")

############################################################
# END OF SCRIPT
############################################################




