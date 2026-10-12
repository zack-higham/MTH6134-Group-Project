# ---- Setup ----
source("code/00_load_data.R")
ls()

source("code/00_load_data.R")
library(tidyverse)
dir.create("outputs", showWarnings = FALSE)

# ---- Step 1: Structure checks ----
nrow(matches)                         # expect 46
table(matches$home_away)              # expect 23 Home, 23 Away
range(matches$opponent_rank)          # expect 1 24
table(matches$opponent_rank)          # each rank that appears should be 2
table(table(matches$opponent_rank))   # expect: 2 -> 23 opponents
setdiff(1:24, matches$opponent_rank)  # expect 9 (the missing rank)

# FINDING (Step 1): Ashford played 46 matches (23 home, 23 away) against 23
# opponents, each once at home and once away. Rank 9 does not appear,
# presumably because it is Ashford's own final position.

#---- Step 2: Derived variables and season record ----
# Does goal_diff match a fresh calculation?
all(matches$goal_diff == matches$goals_scored - matches$goals_conceded)   # expect TRUE

# Does result match a fresh calculation?
check_result <- case_when(matches$goal_diff > 0 ~ "W",
                          matches$goal_diff == 0 ~ "D",
                          TRUE ~ "L")
all(as.character(matches$result) == check_result)   # expect TRUE

# Season record
table(matches$result)   # expect W 22, D 11, L 13

# FINDING (Step 2): goal_diff and result in 00_Load_data.R match a fresh
# calculation. Season record: 22 wins, 11 draws, 13 losses.

# ---- Step 3: Home vs away ----
home_away_table <- matches %>%
  group_by(home_away) %>%
  summarise(games = n(),
            mean_scored = mean(goals_scored),
            mean_conceded = mean(goals_conceded),
            mean_goal_diff = mean(goal_diff),
            W = sum(result == "W"),
            D = sum(result == "D"),
            L = sum(result == "L"))
home_away_table
write.csv(home_away_table, "outputs/matches_home_away_table.csv", row.names = FALSE)

# FINDING (Step 3): Ashford scored 1.74 goals per game at home compared with
# 0.87 away, and conceded 0.57 at home compared with 1.09 away. The home
# advantage is large: a swing of about 1.4 goals per game in goal difference
# (+1.17 at home vs -0.22 away). They won 15 of 23 home games but only 7 of 23 away.

# ---- Step 4: Opponent strength ----
p_scored <- ggplot(matches, aes(opponent_rank, goals_scored, colour = home_away)) +
  geom_point(size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Opponent final rank", y = "Goals scored by Ashford", colour = "Venue")
p_scored
ggsave("outputs/matches_scored_vs_rank.png", p_scored, width = 7, height = 5)

p_conceded <- ggplot(matches, aes(opponent_rank, goals_conceded, colour = home_away)) +
  geom_point(size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Opponent final rank", y = "Goals conceded by Ashford", colour = "Venue")
p_conceded
ggsave("outputs/matches_conceded_vs_rank.png", p_conceded, width = 7, height = 5)

cor(matches$opponent_rank, matches$goals_scored)     # about +0.34
cor(matches$opponent_rank, matches$goals_conceded)   # about -0.38

# FINDING (Step 4): There is a moderate trend with opponent strength. Ashford
# tend to score more (correlation about +0.34) and concede fewer goals
# (about -0.38) against lower-ranked opponents (higher rank numbers). The
# upward trend in home goals scored is partly driven by the 8-0 win against the
# rank 24 side; without it the correlation for goals scored falls to about 0.25.
# The data are paired: every opponent is played once at home and once away, so
# the two games against the same opponent are not fully independent.

# ---- Step 5: Count distributions ----
table(matches$goals_scored)
table(matches$goals_conceded)

p_bar_scored <- ggplot(matches, aes(goals_scored)) +
  geom_bar() +
  scale_x_continuous(breaks = 0:8) +
  labs(x = "Goals scored", y = "Number of matches")
p_bar_scored
ggsave("outputs/matches_goals_scored_bar.png", p_bar_scored, width = 7, height = 5)

p_bar_conceded <- ggplot(matches, aes(goals_conceded)) +
  geom_bar() +
  scale_x_continuous(breaks = 0:8) +
  labs(x = "Goals conceded", y = "Number of matches")
p_bar_conceded
ggsave("outputs/matches_goals_conceded_bar.png", p_bar_conceded, width = 7, height = 5)

matches %>%
  summarise(mean_scored = mean(goals_scored), var_scored = var(goals_scored),
            mean_conceded = mean(goals_conceded), var_conceded = var(goals_conceded)) %>%
  mutate(ratio_scored = var_scored / mean_scored,
         ratio_conceded = var_conceded / mean_conceded)

# FINDING (Step 5): Goals scored has mean 1.30 and variance 1.99 (variance/mean
# about 1.5), a hint of overdispersion. Goals conceded has mean 0.83 and
# variance 0.64 (ratio about 0.77), so there is no sign of overdispersion
# there. The most common outcomes are 1 goal scored (15 matches) and 1 goal
# conceded (22 matches). One match stands out with 8 goals scored.

# ---- Step 6: The 8-0 match ----
matches %>% filter(goals_scored == 8)   # confirm it is a home game vs rank 24

without_8_0 <- matches %>% filter(goals_scored < 8)   # new object; matches is untouched
nrow(without_8_0)   # expect 45

comparison_8_0 <- tibble(
  version = c("All 46 matches", "Without 8-0"),
  mean_scored = c(mean(matches$goals_scored), mean(without_8_0$goals_scored)),
  var_scored  = c(var(matches$goals_scored),  var(without_8_0$goals_scored))
) %>% mutate(ratio = var_scored / mean_scored)
comparison_8_0
write.csv(comparison_8_0, "outputs/matches_8_0_comparison.csv", row.names = FALSE)

# FINDING (Step 6): The 8-0 home win against the rank 24 side is a single
# extreme match. Removing it lowers the mean goals scored from 1.30 to 1.16
# and halves the variance from 1.99 to 1.00, so the variance/mean ratio falls
# from about 1.5 to about 0.86. The apparent overdispersion in goals scored is
# therefore almost entirely due to this one match. The match is kept in the
# data (see decision-notes).
