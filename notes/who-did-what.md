# Who did what

Running record of who worked on which part of the analysis. Each member adds their
own row when they finish a piece of work, and commits it under their own GitHub
account so the commit history matches this table.

Members: Yousuf, Liha, Vish, Liri, Zack

## Week 2–3

| Date | Member | Work done | Files |
|---|---|---|---|
| 12/10/2026 | Zack | Set up GitHub repo, folder structure, RStudio project and shared data loader; drafted variable classification | `README.md`, `.gitignore`, `MTH6134-project.Rproj`, `code/00_load_data.R`, `notes/` |
| 12/10/2026 | Yousuf | Players dataset exploration: summary table, distributions, minutes ceiling, injury rates by position / training load / previous injuries / team | `code/01a_explore_players.R`, `outputs/` |
| 12/10/2026 | Liha | Ashford matches exploration: home vs away, W/D/L record, goals vs opponent rank, count distributions, effect of the 8–0 match | `code/01b_explore_matches.R`, `outputs/` |
| 12/10/2026 | Vish | Normal linear regression for minutes_played: coefficients, model selection, training_load numeric vs factor, residual plots | `code/02_linear_model.R` (his original file: `code/drafts/02_linear_model_draft.R`); `outputs/lm1_*` |
| 12/10/2026 | Liri | Variable roles table and justification of model family for each candidate response | `code/03a_variable_roles.R`, `notes/decision-notes.md` |
| 12/10/2026 | Zack | Linear model vs GLM comparison for goals (Poisson) and injury (binomial); summary written to decision notes | `code/03b_lm_vs_glm.R`, `outputs/` |
| 16/10/2026 | Vish | Second response for the linear model (bmi), with drop1 F-tests; decision note on why bmi works better as an explanatory variable and why injured is excluded as a predictor of minutes | `code/02_linear_model.R`, `notes/decision-notes.md` |
| 16/10/2026 | Liri | Completed the week 3 variable roles: roles/type/distribution table in code and the expanded model rationale for each response in decision notes | `code/03a_variable_roles.R`, `notes/decision-notes.md` |
| 12/10/2026 | Zack | Workspace upkeep: fixed README and folder structure, recreated `outputs/` and `reports/`, added collaborators, checked scripts run | `README.md`, `outputs/README.md`, `reports/README.md` |

## Week 4 — Binomial regression

| Date | Member | Work done | Files |
|---|---|---|---|
| 19/10/2026 | Yousuf | Main logistic model for injury: odds ratios and interpretation | `code/04a_injury_logistic.R` (uploaded as `Statistical Modelling week4.R`), `outputs/injury_full_odds_ratios.csv` |
|16/10/2026 | Liha | Model selection and final injury model | `code/04b_injury_model_selection.R`, `outputs/injury_drop1_full.csv`, `outputs/injury_final_odds_ratios.csv` |
|18/10/2026 | Vish | Extensions: age², interactions, exposure, link functions | `code/04c_injury_extensions.R`, `outputs/injury_extensions_comparison.csv`, `outputs/link_functions_comparisons.png`, `notes/decision-notes.md` (week 4 checklist) |
| 16/10/2026 | Liri | Grouped binomial checks by team and position; tested adding a 23-df fixed team effect to the final injury model and documented the week 11 random-effect follow-up | `code/04d_grouped_binomial.R`, `outputs/injury_team_*`, `outputs/injury_position_grouped.csv`, `notes/decision-notes.md` |
| 15/10/2026 | Zack | Ashford win model (`win ~ home_away + opponent_rank`): odds ratios with 95% CIs, drop1 likelihood ratio tests, grouped observed-vs-fitted check by venue and opponent-rank band; predicted win probability plot with 95% bands; predicted injury probability plot from the final injury model (04b) | `code/04e_ashford_wins_and_predictions.R`, `outputs/win_*`, `outputs/injury_predicted_probabilities.csv`, `outputs/injury_prob_by_prev_injuries.png` |
| 15/10/2026 | Zack | Workspace upkeep: added `run_all.R` and ran all scripts from a fresh session; updated README (weeks 2–3 ticked, tidyverse note, all scripts listed), project status, and the outputs README (every output listed by script) | `run_all.R`, `README.md`, `notes/project-status.md`, `outputs/README.md` |
| 15/10/2026 | Zack | Workspace tidy-up: renamed misnamed files to the agreed naming (Vish's draft moved to `code/drafts/`, empty test file deleted, two lm1 outputs renamed), removed a stray non-code line from `04b` so it runs, fixed the `03a` header comment, ran every script from a fresh session and committed the outputs that were missing | `code/drafts/`, `code/03a_variable_roles.R`, `code/04b_injury_model_selection.R`, `outputs/`, `README.md`, `outputs/README.md` |
| 15/10/2026 | Zack | Edit only, not analysis: moved Vish's week 2 linear model from his original file into `02_linear_model.R` so it runs from the project folder (added the data loader, removed a personal `setwd()` path, switched on his two `write.csv` lines). The analysis and comments are Vish's; his original file is preserved unchanged in git history (commit `6fc4269`) | `code/02_linear_model.R` |
| 15/10/2026 | Zack | Workspace tidy-up: removed the `code/drafts/` folder (Vish's original week 2 file and the old starter), both superseded by `02_linear_model.R` and kept in git history at commit `6fc4269` (restored 19/10, see below) | `code/drafts/` |
| 19/10/2026 | Zack | Edit only, not analysis: renamed Yousuf's week 4 script to `04a_injury_logistic.R` and made it run (data loader added, `league_players` → `players`); added a marked [Zack] section with drop1 tests and term-by-term interpretation for Yousuf to review. The model is Yousuf's; his original is in git history (commit `8144dbc`) | `code/04a_injury_logistic.R`, `outputs/injury_full_odds_ratios.csv` |
| 19/10/2026 | Zack | Workspace upkeep for weeks 2–4: restored `code/drafts/`; wrote up the 04a, 04b and 04c decisions in decision notes from each script (owners to check); corrected the 15/10 tidy-up note; updated README, project status and outputs README; refitted every model to check the notes and ran all scripts from a fresh session | `code/drafts/`, `notes/`, `README.md`, `outputs/README.md` |
| 29/10/2026 | Vish | Week 4 check fixes: corrected the two `04c` comments (0.005 → 0.05; log(minutes) AIC 548.8 vs 547.3 written out); `02_linear_model.R` now sets GK as the baseline and writes `lm1_coefficients_annotated.csv` from code, with one interpretation per term on the right row *(row added by Zack from the commit history, 05/11; Vish to check)* | `code/02_linear_model.R`, `code/04c_injury_extensions.R`, `outputs/lm1_coefficients_annotated.csv` |

## Week 5 — Residuals and diagnostics

| Date | Member | Work done | Files |
|---|---|---|---|
| 20/10/2026 | Zack | Diagnostics for the Poisson goals-scored model and the influence of the 8–0 match: goodness of fit, dispersion, standardised residuals, leverage, Cook's distance, refit without the 8–0, leave-one-out refit of every match, quasipoisson check | `code/05e_goals_influence.R`, `outputs/goals_*` |
| 26/10/2026 | Liha | Grouped goodness-of-fit check for the final injury model (training_load × prev_injuries cells), with an optional grouped refit using age bands; decision note *(row added by Zack from the commit history, 05/11; Liha to check)* | `code/05b_injury_grouped_gof.R`, `outputs/injury_grouped_*`, `notes/decision-notes.md` |
| 26/10/2026 | Vish | Diagnostics for the Ashford win model: residual plots, leverage, Cook's distance, refit without the most influential match (27) and the leverage/Cook's distance of the 8–0. Updated 29/10 to report odds ratios with 95% CIs *(row added by Zack from the commit history, 05/11; Vish to check)* | `code/05c_win_diagnostics.R`, `outputs/win_diagnostics.png`, `outputs/win_cooks.png`, `outputs/win_influence_comparison.csv` |
| 07/11/2026 | Vish | Week 8 check fixes: added the data loader to `05c` so it runs on its own; `02` writes the drop1 table to `lm1_drop1_results.csv` again and the baseline comment now says GK. 08/11: `05c` CIs switched from Wald (`confint.default`) to profile likelihood (`confint`) to match `04e` *(row added by Zack from the commit history, 19/11; Vish to check)* | `code/05c_win_diagnostics.R`, `code/02_linear_model.R` |
| 08/11/2026 | Vish | Diagnostics for the minutes linear model: residual plots with the 16 ceiling players highlighted, leverage and Cook's distance (two influential players, neither at the ceiling), refit without the 16 ceiling players with 95% CIs *(row added by Zack from the commit history, 19/11; Vish to check)* | `code/05d_minutes_diagnostics.R`, `outputs/lm1_diagnostics_ceiling.png`, `outputs/lm1_leverage_cooks.png`, `outputs/lm1_ceiling_sensitivity.csv` |
| 09/11/2026 | Liri | Diagnostics for grouped binomial models: team residuals, position × training-load residual/QQ/leverage/Cook checks, and sensitivity refit without the most influential cell | `code/05d_grouped_diagnostics.R`, `outputs/team_grouped_diagnostics.csv`, `outputs/team_residuals.png`, `outputs/position_load_*`, `notes/decision-notes.md` |
| 09/11/2026 | Yousuf | Player-level diagnostics for the final injury model (the open `05a` task): standardised deviance and Pearson residuals, Q-Q plot, players with \|residual\| > 2, leverage above 2p/n, Cook's distance, refit without the five most influential players. Same file also has the position × injury table (see week 8). Script doesn't run yet and outputs not committed *(row added by Zack from the commit history, 19/11; Yousuf to check)* | `code/Week4 and Week5.R` (now `code/drafts/`) |
| 22/11/2026 | Yousuf | Got `05a` running: split Part 1 of my 09/11 script into `05a_injury_diagnostics.R` (data loader, `players` not `league_players`, duplicate `write.csv` removed); added a binned residual plot (average residual in ~25 bins of fitted probability with ±2 SE bands: 2 of 24 bins outside, no pattern, so no evidence of lack of fit); ran from a fresh session and committed the outputs; original moved to `code/drafts/` | `code/05a_injury_diagnostics.R`, `outputs/injury_final_*`, `outputs/injury_unusual_players.csv`, `outputs/injury_high_leverage.csv`, `outputs/injury_top5_influential.csv`, `outputs/injury_influence_comparison.csv`, `outputs/injury_binned_residuals.*`, `code/drafts/Week4 and Week5.R` |

## Week 6

| Date | Member | Work done | Files |
|---|---|---|---|
| 09/11/2026 | Liri | Three-way previous-injury band × training-load band × injury table; log-linear model selection and conditional-independence tests; equivalent grouped binomial model; collapsibility, age-adjusted comparison and independence graph | `code/06d_injury_loglinear.R`, `outputs/table_prev_load_injured.csv`, `outputs/injury_loglinear_*`, `outputs/loglinear_*`, `outputs/injury_marginal_*`, `outputs/injury_banded_*`, `outputs/independence_graph_injury.png`, `notes/decision-notes.md` |
| 06/11/2026 | Zack | Poisson model selection for goals scored: home_away × opponent_rank interaction (LRT, AIC), linear v log opponent rank (AIC, and LRTs via the model with both), drop1 LRTs and rate ratios with 95% CIs for the final model, the same selection without the 8–0 | `code/06b_goals_scored_selection.R`, `outputs/goals_scored_model_selection.csv` |
| 26/10/2026 | Zack | Home/away × result (W/D/L) contingency table: chi-squared test, the same test as a log-linear model, odds ratios with 95% CIs, link to the binomial win model, exploratory three-way table with opponent-rank band (model selection, conditional independence, collapsibility), stacked bar plot | `code/06e_venue_result_table.R`, `outputs/table_*`, `outputs/venue_*` |
| 05/11/2026 | Zack | Workspace upkeep for weeks 5–6: added the week 5–6 rows above (others' rows from the commit history, for owners to check); wrote up the 05c, 05e and 06e decisions and Vish's 29/10 changes in decision notes; updated README, outputs README and project status; fixed `run_all.R` so it clears the global environment before each script (it had let `05c` pass without loading the data); added `Rplots.pdf` to `.gitignore`; refitted the 05c model to check the notes and ran all scripts from a fresh session | `run_all.R`, `notes/`, `README.md`, `outputs/README.md`, `.gitignore` |

## Week 8 — Contingency tables I

| Date | Member | Work done | Files |
|---|---|---|---|
| 06/11/2026 | Zack | Age band × previous-injury band × injured table: log-linear model with the explanatory margin fixed, shown identical to the grouped logistic model (estimates, SEs, deviance); three-way term tested as the age × prev interaction; odds ratios with 95% CIs; comparison with `04b`; cell residuals | `code/08d_age_prev_injury_table.R`, `outputs/table_age_prev_injury.csv`, `outputs/age_prev_loglinear_vs_logistic.csv` |
| 09/11/2026 | Yousuf | Position × injury table: chi-squared test and expected counts, grouped logistic v log-linear model, three-way table with previous-injury band (log-linear selection), marginal v partial (within-band) position odds ratios. Script doesn't run yet and outputs not committed *(row added by Zack from the commit history, 19/11; Yousuf to check)* | `code/Week4 and Week5.R` (sections 2–6; now `code/drafts/`) |
| 22/11/2026 | Yousuf | Got `08a` running: split Part 2 of my 09/11 script into `08a_position_injury_table.R` (data loader, `players` not `league_players`, `injury_counts` now created before the grouped logistic model, repeated fits removed); ran from a fresh session and committed the outputs. Results unchanged from the 09/11 write-up | `code/08a_position_injury_table.R`, `outputs/table_position_injured*.csv`, `outputs/expected_counts_position_injured.csv`, `outputs/marginal_position_odds_ratios.csv`, `outputs/partial_position_odds_ratios.csv` |
| 19/11/2026 | Zack | Workspace upkeep for weeks 6–8: added the rows above for 06/11–09/11 (others' rows from the commit history, for owners to check); wrote up 05d (Vish), 06b, 08d and Yousuf's 09/11 script in decision notes; updated README, outputs README and project status; ran all scripts from a fresh session; drafted the week 9 task list | `notes/`, `README.md`, `outputs/README.md` |

## Week 9 — Ordinal and matched-pairs models

| Date | Member | Work done | Files |
|---|---|---|---|
| 23/11/2026 | Liri | Paired comparison of Ashford's home and away goals within opponent: opponent-fixed-effect Poisson model, equivalent conditional binomial model, complete-pair sensitivity excluding the opponent involved in the 8–0, fit checks and Bradley–Terry decision | `code/09d_goals_paired.R`, `outputs/goals_paired_*`, `notes/decision-notes.md` |
| 22/11/2026 | Vish | Conditional logistic regression for win with opponent as the stratum (`survival::clogit`, exact): away v home OR 0.273 (0.076–0.978), LRT 4.86 on 1 df (p = 0.027), score test; discordant-pair table; comparison with 04e. Same day: `05c` refactored to profile-likelihood CIs with an extra refit without the 8–0 *(row added by Zack from the commit history, 26/11; Vish to check. The regenerated `win_influence_comparison.csv` is not yet committed)* | `code/09c_win_conditional_logistic.R`, `outputs/win_conditional_logistic.csv`, `code/05c_win_diagnostics.R` |
| 26/11/2026 | Zack | Proportional-odds model for Ashford's result (L < D < W) with `MASS::polr`: model selection (LRTs, AIC; interaction and log rank rejected); cumulative ORs with profile CIs (away 0.19, rank 1.125 per place); proportional-odds checks (cumulative logits, separate binary logits, LRT v `nnet::multinom`, p = 0.42); grouped observed-v-fitted check, link comparison, leave-one-out influence incl. the 8–0; fitted P(L/D/W) at ranks 1, 12, 24 and plot (report Figure 3); comparison table of the away OR across 04e, 09a, 09c (report Table 3) | `code/09a_result_ordinal.R`, `outputs/result_ordinal_*`, `outputs/result_away_or_comparison.csv`, `notes/decision-notes.md` |

## Week 11 — GLMMs

| Date | Member | Work done | Files |
|---|---|---|---|
| 26/11/2026 | Zack | Poisson GLMM for goals scored with a random opponent effect (`lme4::glmer`, AGQ): random-effect variance and boundary LRT v the 06b GLM (p = 0.14), computed from the marginal likelihood by numerical integration because `lme4`'s AGQ log-likelihood is on a different scale to `glm()`; rate ratios v 06b and 09d (away RR 0.50 in all three); 8–0 sensitivity (variance goes to 0); predicted opponent effects; residual checks | `code/11b_goals_opponent_glmm.R`, `outputs/goals_glmm_*`, `notes/decision-notes.md` |
| 26/11/2026 | Zack | Workspace upkeep for weeks 9–11: added the 22/11 row for Vish's 09c and 05c work (from the commit history, for Vish to check); wrote up 09a, 11b and the week 9–11 check in decision notes; updated README (scripts, `lme4` note, progress), outputs README and project status (now the final submission plan); ran all 27 scripts from a fresh session and recorded the two outputs that don't match (05c, 05d grouped) | `notes/`, `README.md`, `outputs/README.md` |
