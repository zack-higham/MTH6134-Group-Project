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
| 12/10/2026 | Vish | Normal linear regression for minutes_played: coefficients, model selection, training_load numeric vs factor, residual plots | `code/02_linear_model.R`, `code/drafts/02_linear_model_draft.R`, `outputs/lm1_residuals.png`, `outputs/lm1_residuals_vs_fitted.png`, `outputs/lm1_coefficients.csv`, `outputs/lm1_drop1_results.csv` |
| 12/10/2026 | Liri | Variable roles table and justification of model family for each candidate response | `code/03a_variable_roles.R`, `notes/decision-notes.md` |
| 12/10/2026 | Zack | Linear model vs GLM comparison for goals (Poisson) and injury (binomial); summary written to decision notes | `code/03b_lm_vs_glm.R`, `outputs/` |
| 12/10/2026 | Zack | Workspace upkeep: fixed README and folder structure, recreated `outputs/` and `reports/`, added collaborators, checked scripts run | `README.md`, `outputs/README.md`, `reports/README.md` |

## Week 4 — Binomial regression

| Date | Member | Work done | Files |
|---|---|---|---|
| | Yousuf | Main logistic model for injury: odds ratios and interpretation | `code/04a_injury_logistic.R` |
| | Liha | Model selection and final injury model | `code/04b_injury_model_selection.R` |
| | Vish | Extensions: age², interactions, exposure, link functions | `code/04c_injury_extensions.R` |
| | Liri | Grouped binomial and team effect | `code/04d_grouped_binomial.R` |
| 15/10/2026 | Zack | Ashford win model (`win ~ home_away + opponent_rank`): odds ratios with 95% CIs, drop1 likelihood ratio tests, grouped observed-vs-fitted check by venue and opponent-rank band; predicted win probability plot with 95% bands; predicted injury probability plot from the final injury model (04b) | `code/04e_ashford_wins_and_predictions.R`, `outputs/win_*`, `outputs/injury_predicted_probabilities.csv`, `outputs/injury_prob_by_prev_injuries.png` |
| 15/10/2026 | Zack | Workspace upkeep: added `run_all.R` and ran all scripts from a fresh session; updated README (weeks 2–3 ticked, tidyverse note, all scripts listed), project status, and the outputs README (every output listed by script) | `run_all.R`, `README.md`, `notes/project-status.md`, `outputs/README.md` |
| 15/10/2026 | Zack | Workspace tidy-up: renamed misnamed files to the agreed naming (draft and test scripts moved to `code/drafts/`, two lm1 outputs renamed), removed a stray non-code line from `04b` so it runs, fixed the `03a` header comment, ran every script from a fresh session and committed the outputs that were missing | `code/drafts/`, `code/03a_variable_roles.R`, `code/04b_injury_model_selection.R`, `outputs/`, `README.md`, `outputs/README.md` |
