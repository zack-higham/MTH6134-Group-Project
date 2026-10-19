# MTH6134 Group Project — Progress and Status

*Last updated: 19/10/2026 (end of week 4 check)*

## Group (5)

| Member | Role |
|---|---|
| Yousuf | Analysis |
| Liha | Analysis |
| Vish | Analysis |
| Liri | Analysis |
| Zack | Analysis and workspace upkeep (GitHub owner) |

## GitHub repo structure

All folder and file names are lowercase. Paths are case-sensitive on GitHub and Linux.

```
README.md
.gitignore
MTH6134-project.Rproj
run_all.R    runs every numbered script in code/ in order and reports failures
code/        numbered R scripts; each starts with source("code/00_load_data.R")
code/drafts/ superseded drafts, kept but not run
data/        league_players.csv, ashford_matches.csv
outputs/     plots (.png) and tables (.csv) saved by the scripts
notes/       decision-notes.md, who-did-what.md, project-status.md
reports/     final group + individual reports (later)
```

- All code uses base R and relative paths, except `01b` and `04b`, which load the tidyverse. Open the `.Rproj` before running anything.
- `00_load_data.R` reads both CSVs. It sets `position` (GK baseline) and `home_away` (Home baseline) as factors, and adds `training_load_f` (ordered factor), `goal_diff`, and `result` (ordered L < D < W).
- **Naming:** `NN` + a letter per task + a short description, e.g. `05a_injury_diagnostics.R`. The number at the start matters: `run_all.R` only runs files whose names start with a digit.

## Scripts

All 12 numbered scripts run cleanly from a fresh session with `source("run_all.R")` (checked 19/10/2026).

| Script | Week | Owner | Status |
|---|---|---|---|
| `00_load_data.R` | — | Zack | Done |
| `01_explore.R` | 2 | Zack | Kept (original combined exploration, split into 01a/01b) |
| `01a_explore_players.R` | 2 | Yousuf | Done |
| `01b_explore_matches.R` | 2 | Liha | Done |
| `02_linear_model.R` | 2 | Vish | Done (bmi response added 16/10) |
| `03a_variable_roles.R` | 3 | Liri | Done |
| `03b_lm_vs_glm.R` | 3 | Zack | Done |
| `04a_injury_logistic.R` | 4 | Yousuf | Done (renamed and made to run by Zack, 19/10; Yousuf to review the [Zack] interpretation section) |
| `04b_injury_model_selection.R` | 4 | Liha | Done |
| `04c_injury_extensions.R` | 4 | Vish | Done |
| `04d_grouped_binomial.R` | 4 | Liri | Done |
| `04e_ashford_wins_and_predictions.R` | 4 | Zack | Done |
| `run_all.R` | — | Zack | Done |

---

## Weeks 2–3 — DONE (12/10/2026)

### Yousuf: players exploration (`01a`)
- 620 players, 24 clubs, no missing values.
- Overall injury rate 18.5%. GK has the highest rate (27%).
- Injury rate rises with previous injuries: 11% (0), 19% (1), 28% (2), 39% (3), 43% (4).
- Injury rate is higher at training load 4–5 (~26%) than at 1–3 (11–16%).
- Team injury rates range from 8% (Moorfield, Penwick) to 44% (Grantwick).
- 16 players sit at the 3960-minute ceiling, 12 of them goalkeepers.
- Explanatory variables are nearly uncorrelated (largest |r| = 0.21, training_load vs minutes).

### Liha: Ashford matches exploration (`01b`)
- Home W15 D5 L3. Away W7 D6 L10.
- Goals scored per game: 1.74 at home vs 0.87 away. Conceded: 0.57 vs 1.09.
- Correlation with opponent rank: goals scored r = +0.34, goals conceded r = −0.38.
- The 8–0 home win v the rank-24 side is the only source of apparent overdispersion:
  - with it, variance 2.0 vs mean 1.30;
  - without it, variance 1.0 vs mean 1.16.
- **Kept in the data.** Its influence is to be checked in week 5.
- Every opponent is played twice (home and away), so the data are paired.

### Vish: linear regression (`02`)
- `minutes_played ~ position + age + training_load + bmi + prev_injuries`, R² = 0.28.
- Position dominates. Compared with GK: DEF −580, MID −900, FWD −1200 minutes.
- Training load: +145 minutes per level.
- Age, bmi and prev_injuries are not significant (p > 0.5).
- training_load kept numeric. The factor version is no better (F = 0.43 on 3 df, p = 0.73).
- bmi as a response (added 16/10): no predictor is significant, so bmi is kept as an explanatory variable.
- Limitation: the 3960-minute ceiling shows up in the residuals.

### Liri: variable roles (`03a`)

| Response | Type | Planned model | Week |
|---|---|---|---|
| injured | Binary | Binomial GLM, logit link (odds ratios) | 4 |
| goals_scored / goals_conceded | Count | Poisson GLM, log link (rate ratios) | 6 |
| result (W/D/L) | Ordinal | Ordinal / proportional-odds model | 10 |
| injured, players within teams | Grouped binary | Binomial GLMM, random team effect | 11 |

- prev_injuries is treated as a predictor of injury, not as a response.
- team is a grouping variable, not 23 dummy variables.

### Zack: linear model vs GLM (`03b`)
- **Goals:**
  - The LM predicts 0.08 goals away v the top side (Poisson GLM: 0.43), and its prediction intervals go below 0.
  - Residual variance is ~3× larger at home than away.
  - Poisson dispersion ≈ 0.99, so plain Poisson looks adequate.
- **Injured:** the LM gives 3 fitted "probabilities" below 0, and its residuals fall in two bands. The logistic GLM stays within (0, 1).
- **Conclusion:** use GLMs for the main responses.

---

## Week 4 — Binomial regression — DONE (19/10/2026)

- **Yousuf, `04a`:** full model
  `injured ~ position + age + minutes_per_1000 + training_load + prev_injuries + bmi`.
  - prev_injuries OR 1.66 (1.39–1.99), age 1.11 (1.05–1.18), training_load 1.35 (1.08–1.69).
  - Minutes (p = 0.96), bmi (p = 0.58) and position (p = 0.51) show no evidence of association.
- **Liha, `04b`:**
  - **Final injury model: `injured ~ age + training_load + prev_injuries`.** Backward elimination by LRT and `step()` by AIC agree (AIC 554.2 → 547.3).
  - Dropped: minutes (p = 0.96), bmi (p = 0.58), position (p = 0.43 when dropped).
  - training_load and prev_injuries kept numeric; the factor versions don't improve the fit (p = 0.24 and p = 0.77).
  - ORs: prev_injuries 1.67 (95% CI 1.40–2.00), training_load 1.38 (1.11–1.71), age 1.11 (1.05–1.18) per year.
- **Vish, `04c`:** every extension rejected; final model kept with logit link.
  - age² p = 0.40; training_load × prev_injuries p = 0.12; position × training_load p = 0.77.
  - log(minutes) as exposure p = 0.52.
  - Probit and cloglog fit about as well as logit (AIC within 2); logit kept for odds ratios.
- **Liri, `04d`:**
  - Team-level grouped model: deviance 24.12 on 23 df (p = 0.40), Pearson dispersion 1.12. No clear extra-binomial variation between teams.
  - Team as a fixed effect: LRT p = 0.59, AIC 547.3 → 572.4. Not kept; revisit as a random effect in week 11.
  - Position-level grouped model is saturated, so it reproduces the raw rates exactly.
- **Zack, `04e`:**
  - `win ~ home_away + opponent_rank` (22/46 wins).
    - Away v home: OR 0.20 (95% CI 0.05–0.72), LRT p = 0.013.
    - Opponent rank: OR 1.09 per place (95% CI 1.00–1.21), LRT p = 0.059. Weak evidence; kept on AIC and context.
    - Grouped check (venue × rank band, 6 cells): observed and fitted win proportions agree, all |Pearson residual| < 0.8.
    - Caveats: small sample, paired by opponent, draws and losses combined.
  - Predicted win-probability plot with 95% bands.
  - Predicted injury-probability plot from Liha's final model.

### Workspace (Zack)
- 15/10: `run_all.R` added; misnamed files renamed; all outputs committed.
- 19/10: Yousuf's week 4 file renamed to `04a` and made to run (edit only, see decision-notes); `code/drafts/` restored so superseded code is kept in the workspace; decision notes written up for 04a–04c from the scripts; READMEs and this file updated; every model refitted to check the notes.

---

## Before week 5 starts: small checks for owners

- **Yousuf:** review the [Zack] interpretation section at the end of `04a` and the 04a entry in decision-notes; reword in your own words. Check the date on your week 4 who-did-what row (the file was uploaded 19/10).
- **Liha:** check the 04b entry in decision-notes (written up by Zack from your FINDING comment). Check the date on your week 4 row (your commits are 14–15/10).
- **Vish:**
  - check the 04c entry in decision-notes;
  - in `04c`, two comments to correct: "p = 0.4 > 0.005" should be 0.05, and the log(minutes) AIC is 548.8 vs 547.3, not "identical";
  - in `outputs/lm1_coefficients_annotated.csv`, each written interpretation sits one row above the term it describes, and "AIC is high hence model is not a good fit" needs removing (AIC has no absolute scale). Position effects there use DEF as baseline; restate against GK before they go in the report.

## Week 5 — Residuals and diagnostics (next)

- **Deadline:** submit the workspace link on QM+ by the end of week 5, shared with e.matechou@qmul.ac.uk. Lecturer check this week.
- Suggested tasks (one script each, `05a`–`05e`):
  - Diagnostics on the final injury model: deviance/Pearson residuals, leverage, Cook's distance. Deviance is not a goodness-of-fit test for 0/1 data, so use a grouped check (e.g. by deciles of fitted probability).
  - Influence of the 8–0 match on the Poisson goals model (`03b`): refit without it and compare.
  - Diagnostics on the Ashford win model (`04e`).
  - Diagnostics on the linear model for minutes (`02`): the 3960 ceiling.
  - Workspace: before the check, restart R and run `source("run_all.R")`.
- **Week 6:** Poisson for goals scored/conceded. Plain Poisson looks adequate after adjusting for home_away and opponent_rank.
- **Week 11:** team variation in injury rates; random team effect (no evidence of overdispersion at team level in week 4, but worth checking with a GLMM).

## Workspace rules

- Each person works only in their own script and commits under their own GitHub account.
- Never delete exploratory code. Superseded scripts go in `code/drafts/` and the change is noted in decision-notes.
- Log every decision, with its date, in `notes/decision-notes.md`. Add a row per task to `notes/who-did-what.md`.
- Before each lecturer check (weeks 5, 8, 11): restart R and run `source("run_all.R")` to check everything still works.
