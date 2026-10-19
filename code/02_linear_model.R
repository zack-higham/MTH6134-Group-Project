# 02_linear_model.R — Week 2: normal linear regression for a continuous outcome
# Author: Vish. The analysis and comments below are his work.
#
# Edit by Zack (15/10/2026): moved here from Vish's original file,
# preserved unchanged in git history at commit 6fc4269 (code/drafts/), so it runs from the
# project folder. Only the setup was changed, no analysis:
#   - added source("code/00_load_data.R") and used `players` instead of
#     `league_players`;
#   - removed setwd() with a personal OneDrive path (paths are relative);
#   - un-commented the two write.csv lines and named the drop1 table
#     lm1_drop1_results.csv, to match the other lm1_* outputs.
# Lines marked [Zack] are editorial notes, not part of the analysis.
source("code/00_load_data.R")

#fits the lm to all the variables given. uses defender as the base position to compare to.
# [Zack] note: 00_load_data.R sets GK as the baseline position, so position
# coefficients are relative to goalkeepers.
lm1 = lm(minutes_played ~ position + age + training_load + bmi + prev_injuries, data = players)

#creates a summary of lm1 & exports it to Excel.
summary(lm1)
coef_summary <- data.frame(
  Estimate = coef(lm1),
  Std.Error = summary(lm1)$coefficients[, "Std. Error"],
  t_value = summary(lm1)$coefficients[, "t value"],
  p_value = summary(lm1)$coefficients[, "Pr(>|t|)"],
  CI_lower = confint(lm1)[, 1],
  CI_upper = confint(lm1)[, 2]
)
write.csv(coef_summary, "outputs/lm1_coefficients.csv", row.names = TRUE)

#Run the drop cmd with an F test to see the p value of each variable if dropped.
drop_results = drop1(lm1, test = "F")
AIC(lm1)
#Position & training load are the only variables with statistical significance, drop the rest.
write.csv(drop_results, "outputs/lm1_drop1_results.csv", row.names = TRUE)
#creating the lm with the 2 variables of statistical significance.
lm2 = lm(minutes_played ~ position + training_load, data = players)
summary(lm2)
coef_summary2 <- data.frame(
  Estimate = coef(lm2),
  Std.Error = summary(lm2)$coefficients[, "Std. Error"],
  t_value = summary(lm2)$coefficients[, "t value"],
  p_value = summary(lm2)$coefficients[, "Pr(>|t|)"],
  CI_lower = confint(lm2)[, 1],
  CI_upper = confint(lm2)[, 2]
)

#training load is a numeric, but it represents ordered categories.
lm1_factor = update(lm1, .~. - training_load + factor(training_load))
anova(lm1, lm1_factor)
# p value = 0.7313, insufficient evidence that treating training load as a factor is beneficial. Numeric assumption is adequate.

#creating and exporting the plots
png("outputs/lm1_residuals.png", width = 800, height = 800)
par(mfrow = c(2, 2))
plot(lm1)
dev.off()

#Second response analysis: using BMI as the response variable
# [Zack] TODO (Vish): this section was empty in the original file.
lm_bmi = lm(bmi ~ position + age + training_load + prev_injuries + injured, data = players)
summary(lm_bmi)
drop1(lm_bmi, test = "F")
AIC(lm_bmi)
#0 variables of statistical significance, bmi is better as an explanatory variable. 
