source("code/00_load_data.R")

# Setup: using person 2's final model as the base model ----
# person 2 tested and found the following were of statistical significance, dropping other variables. 
m_base = glm(injured ~ age + training_load + prev_injuries, family = binomial(link = "logit"), data = players)
summary(m_base)

# Adding quadratic age term might capture non linear effects. Using likelihood ratio test.
m_age_squared = update(m_base, .~. + I(age**2))
anova(m_base, m_age_squared, test = "Chisq")
# p = 0.4 > 0.05, insufficient evidence to reject H0, keep linear age. 

#Testing interactions: retain base model without interaction terms. 

#Interaction 1: Training load & previous injuries. I.e. amount of prev injuries depends on training load
int_1 = update(m_base, .~. + training_load:prev_injuries)
anova(m_base, int_1, test = "Chisq")
# p=0.12 > 0.05, insufficient evidence to suggest interactions are of statistical significance.

#Interaction 2: Position and training load. I.e. does your position affect your training load.
int_2 = update(m_base, .~. + position*training_load)
anova(m_base, int_2, test = "Chisq")
# p=0.77 > 0.05, insufficient evidence to suggest interactions are of statistical significance.

#Testing exposure with log (mins played) to see if it is significant. G
#Given person 2 dropped minutes played due to lack of statistical significance.
m_log = glm(injured ~ age + training_load + prev_injuries + log(minutes_played + 1), family = binomial(link = "logit"), data = players)
AIC(m_base, m_log)
anova(m_base, m_log, test = "Chisq")
# p=0.52 > 0.05 & AIC AIC values (548.8 vs 547.3) are highly comparable; 
# showing a slight 1.5 unit preference for the logit model, confirming that the logit link is appropriate.
#Log transformed mins played adds no significant explanatory power, keep base model.

#Testing alternative link functions: probit & cloglog
m_probit = glm(formula(m_base), family = binomial(link = "probit"), data = players)
AIC(m_base, m_probit)
m_cloglog = glm(formula(m_base), family = binomial(link = "cloglog"), data = players)
AIC(m_base, m_cloglog)
#AIC of all 3 models are virtually identical hence staying with logit function: m_base.

#Creating comparison tables of results above.
extension_summary = data.frame(
  Model = c("Logit (Base)", "Probit", "Cloglog"),
  AIC = c(AIC(m_base), AIC(m_probit), AIC(m_cloglog)),
  ResidualDeviance = c(deviance(m_base), deviance(m_probit), deviance(m_cloglog))
)
dir.create("outputs", showWarnings = FALSE)
write.csv(extension_summary, "outputs/injury_extensions_comparison.csv")

#Plotting fitted probabilities against each other
png("outputs/link_functions_comparisons.png", width = 800, height = 800)
plot(fitted(m_base), fitted(m_probit), 
     xlab = "Logit Fitted Probabilities", 
     ylab = "Probit Fitted Probabilities",
     main = "Comparison of Logit vs Probit Fitted Probabilities")
abline(0, 1, col = "red", lty = 2)
dev.off()
