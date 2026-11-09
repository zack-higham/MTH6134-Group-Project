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
| `lm1_coefficients_annotated.csv` | Coefficients, SEs, t values, p-values and 95% CIs for `minutes_played ~ position + age + training_load + bmi + prev_injuries` (GK baseline), with a written interpretation of each term. Script-generated since 29/10; before that it was saved by hand with DEF as the baseline |
| `drop1_results.csv` | F-test `drop1` results for the same model. Since 29/10 the script writes this name again; the committed copy is `lm1_drop1_results.csv` (renamed 15/10). To be fixed in the script (Vish) |
| `lm1_residuals.png` | The four residual plots for the same model |

**No longer made by any script** (kept)
| File | Contents |
|---|---|
| `lm1_coefficients.csv` | The same coefficient table without interpretations, saved by `02` before its 29/10 update |
| `lm1_drop1_results.csv` | The committed drop1 table (see `drop1_results.csv` above) |
| `lm1_residuals_vs_fitted.png` | Residuals vs fitted for the linear model, saved by hand from Vish's original week 2 file *(renamed from `Plot of lm1 (mins played = pos + age + training+ bmi + prev_injuries).png`)* |

## Week 3 — GLMs

**`03b_lm_vs_glm.R`** (Zack)
| File | Contents |
|---|---|
| `lm_goals_residuals.png` | Linear model for goals: residuals vs fitted and normal Q-Q |
| `goals_lm_vs_glm_predictions.csv` | Predicted goals from the linear model and the Poisson GLM, home/away × opponent rank 1, 12, 24 |
| `goals_lm_vs_glm.png` | Goals scored with linear model and Poisson GLM fitted curves |
| `injured_lm_vs_glm.png` | Linear probability model residuals, and LM vs logistic fitted probabilities |

## Week 4 — Binomial regression

**`04a_injury_logistic.R`** (Yousuf)
| File | Contents |
|---|---|
| `injury_full_odds_ratios.csv` | Odds ratios and 95% CIs for the full injury model (all six predictors, GK baseline, minutes per 1,000) |

**`04b_injury_model_selection.R`** (Liha)
| File | Contents |
|---|---|
| `injury_drop1_full.csv` | Likelihood ratio test for each term in the full injury model |
| `injury_final_odds_ratios.csv` | Odds ratios and 95% CIs for the final injury model (`injured ~ age + training_load + prev_injuries`) |

**`04c_injury_extensions.R`** (Vish)
| File | Contents |
|---|---|
| `injury_extensions_comparison.csv` | AIC and residual deviance of the final injury model with logit, probit and cloglog links |
| `link_functions_comparisons.png` | Logit vs probit fitted injury probabilities |

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


## Week 5 — Residuals and diagnostics

**`05b_injury_grouped_gof.R`** (Liha)
| File | Contents |
|---|---|
| `injury_grouped_obs_vs_fitted.csv` | Observed v expected injuries in each training_load × prev_injuries cell, with Pearson residuals and small-cell flags |
| `injury_grouped_fit.png` | Observed v fitted injury proportion by cell |
| `injury_grouped_age_band_gof.csv` | Deviance and Pearson goodness-of-fit tests for the grouped model with age in bands |
| `injury_grouped_age_band_cells.csv` | Cell counts and fitted values for the age-band grouped model |
| `injury_grouped_age_band_or.csv` | Odds ratios and 95% CIs from the age-band grouped model |

**`05c_win_diagnostics.R`** (Vish)
| File | Contents |
|---|---|
| `win_diagnostics.png` | The four standard residual plots for the win model |
| `win_cooks.png` | Cook's distance for each match |
| `win_influence_comparison.csv` | Odds ratios and 95% Wald CIs with and without match 27 (the largest Cook's distance) |

**`05d_grouped_diagnostics.R`** (Liri)
| File | Contents |
|---|---|
| `team_grouped_diagnostics.csv` | Team injury counts, fitted rates, standardised deviance and Pearson residuals, leverage, Cook's distance and residual flags |
| `team_residuals.png` | Index plot of standardised deviance residuals for all 24 teams |
| `position_load_cell_diagnostics.csv` | Observed and fitted rates plus residual, leverage and influence diagnostics for the 20 position × training-load cells |
| `position_load_diagnostics.png` | Residual-v-fitted, QQ, leverage and Cook's-distance plots for the grouped cell model |
| `position_load_influence_comparison.csv` | Coefficients, odds ratios and 95% Wald CIs with and without the cell having the largest Cook's distance |

**`05e_goals_influence.R`** (Zack)
| File | Contents |
|---|---|
| `goals_poisson_rate_ratios.csv` | Rate ratios and 95% CIs for `goals_scored ~ home_away + opponent_rank` |
| `goals_diagnostics_table.csv` | Fitted values, standardised deviance and Pearson residuals, leverage and Cook's distance for every match |
| `goals_residuals.png` | Residuals v fitted, v opponent rank, and normal Q-Q |
| `goals_leverage_cooks.png` | Leverage and Cook's distance by match |
| `goals_8nil_influence.csv` | Rate ratios, CIs and LRT p-values with and without the 8–0 |
| `goals_8nil_fit_summary.csv` | Deviance, df and Pearson dispersion with and without the 8–0 |
| `goals_8nil_fitted_curves.png` | Fitted expected goals against opponent rank, with and without the 8–0 |
| `goals_8nil_predictions.csv` | Expected goals at ranks 1, 12 and 24, home and away, with and without the 8–0 |
| `goals_leave_one_out.csv` | Rate ratios, LRT p-values and Cook's distance after leaving out each match in turn |
| `goals_poisson_vs_quasi.csv` | Standard errors under Poisson and quasipoisson |

## Week 6

**`06e_venue_result_table.R`** (Zack)
| File | Contents |
|---|---|
| `table_venue_result.csv` | Home/away × W/D/L counts with expected counts and Pearson residuals |
| `venue_result_tests.csv` | Pearson chi-squared and log-linear likelihood ratio tests of association |
| `venue_result_odds_ratios.csv` | Odds ratios (W v L, D v L, away v home) with 95% CIs |
| `venue_win_loglinear_vs_logistic.csv` | The log-linear interaction for win/not win v the logistic home_away coefficient |
| `table_rank_venue_result.csv` | Three-way table, rank band × venue × result, with fitted values and residuals |
| `venue_result_loglinear_selection.csv` | Log-linear model selection for the three-way table |
| `venue_result_marginal_vs_conditional_or.csv` | Venue-result odds ratios: marginal v conditional on rank band |
| `venue_result_by_rank.png` | Result proportions by venue, overall and within rank bands |
