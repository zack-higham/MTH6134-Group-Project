# MTH6134 Group Project — Progress and Status

*Last updated: 15/10/2026 (tidy-up)*

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
data/        league_players.csv, ashford_matches.csv
outputs/     plots (.png) and tables (.csv) saved by the scripts
notes/       decision-notes.md, who-did-what.md
reports/     final group + individual reports (later)
```

- All code uses base R and relative paths, except `01b` and `04b`, which load the tidyverse. Open the `.Rproj` before running anything.
- `00_load_data.R` reads both CSVs. It sets `position` (GK baseline) and `home_away` (Home baseline) as factors, and adds `training_load_f` (ordered factor), `goal_diff`, and `result` (ordered L < D < W).

## Scripts

| Script | Week | Owner | Status |
|---|---|---|---|
| `00_load_data.R` | — | Zack | Done |
| `01_explore.R` | 2 | Zack | Kept (original combined exploration, split into 01a/01b) |
| `01a_explore_players.R` | 2 | Yousuf | Done |
| `01b_explore_matches.R` | 2 | Liha | Done |
| `02_linear_model.R` | 2 | Vish | Done except the bmi response (moved into place by Zack, 15/10) |
| `03a_variable_roles.R` | 3 | Liri | Done |
| `03b_lm_vs_glm.R` | 3 | Zack | Done |
| `04a_injury_logistic.R` | 4 | Yousuf | In progress |
| `04b_injury_model_selection.R` | 4 | Liha | Done (decision-notes and who-did-what entries still to add) |
| `04c_injury_extensions.R` | 4 | Vish | In progress |
| `04d_grouped_binomial.R` | 4 | Liri | In progress |
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

### Zack: workspace
- Repo setup, README, folder structure, and collaborators added.
- `outputs/` and `reports/` rebuilt after an upload flattened the folders.

---

## Week 4 — Binomial regression (IN PROGRESS)

- **Yousuf, `04a`:** full logistic model,
  `injured ~ position + age + minutes_played + training_load + prev_injuries + bmi`.
  Odds ratios with 95% CIs, and interpretation of each term.
- **Liha, `04b` — DONE 14/10/2026:**
  - **Final injury model: `injured ~ age + training_load + prev_injuries`.** Backward elimination by LRT and `step()` by AIC agree.
  - Dropped: minutes (p = 0.96), bmi (p = 0.58), position (p = 0.43 when dropped).
  - training_load and prev_injuries kept numeric; the factor versions don't improve the fit (p = 0.24 and p = 0.77).
  - ORs: prev_injuries 1.67 (95% CI 1.40–2.00), training_load 1.38 (1.11–1.71), age 1.11 (1.05–1.18) per year.
- **Vish, `04c`:** extensions.
  - age².
  - Interactions: `training_load:prev_injuries` and `position:training_load`.
  - `log(minutes_played)` as exposure.
  - Probit and cloglog links vs logit.
- **Liri, `04d`:** grouped binomial.
  - Team-level `cbind(injured, n - injured)` model and an overdispersion check.
  - Likelihood ratio test for team as a fixed effect.
  - Position-level grouped model.
  - Note for the week 11 GLMM.
- **Zack, `04e` — DONE 15/10/2026:**
  - `win ~ home_away + opponent_rank` (22/46 wins).
    - Away v home: OR 0.20 (95% CI 0.05–0.72), LRT p = 0.013.
    - Opponent rank: OR 1.09 per place (95% CI 1.00–1.21), LRT p = 0.059. Weak evidence; kept on AIC and context.
    - Grouped check (venue × rank band, 6 cells): observed and fitted win proportions agree, all |Pearson residual| < 0.8.
    - Caveats: small sample, paired by opponent, draws and losses combined.
  - Predicted win-probability plot with 95% bands.
  - Predicted injury-probability plot from Liha's final model.
  - Workspace: `run_all.R` added; README updated (weeks 2–3 ticked, tidyverse note, all scripts listed); `outputs/README.md` now lists every output by script.
  - Tidy-up: misnamed files renamed (see decision-notes, 15/10/2026); all numbered scripts run cleanly from a fresh session; all script outputs committed.

---

## Carry forward

- **Week 5:**
  - Influence of the 8–0 match.
  - Diagnostics on the final injury model.
  - Deviance is not a goodness-of-fit test for 0/1 data.
  - Vish: his week 2 work has been moved into `02_linear_model.R` (edit by Zack, still Vish's analysis). The bmi response section is still empty. His interpretations in `outputs/lm1_coefficients_annotated.csv` use defenders as the baseline, while the scripts use GK, so the position effects need restating against GK before they go in the report.
  - Liha: add decision-notes and who-did-what entries for `04b`.
- **Week 6:** Poisson for goals scored/conceded. Plain Poisson looks adequate after adjusting for home_away and opponent_rank.
- **Week 11:** variation in injury rates between teams suggests a random team effect.

## Workspace rules

- Each person works only in their own script and commits under their own GitHub account.
- Never delete exploratory code. Superseded scripts are kept and the change is noted in decision-notes.
- Log every decision, with its date, in `notes/decision-notes.md`. Add a row per task to `notes/who-did-what.md`.
- Before each lecturer check (weeks 5, 8, 11): restart R and run `source("run_all.R")` to check everything still works.
