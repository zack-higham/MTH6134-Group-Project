#From 04e. model evaluates log odds of winning a match 
# As a function of playing location and opponent rank is a covariate, accounting for opposition quality.
matches$win <- as.integer(matches$result == "W")
table(win = matches$win, home_away = matches$home_away)   # 15/23 home, 7/23 away
m_win = glm(win ~ home_away + opponent_rank, family = binomial, data = matches)
summary(m_win)

plot(fitted(m_win))
plot(m_win)
rstandard(m_win)

#Export Residuals vs Fitted / Diagnostic Plots
png("outputs/win_diagnostics.png", width = 800, height = 800)
par(mfrow = c(2, 2))
plot(m_win)
dev.off()
#Residuals vs fitted has a distinct 2 band pattern due to the binary response data
#outcomes are strictly 0 or 1. Curve of best fit not useful. 
#QQ residuals follow ab line except at upper tail, showing potential outliers. 
#does not follow Gaussian dist. due to binary data hence cannot check normal distribution.

#Measuring the leverage that each point has.
hatvalues(m_win)
print(which(hatvalues(m_win)> 3 / 46))
win = ifelse(matches$goals_scored > matches$goals_conceded, 1, 0)
matches[hatvalues(m_win) > 3/46, c("home_away", "opponent_rank", "win")]
#p/n = 3/46 = 0.0652 is the average leverage (influence) that each point should have. 
#19 values have a leverage above 0.0652
#game 1 has the highest leverage since it is against the no.1 team at home.

#Cooks distance: measuring the influence of each individual match (data point)
png("outputs/win_cooks.png", width = 800, height = 800)
plot(m_win, which = 4)
dev.off()
#2p/n = 0.1304 is the point where the rule of thumb says this is an influential point. 
# all games have a cooks distance < 0.1. 
# indicating no single match severely distorts coefficient estimates.

#-Refit model excluding top Cook's distance point (match 27)
m_win_no27 = update(m_win, subset = -27)
# Compare coefficient estimates and odds ratios
coef_comparison = data.frame(
  Full_Model = coef(m_win),
  No_Row27_Model = coef(m_win_no27),
  Percent_Change = ((coef(m_win_no27) - coef(m_win)) / coef(m_win)) * 100
)
print(coef_comparison)
# Save the influence comparison output for team documentation
write.csv(coef_comparison, "outputs/win_influence_comparison.csv", row.names = TRUE)
#

#-Inspect Row 8 (8-0 Match) influence
cat("Row 8 Leverage:", hatvalues(m_win)[8], "\n")
cat("Row 8 Cook's Distance:", cooks.distance(m_win)[8], "\n")
#Note: Match 8 has moderate leverage (0.0772 > p/n) due to rank 24, but a negligible 
# Cook's distance (0.00558). Because the outcome is binary win (1), the 8-0 margin 
# carries no additional weight over a 1-0 win, preventing parameter distortion.