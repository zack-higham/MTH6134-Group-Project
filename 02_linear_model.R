# code/02_linear_model.R — Week 2: normal linear regression for a continuous outcome
source("code/00_load_data.R")

# Response: minutes_played (continuous, but capped at 3960 - note this)
lm1 <- lm(minutes_played ~ position + age + training_load + bmi + prev_injuries,
          data = players)
summary(lm1)
confint(lm1)

# Quick first look at residuals (full diagnostics in week 5)
png("outputs/lm1_residuals.png", width = 900, height = 800)
par(mfrow = c(2, 2))
plot(lm1)
dev.off()

# TODO: try dropping terms and compare (anova / AIC), record choice in decision-notes.md
# TODO: alternative continuous response, e.g. bmi
