# MTH6134 Group Project — Progress and Status

*Last updated: 05/11/2026 (before week 8 and the second lecturer check)*

## Where we are (summary)

- **Done:** weeks 2–4 in full; week 5 diagnostics for three models (05b, 05c,
  05e); the Poisson model for goals scored (in 05e); a first contingency-table
  analysis (06e, venue × result), ahead of week 8.
- **Open from weeks 5–6:** 05a (injury model residuals), 05d (minutes ceiling),
  Poisson model for goals conceded. No owners yet.
- **Workspace:** every numbered script runs from a fresh session except `05c`,
  which needs the data-loader line added (Vish). `01b` and `04b` need the
  tidyverse installed.
- **Activity since 19/10:** Zack (05e, 06e, upkeep), Vish (05c, week 4 fixes),
  Liha (05b). No commits from Yousuf since 19/10 or from Liri since 16/10.
- **Lecturer check in week 8.** Confirm the workspace link was submitted on QM+
  and is shared with e.matechou@qmul.ac.uk.

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
run_all.R    runs every numbered script in code/ in order (clean global environment each time) and reports failures
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

16 numbered scripts. All run from a fresh session with `source("run_all.R")`
except `05c` (checked 05/11/2026).

| Script | Week | Owner | Status |
|---|---|---|---|
| `00_load_data.R` | — | Zack | Done |
| `01_explore.R` | 2 | Zack | Kept (original combined exploration, split into 01a/01b) |
| `01a_explore_players.R` | 2 | Yousuf | Done |
| `01b_explore_matches.R` | 2 | Liha | Done |
| `02_linear_model.R` | 2 | Vish | Done (GK baseline and annotated table from code, 29/10; drop1 file name to fix) |
| `03a_variable_roles.R` | 3 | Liri | Done |
| `03b_lm_vs_glm.R` | 3 | Zack | Done |
| `04a_injury_logistic.R` | 4 | Yousuf | Done (Yousuf still to review the [Zack] interpretation section) |
| `04b_injury_model_selection.R` | 4 | Liha | Done |
| `04c_injury_extensions.R` | 4 | Vish | Done (comments corrected 29/10) |
| `04d_grouped_binomial.R` | 4 | Liri | Done |
| `04e_ashford_wins_and_predictions.R` | 4 | Zack | Done |
| `05a` (injury model residuals) | 5 | — | **Not started** |
| `05b_injury_grouped_gof.R` | 5 | Liha | Done |
| `05c_win_diagnostics.R` | 5 | Vish | Done, but **fails on its own**: needs `source("code/00_load_data.R")` |
| `05d` (minutes ceiling) | 5 | — | **Not started** |
| `05e_goals_influence.R` | 5 | Zack | Done |
| `06e_venue_result_table.R` | 6 | Zack | Done (contingency tables, ahead of week 8) |
| `run_all.R` | — | Zack | Done (now clears the global environment before each script, 05/11) |

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

## Week 5 — Residuals and diagnostics — MOSTLY DONE (26/10/2026)

- **Liha, `05b`:** grouped goodness of fit for the final injury model
  (training_load × prev_injuries, 23 cells).
  - 1 of 23 cells has |residual| > 2 (load 1, 0 previous injuries: 3 observed v
    0.68 expected), and it is a tiny cell. No clear evidence of lack of fit.
  - Age-band grouped refit: deviance 74.3 on 72 df (p = 0.40), Pearson 70.3 on
    72 df (p = 0.54), but every cell is small, so low power.
  - Final injury model kept unchanged.
- **Vish, `05c`:** diagnostics for the Ashford win model.
  - All Cook's distances < 0.1. Largest: match 27 (2–1 away win v rank 6).
  - Without match 27: away OR 0.205 → 0.157; rank OR 1.092 → 1.113, CI no
    longer includes 1 (LRT p 0.059 → 0.029, Zack's check).
  - The 8–0 has leverage 0.077 but Cook's distance 0.006: it counts as one win.
- **Zack, `05e`:** Poisson model for goals scored and the 8–0.
  - All 46: away RR 0.50 (0.29–0.84), p = 0.009; rank RR 1.056 per place
    (1.017–1.098), p = 0.004. Deviance 49.8 on 43 df, dispersion 0.99.
  - The 8–0: Cook's distance 0.64 (next largest 0.08), leverage 0.162.
  - Without it: away 0.59 (0.33–1.02), p = 0.058; rank 1.034 (0.993–1.078),
    p = 0.10. No other single match changes the conclusions.
  - **Decision:** keep the 8–0; report the without-8–0 fit as a sensitivity
    analysis. Quasipoisson / negative binomial not needed.
- **Not done:** `05a` (player-level residuals, leverage and Cook's distance for
  the final injury model), `05d` (linear model for minutes: the 3960 ceiling).

## Week 6 — PARTLY DONE

- Poisson for goals scored: done in `05e`.
- **Zack, `06e`:** venue × result contingency table.
  - X² = 6.77 on 2 df, p = 0.034. Away v home: win rather than loss OR 0.14
    (0.02–0.62); draw rather than loss OR 0.36 (0.06–2.01).
  - Three-way table with rank band: no three-way term (p = 0.83); venue and
    result not conditionally independent given rank band (p = 0.019). Final
    model rank*venue + venue*result (deviance 9.45 on 8 df); collapsible over
    rank band.
- **Not done:** Poisson model for goals conceded.

---

## Before the week 8 check

**Owners (small fixes):**
- **Vish:**
  - add `source("code/00_load_data.R")` at the top of `05c` (it fails on its own);
  - in `02`, change line 52 back to `outputs/lm1_drop1_results.csv`, and fix the
    comment that still says defender is the baseline;
  - check the 05c and 29/10 entries in decision-notes and your rows in
    who-did-what (written up by Zack from your commits).
- **Liha:** check your 05b row in who-did-what; fix the date on your week 4 row
  (says 16/10, your commits are 14–15/10).
- **Yousuf:** review the [Zack] interpretation section at the end of `04a` and
  the 04a decision-notes entry; fix the date on your week 4 row (says 17/10,
  file uploaded 19/10).
- **Liri:** nothing outstanding from earlier weeks; pick up a week 5/6 or week 8
  task below.
- **Everyone:** add your own row to who-did-what when you finish something.
  It is compared against the individual contribution statements.

**Workspace (Zack):** confirm the QM+ link; restart R and run
`source("run_all.R")` after Vish's fix.

## Remaining work for the rest of term

Suggested owners only; agree them at the week 8 session.

| Week | Task | Script | Suggested owner |
|---|---|---|---|
| 5 (catch-up) | Injury model residuals, leverage, Cook's distance; binned residual plot | `05a` | Yousuf |
| 5 (catch-up) | Linear model for minutes: the 3960 ceiling in the residuals | `05d` | Liri |
| 6 (catch-up) | Poisson model for goals conceded (home_away, opponent_rank, dispersion, diagnostics) | `06a` | Liha |
| 8 | Position × injury table: chi-squared, log-linear model, odds ratios | `08a` | Liri |
| 8 | Training load × injury and prev_injuries × injury tables (ordered categories) | `08b` | Yousuf |
| 9 | Three-way tables, e.g. position × training load × injury; conditional independence and collapsibility | `09a` | Vish |
| 9 | Contingency-tables II follow-ups from the lecture | `09b` | Liha |
| 10 | Ordinal (proportional-odds) model for result (L < D < W) ~ home_away + opponent_rank; compare with 06e and 04e | `10a` | Zack |
| 10 | Any other outcome needing a specialised model (e.g. the minutes ceiling) | `10b` | Vish |
| 11 | Injury GLMM with a random team effect; compare with the week 4 fixed-effect test | `11a` | Liri |
| 11 | Goals GLMM with a random opponent effect (each opponent played twice) | `11b` | Zack |
| 12 | Choose the three analyses; plan the report and split the writing | — | All |
| Brief | Group report (PDF), individual reports in `reports/` | — | All |

**Notes on the plan:**
- Week 10 and 11 models need packages beyond base R (e.g. `MASS::polr` for the
  ordinal model, `lme4::glmer` for GLMMs). Note them in the README when added.
- The lecturer checks again in week 11, so weeks 8–10 work should be committed
  and noted by then.
- Strongest candidates for the final three analyses so far:
  1. **Injury risk:** binomial GLM (04a–04e, 05a, 05b), then a GLMM (11a).
  2. **Ashford goals:** Poisson GLM with the 8–0 sensitivity analysis (05e),
     goals conceded (06a), opponent GLMM (11b).
  3. **Ashford results:** venue × result table (06e) and/or the ordinal model
     (10a), or a player contingency-table analysis (08a/08b).
- The full project brief overrides this plan when it is released.

## Workspace rules

- Each person works only in their own script and commits under their own GitHub account.
- Never delete exploratory code. Superseded scripts go in `code/drafts/` and the change is noted in decision-notes.
- Log every decision, with its date, in `notes/decision-notes.md`. Add a row per task to `notes/who-did-what.md`.
- Before each lecturer check (weeks 5, 8, 11): restart R and run `source("run_all.R")` to check everything still works.
