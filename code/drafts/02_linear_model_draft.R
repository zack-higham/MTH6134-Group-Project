#fits the lm to all the variables given. uses defender as the base position to compare to. 
lm1 = lm(minutes_played ~ position + age + training_load + bmi + prev_injuries, data = league_players)

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
setwd("C:/Users/ah23304/OneDrive - Queen Mary, University of London/Stats modelling 2 lab/Project/Weekly tasks (R studio workings)")
##write.csv(coef_summary, "outputs/lm1_coefficients.csv", row.names = TRUE) 

#Run the drop cmd with an F test to see the p value of each variable if dropped. 
drop_results = drop1(lm1, test = "F")
AIC(lm1)
#Position & training load are the only variables with statistical significance, drop the rest. 
##write.csv(drop_results, "outputs/drop1_results.csv", row.names = TRUE)
#creating the lm with the 2 variables of statistical significance. 
lm2 = lm(minutes_played ~ position + training_load, data = league_players)
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
