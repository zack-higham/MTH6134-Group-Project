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
|17/10/2026 | Yousuf | Main logistic model for injury: odds ratios and interpretation | `code/04a_injury_logistic.R` (uploaded as `Statistical Modelling week4.R`), `outputs/injury_full_odds_ratios.csv` |
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
