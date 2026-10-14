source("code/00_load_data.R")
library(tidyverse)

# ---- Setup: full model (same as Person 1) ----
players$position  <- relevel(factor(players$position), ref = "GK")
players$minutes_k <- players$minutes_played / 1000   # per 1,000 minutes

m_full <- glm(injured ~ position + age + minutes_k + training_load + prev_injuries + bmi,
              family = binomial, data = players)
summary(m_full)

# ---- Likelihood ratio tests ----
d1 <- drop1(m_full, test = "Chisq")
d1
write.csv(as.data.frame(d1), "outputs/injury_drop1_full.csv")

# ---- Backward elimination (drop largest p each round, stop when all p < 0.05) ----
m_cur <- m_full
repeat {
  d <- drop1(m_cur, test = "Chisq")
  print(d)
  p <- d[-1, "Pr(>Chi)"]
  names(p) <- rownames(d)[-1]
  if (max(p) < 0.05) break
  worst <- names(which.max(p))
  cat("Dropping:", worst, "\n")
  m_cur <- update(m_cur, as.formula(paste(". ~ . -", worst)))
}
m_lrt <- m_cur
formula(m_lrt)

# ---- AIC ----
m_aic <- step(m_full)
formula(m_aic)
AIC(m_full, m_lrt, m_aic)

# ---- training_load: numeric vs factor ----
m_tl_fac <- update(m_full, . ~ . - training_load + factor(training_load))
anova(m_full, m_tl_fac, test = "Chisq")

# ---- prev_injuries: numeric vs factor ----
table(players$prev_injuries)
m_pi_fac <- update(m_full, . ~ . - prev_injuries + factor(prev_injuries))
anova(m_full, m_pi_fac, test = "Chisq")

# ---- Final model ----
m_final <- glm(injured ~ age + training_load + prev_injuries,
               family = binomial, data = players)
summary(m_final)

or_tab <- exp(cbind(OR = coef(m_final), confint(m_final)))
colnames(or_tab) <- c("OR", "lower95", "upper95")
round(or_tab, 3)
write.csv(round(or_tab, 3), "outputs/injury_final_odds_ratios.csv")


# FINDING: Backward elimination by likelihood ratio tests and AIC both select
# age + training_load + prev_injuries. minutes_k (p = 0.96), bmi (p = 0.58)
# and position (p = 0.43 at the point it was dropped) are not associated with
# injury once the other variables are accounted for. Goalkeepers have the
# highest raw injury rate (27%), but with only 62 goalkeepers the data cannot
# distinguish a real position effect from chance.
# training_load (p = 0.24) and prev_injuries (p = 0.77) are adequately
# modelled as numeric; the factor versions do not improve the fit.
# Holding the other variables fixed, each additional previous injury is
# associated with the odds of injury being multiplied by about 1.67
# (95% CI 1.40 to 1.99).

Add Person 2 injury model selection
