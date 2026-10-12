#################################
# 0. CREATE OUTPUT FOLDER
#################################

dir.create("outputs", showWarnings = FALSE)

#################################
# 1. INITIAL DATA EXPLORATION
#################################

head(league_players) 

# View the structure of the dataset
str(league_players)

# Summary of all variables
summary(league_players)

# Number of missing values in each column
colSums(is.na(league_players))

dim(league_players) 

colSums(is.na(league_players))

# Number of players in each team
table(league_players$team)

# Number of players in each position
table(league_players$position)

# Number of unique teams
length(unique(league_players$team))


############################################################
# 2. SUMMARY STATISTICS
############################################################

# Select variables for numerical summaries
summary_variables <- league_players[
  , c("age", "minutes_played", "training_load",
      "prev_injuries", "bmi")
]

# Calculate summaries for numeric variables only
numeric_variables <- summary_variables[
  , sapply(summary_variables, is.numeric), drop = FALSE
]

summary_table <- data.frame(
  Variable = names(numeric_variables),
  Mean = sapply(numeric_variables, mean, na.rm = TRUE),
  SD = sapply(numeric_variables, sd, na.rm = TRUE),
  Median = sapply(numeric_variables, median, na.rm = TRUE),
  Min = sapply(numeric_variables, min, na.rm = TRUE),
  Max = sapply(numeric_variables, max, na.rm = TRUE)
)

# Display the table
print(summary_table)

dir.create("outputs", showWarnings = FALSE)

# Save the table
write.csv(
  summary_table,
  "outputs/players_summary_table.csv",
  row.names = FALSE
)


############################################################
# 3. DISTRIBUTIONS OF VARIABLES
############################################################


# 1. Distribution of player ages
hist(players$age,
     main = "Distribution of Player Ages",
     xlab = "Age",
     ylab = "Number of Players",
     col = "lightblue",
     border = "white")

# 2. Distribution of BMI
hist(players$bmi,
     main = "Distribution of Player BMI",
     xlab = "BMI",
     ylab = "Number of Players",
     col = "lightgreen",
     border = "white")

# 3. Distribution of minutes played
hist(players$minutes_played,
     main = "Distribution of Minutes Played",
     xlab = "Minutes Played",
     ylab = "Number of Players",
     col = "lightpink",
     border = "white")


# 4. Training load
barplot(table(players$training_load),
        main = "Players by Training Load",
        xlab = "Training Load",
        ylab = "Number of Players",
        col = "lightblue")

# 5. Previous injuries
barplot(table(players$prev_injuries),
        main = "Players by Previous Injuries",
        xlab = "Number of Previous Injuries",
        ylab = "Number of Players",
        col = "lightgreen")

# 6. Playing position
barplot(table(players$position),
        main = "Players by Position",
        xlab = "Position",
        ylab = "Number of Players",
        col = "lightpink")


dir.create("outputs", showWarnings = FALSE)

png("outputs/age_histogram.png",
    width = 800, height = 600)

hist(players$age,
     main = "Distribution of Player Ages",
     xlab = "Age",
     ylab = "Number of Players",
     col = "lightblue",
     border = "white")

dev.off()


############################################################
# 4. MINUTES-PLAYED CEILING
############################################################

# Count players who played exactly 3960 minutes
sum(league_players$minutes_played == 3960, na.rm = TRUE)

# Select players who played exactly 3960 minutes
ceiling_players <- league_players[
  !is.na(league_players$minutes_played) &
    league_players$minutes_played == 3960, ]

# View their positions
table(ceiling_players$position)

ceiling_players[c("team", "position", "minutes_played")]


############################################################
# 5. INJURY RATES
############################################################


# Overall injury rate
overall_injury_rate <- mean(league_players$injured, na.rm = TRUE) * 100

# Display the result
overall_injury_rate


# Injury rate by playing position
injury_by_position <- aggregate(
  injured ~ position,
  data = league_players,
  FUN = function(x) mean(x, na.rm = TRUE) * 100
)

# Rename the rate column
names(injury_by_position)[2] <- "injury_rate_percent"

# Display the results
injury_by_position



# Injury rate by training load
injury_by_training <- aggregate(
  injured ~ training_load,
  data = league_players,
  FUN = function(x) mean(x, na.rm = TRUE) * 100
)

names(injury_by_training)[2] <- "injury_rate_percent"

injury_by_training



# Injury rate by number of previous injuries
injury_by_prev <- aggregate(
  injured ~ prev_injuries,
  data = league_players,
  FUN = function(x) mean(x, na.rm = TRUE) * 100
)

names(injury_by_prev)[2] <- "injury_rate_percent"

injury_by_prev



# Injury rate by team
injury_by_team <- aggregate(
  injured ~ team,
  data = league_players,
  FUN = function(x) mean(x, na.rm = TRUE) * 100
)

names(injury_by_team)[2] <- "injury_rate_percent"

# Sort from highest to lowest injury rate
injury_by_team <- injury_by_team[
  order(injury_by_team$injury_rate_percent, decreasing = TRUE),
]

injury_by_team



# Create outputs folder if needed
dir.create("outputs", showWarnings = FALSE)

# Chart 1: Overall injury rate
png("outputs/injury_rate_overall.png",
    width = 800, height = 600)

barplot(overall_injury_rate,
        names.arg = "All players",
        ylim = c(0, 100),
        main = "Overall Injury Rate",
        ylab = "Injured players (%)",
        col = "tomato")

dev.off()


# Chart 2: Injury rate by position
png("outputs/injury_rate_position.png",
    width = 800, height = 600)

barplot(injury_by_position$injury_rate_percent,
        names.arg = injury_by_position$position,
        ylim = c(0, 100),
        main = "Injury Rate by Position",
        xlab = "Position",
        ylab = "Injured players (%)",
        col = "steelblue")

dev.off()


# Chart 3: Injury rate by training load
png("outputs/injury_rate_training_load.png",
    width = 800, height = 600)

barplot(injury_by_training$injury_rate_percent,
        names.arg = injury_by_training$training_load,
        ylim = c(0, 100),
        main = "Injury Rate by Training Load",
        xlab = "Training load",
        ylab = "Injured players (%)",
        col = "darkseagreen")

dev.off()


# Chart 4: Injury rate by previous injuries
png("outputs/injury_rate_prev_injuries.png",
    width = 900, height = 600)

barplot(injury_by_prev$injury_rate_percent,
        names.arg = injury_by_prev$prev_injuries,
        ylim = c(0, 100),
        main = "Injury Rate by Previous Injuries",
        xlab = "Number of previous injuries",
        ylab = "Injured players (%)",
        col = "goldenrod")

dev.off()


# Chart 5: Injury rate by team
png("outputs/injury_rate_team.png",
    width = 1200, height = 700)

par(mar = c(10, 4, 4, 2))

barplot(injury_by_team$injury_rate_percent,
        names.arg = injury_by_team$team,
        las = 2,
        ylim = c(0, 100),
        main = "Injury Rate by Team",
        ylab = "Injured players (%)",
        cex.names = 0.7,
        col = "mediumpurple")

dev.off()

# Reset plotting margins
par(mar = c(5, 4, 4, 2))



############################################################
# 6. RELATIONSHIPS BETWEEN VARIABLES
############################################################


# Age against minutes played
plot(league_players$age,
     league_players$minutes_played,
     main = "Age vs Minutes Played",
     xlab = "Age (years)",
     ylab = "Minutes Played",
     pch = 19,
     col = "steelblue")

# Add a trend line
abline(lm(minutes_played ~ age, data = league_players),
       col = "red", lwd = 2)


# BMI by playing position
boxplot(bmi ~ position,
        data = league_players,
        main = "BMI by Playing Position",
        xlab = "Playing Position",
        ylab = "BMI",
        col = "lightgreen")


# Minutes played by playing position
boxplot(minutes_played ~ position,
        data = league_players,
        main = "Minutes Played by Position",
        xlab = "Playing Position",
        ylab = "Minutes Played",
        col = "lightblue")


# Pearson correlation between age and minutes played
cor(league_players$age,
    league_players$minutes_played,
    use = "complete.obs")

############################################################
# 7. CHECK CORRELATIONS BETWEEN NUMERIC VARIABLES
############################################################

# Select numeric explanatory variables
correlation_variables <- league_players[
  , c("age", "minutes_played", "training_load",
      "prev_injuries", "bmi"),
  drop = FALSE
]

correlation_variables <- correlation_variables[
  , sapply(correlation_variables, is.numeric),
  drop = FALSE
]

# Calculate the correlation matrix
correlation_matrix <- cor(
  correlation_variables,
  use = "pairwise.complete.obs"
)

print(round(correlation_matrix, 2))


# Save the correlation matrix
write.csv(
  correlation_matrix,
  "outputs/correlation_matrix.csv"
)


############################################################
# END OF SCRIPT
############################################################




