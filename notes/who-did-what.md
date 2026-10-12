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
| 12/10/2026 | Vish | Normal linear regression for minutes_played: coefficients, model selection, training_load numeric vs factor, residual plots | `code/02_linear_model.R`, `outputs/lm1_*`, `lm1_residuals.png`, `Plot of lm1 (mins played = pos + age + training+ bmi + prev_injuries)`, `lm1_coefficients.csv`, `drop1_results.csv` |
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
| | Zack | Ashford win model, prediction plots, workspace upkeep | `code/04e_ashford_wins_and_predictions.R` |
