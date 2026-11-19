# MTH6134 Group Project — Progress and Status

*Last updated: 19/11/2026 (week 9; next lecturer check in week 11)*

## Where we are (summary)

- **Done:** weeks 2–4 in full; week 5 diagnostics for every model except the
  player-level injury diagnostics (`05a`, written by Yousuf but not yet
  running); Poisson model and model selection for goals scored (`05e`, `06b`);
  contingency tables for venue × result (`06e`), previous injuries × training
  load × injury (`06d`) and age × previous injuries × injury (`08d`).
- **Open:** `05a` and `08a` (Yousuf's 09/11 script, needs fixing and
  splitting); Poisson model for goals conceded (`06a`, overdue from week 6);
  week 9 ordinal and matched-pairs models (owners below).
- **Workspace:** all 21 numbered scripts run from a fresh session with
  `source("run_all.R")` (checked 19/11). `01b` and `04b` need the tidyverse.
  `code/Week4 and Week5.R` doesn't run and isn't picked up by `run_all.R`.
- **Activity since 05/11:** Zack (06b, 08d, upkeep), Vish (05d minutes,
  02/05c fixes), Liri (05d grouped diagnostics, 06d), Yousuf (09/11 script).
  **No commits from Liha since 26/10.**
- **Lecturer check in week 11.** Weeks 8–10 work should be committed and
  noted before then. **Deadline: 23:59, 6 January 2027.**

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
- `00_load_data.R` reads both CSVs into **`players`** and **`matches`** (not `league_players`). It sets `position` (GK baseline) and `home_away` (Home baseline) as factors, and adds `training_load_f` (ordered factor), `goal_diff`, and `result` (ordered L < D < W).
- **Naming:** `NN` + a letter per task + a short description, e.g. `05a_injury_diagnostics.R`. The number at the start matters: `run_all.R` only runs files whose names start with a digit.
- Week 9 models need packages beyond base R: `MASS` (polr, comes with R), `nnet` (multinom, comes with R), `survival` (clogit, comes with R). Note any others in the README.

## Scripts

21 numbered scripts, all running from a fresh session (checked 19/11/2026).

| Script | Week | Owner | Status |
|---|---|---|---|
| `00_load_data.R` | — | Zack | Done |
| `01_explore.R` | 2 | Zack | Kept (original combined exploration, split into 01a/01b) |
| `01a_explore_players.R` | 2 | Yousuf | Done |
| `01b_explore_matches.R` | 2 | Liha | Done |
| `02_linear_model.R` | 2 | Vish | Done (fixes from the week 5–6 check done 07/11) |
| `03a_variable_roles.R` | 3 | Liri | Done |
| `03b_lm_vs_glm.R` | 3 | Zack | Done |
| `04a_injury_logistic.R` | 4 | Yousuf | Done (Yousuf still to review the [Zack] interpretation section) |
| `04b_injury_model_selection.R` | 4 | Liha | Done |
| `04c_injury_extensions.R` | 4 | Vish | Done |
| `04d_grouped_binomial.R` | 4 | Liri | Done |
| `04e_ashford_wins_and_predictions.R` | 4 | Zack | Done |
| `05a` (injury model residuals) | 5 | Yousuf | **Written, doesn't run** (in `code/Week4 and Week5.R`) |
| `05b_injury_grouped_gof.R` | 5 | Liha | Done |
| `05c_win_diagnostics.R` | 5 | Vish | Done; runs on its own now. **Output not re-run** after the 08/11 CI change |
| `05d_grouped_diagnostics.R` | 5 | Liri | Done (grouped binomial diagnostics) |
| `05d_minutes_diagnostics.R` | 5 | Vish | Done (minutes ceiling) |
| `05e_goals_influence.R` | 5 | Zack | Done |
| `06a` (goals conceded) | 6 | Liha | **Not started** |
| `06b_goals_scored_selection.R` | 6 | Zack | Done |
| `06d_injury_loglinear.R` | 6 | Liri | Done (prev injuries × training load × injury) |
| `06e_venue_result_table.R` | 6 | Zack | Done |
| `08a` (position × injury) | 8 | Yousuf | **Written, doesn't run** (in `code/Week4 and Week5.R`) |
| `08d_age_prev_injury_table.R` | 8 | Zack | Done |
| `run_all.R` | — | Zack | Done |

Two scripts start with `05d`; both run. Liri may rename hers (e.g. `05f`) and
note it in decision-notes.

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
- **Kept in the data.** Its influence was checked in week 5 (`05e`).
- Every opponent is played twice (home and away), so the data are paired
  (23 opponents; Ashford finished 9th).

### Vish: linear regression (`02`)
- `minutes_played ~ position + age + training_load + bmi + prev_injuries`, R² = 0.28.
- Position dominates. Compared with GK: DEF −580, MID −900, FWD −1200 minutes.
- Training load: +145 minutes per level.
- Age, bmi and prev_injuries are not significant (p > 0.5).
- training_load kept numeric. The factor version is no better (F = 0.43 on 3 df, p = 0.73).
- bmi as a response (added 16/10): no predictor is significant, so bmi is kept as an explanatory variable.
- Limitation: the 3960-minute ceiling shows up in the residuals (see `05d_minutes_diagnostics`).

### Liri: variable roles (`03a`)

| Response | Type | Planned model | Week |
|---|---|---|---|
| injured | Binary | Binomial GLM, logit link (odds ratios) | 4 |
| goals_scored / goals_conceded | Count | Poisson GLM, log link (rate ratios) | 6 |
| result (W/D/L) | Ordinal | Ordinal / proportional-odds model | 9–10 |
| injured, players within teams | Grouped binary | Binomial GLMM, random team effect | 11 |

- prev_injuries is treated as a predictor of injury, not as a response.
- team is a grouping variable, not 23 dummy variables.

### Zack: linear model vs GLM (`03b`)
- **Goals:** the LM predicts 0.08 goals away v the top side (Poisson GLM: 0.43), and its prediction intervals go below 0. Residual variance is ~3× larger at home than away. Poisson dispersion ≈ 0.99.
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
  - ORs: prev_injuries 1.67 (95% CI 1.40–2.00), training_load 1.38 (1.11–1.71), age 1.11 (1.05–1.18) per year.
- **Vish, `04c`:** every extension rejected (age², interactions, log(minutes), probit/cloglog); final model kept with logit link.
- **Liri, `04d`:** team-level grouped model deviance 24.12 on 23 df (p = 0.40), dispersion 1.12; team as a fixed effect not kept (LRT p = 0.59); revisit as a random effect in week 11.
- **Zack, `04e`:** `win ~ home_away + opponent_rank` (22/46 wins). Away v home OR 0.20 (0.05–0.72), LRT p = 0.013; opponent rank OR 1.09 per place (1.00–1.21), LRT p = 0.059. Predicted win and injury probability plots.

---

## Week 5 — Residuals and diagnostics — MOSTLY DONE

- **Liha, `05b`:** grouped goodness of fit for the final injury model; 1 of 23 cells has |residual| > 2 (tiny cell). Final injury model kept.
- **Vish, `05c`:** win model diagnostics. All Cook's distances < 0.1; without match 27 the rank CI no longer includes 1. The 8–0 counts as one win (Cook's 0.006).
- **Liri, `05d_grouped_diagnostics`:** Grantwick is the only team outside ±2 (std residual 3.54); kept, and supports the week 11 GLMM. Position × training-load cells: no residual outside ±2; without the most influential cell, training_load OR 1.40 → 1.33. All cells kept.
- **Vish, `05d_minutes_diagnostics`:** S-shaped Q-Q plot from the 3960 ceiling (censoring). Without the 16 ceiling players, position effects shrink by ~130–150 minutes; training_load unchanged. All players kept; censored-data model is a week 10 follow-up.
- **Zack, `05e`:** Poisson goals scored. Away RR 0.50 (0.29–0.84), rank RR 1.056 (1.017–1.098). The 8–0 has Cook's distance 0.64; without it away 0.59 (p = 0.058), rank 1.034 (p = 0.10). Kept, with the without-8–0 fit as a sensitivity analysis.
- **Yousuf, `05a` (in `code/Week4 and Week5.R`):** 26 players with |std residual| > 2, all injured with fitted probability 4–13%; largest Cook's distances ≈ 0.025; without the top 5, ORs strengthen slightly, conclusions unchanged. **Needs to run and be committed.**

## Week 6 — MOSTLY DONE

- **Zack, `06b`:** goals scored model selection. No interaction (p = 0.55); linear rank preferred to log rank (AIC 133.4 v 136.1); both terms kept (p = 0.009, 0.004). Same model without the 8–0, though linear v log rank then nearly tied.
- **Liri, `06d`:** prev-injury band × training-load band × injury. No three-way term (p = 0.27); injury associated with both, each adjusted for the other. ORs: 1 v 0 previous 2.00 (1.17–3.41), 2+ v 0 3.91 (2.37–6.51), load 4–5 v 1–3 2.07 (1.36–3.15). Matches a banded 04b.
- **Zack, `06e`:** venue × result. X² = 6.77 on 2 df, p = 0.034; away v home win-rather-than-loss OR 0.14 (0.02–0.62). Holds given rank band (p = 0.019).
- **Not done:** Poisson model for goals conceded (`06a`).

## Week 8 — Contingency tables I — MOSTLY DONE

- **Zack, `08d`:** age band × prev band × injury. Log-linear model identical to the grouped logistic; no three-way term (p = 0.99); age (p = 0.002) and prev band (p < 0.001) both kept. Supports 04b's numeric terms.
- **Yousuf, `08a` (in `code/Week4 and Week5.R`):** position × injury X² = 4.38 on 3 df, p = 0.22; no position effect once previous injuries are allowed for. **Needs to run and be committed.**
- `08b` (training load × injury, prev injuries × injury) is covered by `06d` and `08d`; not needed separately.

---

## Week 9 — Ordinal and matched-pairs models (from the week 9 lecture)

Aim to commit by **Thu 26/11** so there is time to fix things before the
week 11 check. Each person works in their own script and adds their own row to
who-did-what and their own entry to decision-notes.

**Zack — `09a_result_ordinal.R`:** proportional-odds model for result
(L < D < W) ~ home_away + opponent_rank with `MASS::polr`.
- LRT for each term; ORs with 95% CIs, interpreted the right way round
  (`polr` uses logit P(Y ≤ j) = ζj − η, so check the sign);
- check the proportional-odds assumption: cumulative-logit differences
  (slides 11–13) and LRT against `nnet::multinom`;
- table of fitted P(L), P(D), P(W) at home and away for ranks 1, 12, 24;
- compare with the win model (04e) and the venue × result table (06e).
- Plus: workspace upkeep, confirm the QM+ link for week 11.

**Liha — `09b_matched_pairs_results.R`, and `06a_goals_conceded.R` (overdue):**
- pair each opponent's home and away match (23 pairs);
- McNemar's test: won at home v won away (slides 17–20);
- the 3 × 3 home-result × away-result square table: symmetry,
  quasi-symmetry and marginal homogeneity (slide 25 and the practical);
- `06a`: Poisson model for goals conceded ~ home_away + opponent_rank, with
  model selection, dispersion, rate ratios with CIs and diagnostics (as
  05e/06b for goals scored);
- check your 05b row in who-did-what; fix the date on your week 4 row.

**Vish — `09c_win_conditional_logistic.R`:**
- conditional logistic regression for win with opponent as the stratum,
  `survival::clogit(win ~ home_away + strata(opponent_rank))` (slides 21–24);
- interpret the within-opponent OR for away v home and compare with 04e
  (OR 0.20, which adjusts for rank as a number instead) and with Liha's
  McNemar result (only the discordant pairs carry information);
- re-run `05c` and commit `win_influence_comparison.csv` (still has the old
  Wald CIs); check your 05c, 05d and 07–08/11 entries.

**Liri — `09d_goals_paired.R` and the Bradley–Terry decision:**
- goals scored within opponent pairs: home v away rate ratio conditional on
  the opponent, e.g. Poisson with opponent as a factor, or equivalently
  binomial for home goals out of each pair's total; compare with the
  venue RR in 05e/06b (0.50) and with the 8–0 removed;
- write the decision note on Bradley–Terry (why it does or doesn't apply
  here: only Ashford's fixtures, draws, home advantage = order effect);
- optional: rename `05d_grouped_diagnostics.R` (e.g. `05f`) so the two 05d
  scripts don't clash; note it in decision-notes.

**Yousuf — get `05a` and `08a` running:**
- split `code/Week4 and Week5.R` into `05a_injury_diagnostics.R` and
  `08a_position_injury_table.R`; use `players` (from `00_load_data.R`), not
  `league_players`; create `injury_counts` before the grouped model; run each
  from a fresh session and commit the outputs; move the original to
  `code/drafts/`;
- in `05a`, add a binned residual plot (average residual within bins of
  fitted probability), which is a better check than individual residuals for
  a binary response;
- check the 05a/08a decision-notes entry and your rows in who-did-what;
- still open: review the [Zack] section at the end of `04a` and the 04a entry;
  fix the date on your week 4 row (17/10 → 19/10).

**Everyone:** add your own row to who-did-what when you finish something. It
is the evidence used for the contribution factor.

## Remaining work for the rest of term

| Week | Task | Script | Suggested owner |
|---|---|---|---|
| 10 | Censored model for minutes (the 3960 ceiling), e.g. Tobit with `survival::survreg` | `10b` | Vish |
| 10 | Any other outcome needing a specialised model | `10c` | Open |
| 11 | Injury GLMM with a random team effect (Grantwick); compare with the week 4 fixed-effect test | `11a` | Liri |
| 11 | Goals GLMM with a random opponent effect (each opponent played twice); compare with 09d | `11b` | Zack |
| 11 | Lecturer check: everything committed and noted | — | All |
| 12 | Choose the three questions; plan the report and split the writing | — | All |
| Brief | Group report (4 pages + code appendix + workspace link), Group Contribution Summary, individual reports | — | All |

**Notes on the plan:**
- GLMMs need `lme4::glmer`. Note it in the README when added.
- Strongest candidates for the three questions:
  1. **Injury risk:** binomial GLM (04a–04e, 05a, 05b, 05d), table models
     (06d, 08d), then a GLMM (11a).
  2. **Ashford goals:** Poisson GLM with model selection and the 8–0
     sensitivity analysis (05e, 06b), goals conceded (06a), within-opponent
     comparison (09d), opponent GLMM (11b).
  3. **Ashford results:** venue × result (06e), ordinal model (09a) and the
     matched-pairs analyses (09b, 09c).
- Marks (group report): interpretation 30, model choice/selection/fit 20,
  presentation and code 20, choice of questions 15, exploratory analysis 15.
  Each question needs a justified model, model selection, a fit/diagnostic
  check and CIs.
- Individual reports use `ashford_matches_individual.csv` (shots on target,
  possession); not part of the group workspace.

## Workspace rules

- Each person works only in their own script and commits under their own GitHub account.
- Never delete exploratory code. Superseded scripts go in `code/drafts/` and the change is noted in decision-notes.
- Log every decision, with its date, in `notes/decision-notes.md`. Add a row per task to `notes/who-did-what.md`.
- Before each lecturer check (weeks 5, 8, 11): restart R and run `source("run_all.R")` to check everything still works.
