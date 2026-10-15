# Decision notes

Every analytical decision: **what** we decided, **when**, **why**, and what
alternatives we considered. Newest weeks at the bottom.

---

## Week 2 — Exploration and normal linear regression

### 12/10/2026 — Variable classification

| Variable | Dataset | Type |
|---|---|---|
| team | Players | Nominal categorical (24 levels, grouping variable) |
| position | Players | Nominal categorical (GK, DEF, MID, FWD); GK is the baseline |
| age | Players | Continuous (recorded in whole years) |
| minutes_played | Players | Continuous, capped at 3960 |
| training_load | Players | Ordinal (1–5) |
| prev_injuries | Players | Count (0–4) |
| bmi | Players | Continuous |
| injured | Players | Binary |
| home_away | Matches | Binary categorical; Home is the baseline |
| goals_scored | Matches | Count |
| goals_conceded | Matches | Count |
| opponent_rank | Matches | Ordinal (1–24), treated as numeric |

Derived in `00_load_data.R`: `goal_diff = goals_scored − goals_conceded`, and
`result` (L < D < W, ordered).

### Players dataset findings (Yousuf)
- 620 players, 24 clubs, no missing values.
- Overall injury rate 18.5%. By position, GK has the highest rate (27%).
- Injury rate rises with previous injuries: 11% (0), 19% (1), 28% (2), 39% (3), 43% (4).
- Injury rate is higher at training load 4–5 (~26%) than at 1–3 (11–16%).
- Injury rate varies by team, from 8% (Moorfield, Penwick) to 44% (Grantwick).
- 16 players sit at the 3960-minute ceiling, 12 of them goalkeepers.
- Explanatory variables are close to uncorrelated (largest |r| = 0.21, training_load vs minutes_played).

### Ashford matches findings (Liha)
- Home record W15 D5 L3. Away record W7 D6 L10.
- Mean goals scored: 1.74 at home vs 0.87 away. Mean conceded: 0.57 at home vs 1.09 away.
- Goals scored rise against weaker opponents (r = +0.34 with opponent rank). Goals conceded fall (r = −0.38).
- Every opponent appears twice (home and away), so the data are paired by opponent.

### 12/10/2026 — The 8–0 match
**Decision:** keep the 8–0 home win v the rank-24 side.
**Why:** there is no evidence it is a data error. Removing it would be a judgement
we can't justify.
**Note:** it is the only reason goals_scored looks overdispersed. With it, the
variance is 2.0 against a mean of 1.30. Without it, the variance is 1.0 against a
mean of 1.16. Influence to be checked in week 5.

### Linear model for minutes_played (Vish)
**Model:** `minutes_played ~ position + age + training_load + bmi + prev_injuries` (R² = 0.28).
- Position dominates. Compared with GK: DEF −580, MID −900, FWD −1200 minutes.
- Each extra training-load level is associated with ~145 more minutes.
- Age, bmi and prev_injuries are not significant (p > 0.5) and are candidates to drop.

**Decision:** treat `training_load` as numeric.
**Why:** the factor version is not a significant improvement (F = 0.43 on 3 df, p = 0.73).
**Alternative considered:** factor with 5 levels (3 extra parameters).

**Limitation:** the ceiling at 3960 minutes (mostly goalkeepers) shows in the
residual plots. A normal linear model doesn't respect an upper limit.

---

## Week 3 — Responses vs explanatory variables

### Roles of variables (Liri)

| Variable | Role |
|---|---|
| injured | Response (binary) |
| goals_scored, goals_conceded | Responses (counts) |
| result | Response (ordinal, derived) |
| minutes_played | Response in week 2. Otherwise an explanatory/exposure variable for injury |
| position, age, training_load, bmi | Explanatory |
| prev_injuries | Explanatory: a count, but a natural predictor of `injured` rather than a response |
| home_away, opponent_rank | Explanatory (matches) |
| team | Grouping variable, not a standard predictor (23 dummy variables) |

### Planned model for each response (Liri)

| Response | Outcome type | Model | Link | Coefficients mean | Week |
|---|---|---|---|---|---|
| injured | Binary | Binomial GLM | logit | log-odds / odds ratios | 4 |
| goals_scored, goals_conceded | Count | Poisson GLM | log | log-rate / rate ratios | 6 |
| result (W/D/L) | Ordinal | Ordinal (proportional odds) model | logit | cumulative log-odds | 10 |
| injured, players within teams | Binary, grouped | Binomial GLMM, random team effect | logit | conditional log-odds | 11 |

### 12/10/2026 — Why GLMs rather than linear models (Zack)
- **Goals:**
  - The LM gives no negative fitted values, but predicts only ~0.08 goals for an
    away game v the top side (Poisson GLM: ~0.43), and its prediction intervals go
    below zero.
  - Residual variance is ~3× larger at home than away, which breaks the
    constant-variance assumption.
  - The Poisson GLM respects that goals are non-negative counts whose variance
    rises with the mean.
  - Pearson dispersion ≈ 0.99 with home_away and opponent_rank in the model, so
    plain Poisson looks adequate.
- **Injured:** the LM gives 3 fitted "probabilities" below 0, and its residuals
  fall in two bands, so they cannot be normal. The logistic GLM keeps every
  fitted probability in (0, 1).

**Decision:** use GLMs (binomial for binary, Poisson for counts) for the main
responses from week 4 onwards.

---

## Week 4 — Binomial regression

### 12/10/2026 — Plan
**Primary binary response:** `injured` (players data).
**Secondary binary response:** `win = (result == "W")` (Ashford matches, 22/46 wins).
**Link:** logit by default, so coefficients are odds ratios. Probit and cloglog
to be compared in `04c`.
**Main model fitted by:** Yousuf (`04a`).

**Starting model:**
`injured ~ position + age + minutes_played + training_load + prev_injuries + bmi`

### Decisions to record this week (fill in as completed)
- [ ] Final injury model: terms kept and dropped, with test results (`04b`, Liha)
- [ ] training_load numeric vs factor in the logistic model (`04b`, Liha)
- [ ] prev_injuries numeric vs factor (`04b`, Liha)
- [ ] Extensions kept or rejected: age², interactions, log(minutes), link function (`04c`, Vish)
- [ ] Team effect: likelihood ratio test result, and note for week 11 GLMM (`04d`, Liri)
- [x] Ashford win model results and small-sample caveat (`04e`, Zack)

(Add reasoning here.)

### 15/10/2026 — Ashford win model (Zack, `04e`)
**Model:** `win ~ home_away + opponent_rank`, binomial GLM with logit link, where
`win = (result == "W")`. A binomial GLM suits a 0/1 response because it keeps
fitted probabilities in (0, 1); the logit link gives odds ratios.

| Term | Odds ratio | 95% CI | LRT (1 df) | p |
|---|---|---|---|---|
| Away (vs Home) | 0.20 | 0.05 to 0.72 | 6.15 | 0.013 |
| Opponent rank (+1 place) | 1.09 | 1.00 to 1.21 | 3.58 | 0.059 |

CIs are profile-likelihood intervals on the log-odds scale, exponentiated.

- Holding opponent rank fixed, playing away is associated with the odds of an
  Ashford win being multiplied by about 0.20 (95% CI 0.05 to 0.72). The LRT
  rejects removing home_away at the 5% level (p = 0.013), so we keep it.
- Holding venue fixed, each place lower the opponent finished is associated with
  the odds of winning being multiplied by about 1.09 (95% CI 1.00 to 1.21).
  The LRT gives p = 0.059, so there is only weak evidence for this term at the
  5% level. Across the whole table (rank 1 to 24) that is an odds ratio of
  about 1.09^23 ≈ 7.6.
- **Decision:** keep both terms for now. opponent_rank is borderline on the LRT,
  but AIC prefers keeping it (60.4 with it vs 62.0 without), it is the obvious
  measure of opposition strength, and it is clearly associated with goals
  scored and conceded (week 2). Alternative considered: home_away only.

**Caveats:**
- Only 46 matches and 22 wins, so the intervals are wide.
- The data are paired: each opponent is played twice, home and away. The
  model treats the 46 matches as independent, which ignores this.
- `win` collapses draws and losses together. The ordinal model (week 10) uses
  the full W/D/L outcome.
- Ashford's own rank is absent from opponent_rank (they finished 9th, so no
  opponent has rank 9).

**Goodness of fit:** the response is 0/1, so residual deviance (54.4 on 43 df) is
not a goodness-of-fit test. Instead, matches were grouped by venue and opponent
rank band (1–8, 9–16, 17–24; the middle band is effectively 10–16). Observed and
fitted win proportions agree closely in all six cells. Every Pearson residual
is within ±0.8 and none exceeds 2. Pearson X² = 1.19 over the six cells. With
only 7–8 matches per cell this is descriptive, not a formal test.
Table: `outputs/win_grouped_check.csv`.

**Outputs:** `win_odds_ratios.csv`, `win_drop1_lrt.csv`, `win_grouped_check.csv`,
`win_predicted_probabilities.csv`, `win_prob_by_rank.png`.

### 15/10/2026 — Predicted injury probability plot (Zack, `04e`)
- Uses Liha's final injury model from `04b`: `injured ~ age + training_load + prev_injuries`.
- Predicted probability plotted against prev_injuries (0–4) for each training
  load (1–5), at the median age (25).
- Example: a 25-year-old with no previous injuries on load 1 has a predicted
  injury probability of 0.06 (95% CI 0.03 to 0.10). With 4 previous injuries on
  load 5 it is 0.62 (95% CI 0.46 to 0.76).
- Only 21 players have 4 previous injuries, so the right-hand end of the plot is
  the least certain.
- 95% bands were computed on the log-odds scale with `predict(se.fit = TRUE)` and
  transformed with `plogis()`, so they stay within (0, 1).

**Outputs:** `injury_predicted_probabilities.csv`, `injury_prob_by_prev_injuries.png`.

### 15/10/2026 — Workspace: run_all.R (Zack)
Added `run_all.R`. It runs every numbered script in `code/` in order, each in
its own environment, and reports any that fail. Un-numbered drafts in `code/`
are kept but skipped. Use it from a fresh R session before
each lecturer check.

### 15/10/2026 — Workspace tidy-up: renamed files (Zack)
**What:** files whose names didn't follow the agreed naming were renamed. No
file was deleted and no file's content was changed except where noted.

| Old name | New name | Why |
|---|---|---|
| `code/Normal linear regression (week 2&3).R` | `code/drafts/02_linear_model_draft.R` | Spaces and brackets in the name; it is a draft of `02_linear_model.R` |
| `outputs/Plot of lm1 (mins played = pos + age + training+ bmi + prev_injuries).png` | `outputs/lm1_residuals_vs_fitted.png` | Spaces and symbols in the name; it is the lm1 residuals vs fitted plot |
| `outputs/drop1_results.csv` | `outputs/lm1_drop1_results.csv` | Name didn't say which model; matches the other `lm1_*` outputs |

**Why `code/drafts/`:** the brief says to keep all code, including discarded
attempts. A separate folder keeps the drafts without `run_all.R` trying to run
them. The draft's commented-out `write.csv` lines still mention the old output
name; they were left as written.

**Small fixes to make every script run:**
- `04b_injury_model_selection.R`: deleted line 72, which contained the text
  "Add Person 2 injury model selection" (a commit message pasted into the
  script). It caused a syntax error. No R code was changed.
- `03a_variable_roles.R`: header comment corrected from `03_variable_roles.R`
  to the file's actual name.

**Test file:** `code/test2.R` contained only a comment (`#hi zack`) and no
analysis code, so it was deleted rather than kept.

**Alternatives considered:** moving Vish's draft into `02_linear_model.R` (left for
Vish, since it is his work and needs edits to run).

**Outputs committed:** after the fixes, every numbered script was run from a
fresh session and the 25 outputs that existed only locally were committed, so
`outputs/` now matches `outputs/README.md`.

### 15/10/2026 — `02_linear_model.R`: Vish's work moved into place (edit by Zack)
**This is an edit, not new analysis. The model, the tests, the comments and
the conclusions are all Vish's.**

**What:** Vish's week 2 analysis was in his own file (now
`code/drafts/02_linear_model_draft.R`), while `02_linear_model.R` was still the
starter template. His code was copied into `02_linear_model.R` with only these
changes, so it runs from the project folder:
- added `source("code/00_load_data.R")` and used `players` instead of
  `league_players`;
- removed `setwd()` with a personal OneDrive path;
- un-commented his two `write.csv` lines, saving the drop1 table as
  `lm1_drop1_results.csv`;
- added a note that the scripts use GK as the baseline position (his comment
  says defender), and a TODO for the empty bmi section. Both are marked [Zack].

**Kept, not deleted:** his original file (unchanged) and the old starter, both
in `code/drafts/`. His hand-edited coefficient table, which includes his written
interpretation of every term, was renamed `lm1_coefficients_annotated.csv` so
the script's plain table (`lm1_coefficients.csv`, the name in the week 2
instructions) doesn't overwrite it.

**Why:** the brief requires everything to run from the folder as submitted, and
the week 4 email asked for these TODOs to be finished.

**Note for the report:** his annotated table uses defenders as the baseline;
the scripts use goalkeepers. The fitted model is the same and the numbers agree
once the baseline is accounted for (GK +580 vs DEF matches DEF −580 vs GK).

### 15/10/2026 — `code/drafts/` removed (Zack)
**What:** deleted the `code/drafts/` folder and its two files:
- `02_linear_model_draft.R`: Vish's original week 2 file. All of its analysis
  is in `02_linear_model.R` (see the entry above).
- `02_linear_model_starter.R`: the original starter template for
  `02_linear_model.R`, superseded by Vish's work.

**Why:** keep `code/` to one script per task. Both files were fully superseded,
and keeping a duplicate of Vish's code next to the working version risked the
two drifting apart.

**Kept:** the brief asks for all code, including discarded attempts, to be kept.
Both files are preserved unchanged in the git history at commit `6fc4269`:
https://github.com/zack-higham/mth6134-group-project/tree/6fc4269/code/drafts

**Alternative considered:** keeping them in `code/drafts/` (the previous
arrangement).

