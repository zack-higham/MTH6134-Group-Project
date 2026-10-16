# Outputs

Plots and tables produced by the scripts in `code/`. Keep everything here, including outputs that don't make it into the final report.

Every file below is recreated by running `source("run_all.R")` from a fresh R session, except where marked *(not script-generated)*.

## Week 2 — Exploration

**`01_explore.R`** (Zack; original combined exploration, kept)
| File | Contents |
|---|---|
| `players_histograms.png` | Histograms of age, BMI and minutes played, and a bar chart of training load |
| `injury_rate_by_position.png` | Proportion injured by position |
| `goals_vs_opponent_rank.png` | Goals scored and conceded against opponent rank, home vs away |

**`01a_explore_players.R`** (Yousuf)
| File | Contents |
|---|---|
| `players_summary_table.csv` | Mean, SD, median, min and max of the numeric player variables |
| `players_distributions.png` | Distributions of the player variables |
| `injury_rates_position.csv` | Injury rate by position |
| `injury_rates_training_load.csv` | Injury rate by training load |
| `injury_rates_prev_injuries.csv` | Injury rate by number of previous injuries |
| `injury_rates_team.csv` | Injury rate by team |
| `injury_rate_position.png` | Bar chart: injury rate by position |
| `injury_rate_training_load.png` | Bar chart: injury rate by training load |
| `injury_rate_prev_injuries.png` | Bar chart: injury rate by previous injuries |
| `injury_rate_team.png` | Bar chart: injury rate by team, with the league-wide rate marked |
| `players_relationships.png` | Relationships between player variables (e.g. age vs minutes played) |
| `correlation_matrix.csv` | Correlations between the numeric explanatory variables |

**`01b_explore_matches.R`** (Liha)
| File | Contents |
|---|---|
| `matches_home_away_table.csv` | Games, mean goals scored/conceded/difference and W/D/L, home vs away |
| `matches_scored_vs_rank.png` | Goals scored against opponent rank |
| `matches_conceded_vs_rank.png` | Goals conceded against opponent rank |
| `matches_goals_scored_bar.png` | Distribution of goals scored |
| `matches_goals_conceded_bar.png` | Distribution of goals conceded |
| `matches_8_0_comparison.csv` | Mean, variance and variance/mean ratio of goals scored, with and without the 8–0 match |

**`02_linear_model.R`** (Vish)
| File | Contents |
|---|---|
| `lm1_coefficients.csv` | Coefficients, SEs, t values, p-values and 95% CIs for `minutes_played ~ position + age + training_load + bmi + prev_injuries` (GK baseline) |
| `lm1_drop1_results.csv` | F-test `drop1` results for the same model (renamed from `drop1_results.csv`) |
| `lm1_residuals.png` | The four residual plots for the same model |

**Saved by hand** (Vish, from his original week 2 file, kept in git history at commit `6fc4269`; no script recreates these)
| File | Contents |
|---|---|
| `lm1_coefficients_annotated.csv` | Vish's coefficient table with his written interpretation of each term, R², AIC and the training_load factor test. Defender is the baseline position here, so position effects differ from `lm1_coefficients.csv` (GK baseline). Originally committed as `lm1_coefficients.csv`. |
| `lm1_residuals_vs_fitted.png` | Residuals vs fitted for the linear model *(not script-generated; renamed from `Plot of lm1 (mins played = pos + age + training+ bmi + prev_injuries).png`)* |

## Week 3 — GLMs

**`03b_lm_vs_glm.R`** (Zack)
| File | Contents |
|---|---|
| `lm_goals_residuals.png` | Linear model for goals: residuals vs fitted and normal Q-Q |
| `goals_lm_vs_glm_predictions.csv` | Predicted goals from the linear model and the Poisson GLM, home/away × opponent rank 1, 12, 24 |
| `goals_lm_vs_glm.png` | Goals scored with linear model and Poisson GLM fitted curves |
| `injured_lm_vs_glm.png` | Linear probability model residuals, and LM vs logistic fitted probabilities |

## Week 4 — Binomial regression

**`04b_injury_model_selection.R`** (Liha)
| File | Contents |
|---|---|
| `injury_drop1_full.csv` | Likelihood ratio test for each term in the full injury model |
| `injury_final_odds_ratios.csv` | Odds ratios and 95% CIs for the final injury model (`injured ~ age + training_load + prev_injuries`) |

**`04d_grouped_binomial.R`** (Liri)
| File | Contents |
|---|---|
| `injury_team_grouped.csv` | Team injury counts, squad sizes, observed rates and common fitted rate |
| `injury_team_grouped_gof.csv` | Deviance and Pearson checks for extra-binomial team variation |
| `injury_team_lrt.csv` | Likelihood-ratio and AIC comparison of the final injury model with and without fixed team effects |
| `injury_position_grouped.csv` | Observed and grouped-binomial fitted injury rates by position |

**`04e_ashford_wins_and_predictions.R`** (Zack)
| File | Contents |
|---|---|
| `win_odds_ratios.csv` | Odds ratios and 95% CIs for `win ~ home_away + opponent_rank` |
| `win_drop1_lrt.csv` | Likelihood ratio test for each term in the win model |
| `win_grouped_check.csv` | Observed vs fitted wins by venue and opponent-rank band, with Pearson residuals |
| `win_predicted_probabilities.csv` | Predicted win probability and 95% CI for each opponent rank, home and away |
| `win_prob_by_rank.png` | Predicted win probability against opponent rank, with 95% bands |
| `injury_predicted_probabilities.csv` | Predicted injury probability and 95% CI by previous injuries × training load, at age 25 |
| `injury_prob_by_prev_injuries.png` | Predicted injury probability against previous injuries, one line per training load |

*Still to come this week:* outputs from `04a` (Yousuf) and `04c` (Vish).
