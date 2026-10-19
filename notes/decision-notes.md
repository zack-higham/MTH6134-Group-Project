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
- Injuries is not included as a predictor because an injury directly causes a drop in minutes played, distorting the data. 

**Decision:** treat `training_load` as numeric.
**Why:** the factor version is not a significant improvement (F = 0.43 on 3 df, p = 0.73).

**Alternative considered:** BMI as the response variable, factor with 5 levels (3 extra parameters).
-There are 0 statistically significant variables when considering BMI as the response variable, p value > 0.05. 
-Logically, injuries are a consequence of physical status hence it would be a circular model. Therefore minutes played should be the response variable, BMI is better as an explanatory variable. 

**Limitation:** the ceiling at 3960 minutes (mostly goalkeepers) shows in the
residual plots. A normal linear model doesn't respect an upper limit.

---

## Week 3 — Responses vs explanatory variables

### Roles of variables (Liri)

The distribution listed for a response determines the proposed model family.
Predictors do not have to follow the response distribution; their entries below
describe their observed data type and likely empirical distribution.

| Variable | Role | Type | Likely distribution |
|---|---|---|---|
| team | Grouping variable | Nominal categorical (24 clubs) | Multinomial categorical |
| position | Explanatory | Nominal categorical (GK, DEF, MID, FWD) | Multinomial categorical |
| age | Explanatory | Continuous, recorded in whole years | Empirical continuous |
| minutes_played | Response in week 2; otherwise explanatory/exposure for injury | Bounded continuous | Ceiling-affected at 3960 |
| training_load | Explanatory | Ordinal (1–5) | Ordered discrete |
| prev_injuries | Explanatory for `injured` | Count (0–4) | Right-skewed count |
| bmi | Explanatory | Continuous | Empirical continuous |
| injured | Response | Binary (0/1) | Bernoulli; binomial when aggregated |
| home_away | Explanatory (matches) | Binary categorical | Binary categorical |
| goals_scored | Response | Count | Poisson candidate |
| goals_conceded | Response | Count | Poisson candidate |
| opponent_rank | Explanatory (matches) | Ordinal (1–24), treated as numeric | Ordered discrete |
| result | Response (derived) | Ordered categorical (L < D < W) | Ordinal categorical |

### Planned model for each response (Liri)

| Response | Outcome type | Model | Link | Coefficients mean | Week |
|---|---|---|---|---|---|
| injured | Binary | Binomial GLM | logit | log-odds / odds ratios | 4 |
| goals_scored, goals_conceded | Count | Poisson GLM | log | log-rate / rate ratios | 6 |
| result (W/D/L) | Ordinal | Ordinal (proportional odds) model | logit | cumulative log-odds | 10 |
| injured, players within teams | Binary, grouped | Binomial GLMM, random team effect | logit | conditional log-odds | 11 |

**Injury.** `injured` is a binary outcome, so a binomial GLM with a logit link
keeps fitted probabilities between zero and one. A coefficient is the change in
log-odds for a one-unit predictor increase (or relative to a reference category),
and its exponential is an odds ratio. Candidate predictors are position, age,
minutes played, training load, previous injuries and BMI because they represent
player role, exposure, workload, injury history and physiology.

**Goals scored and conceded.** These are non-negative counts, so Poisson GLMs
with log links are the starting models. A coefficient is a change in the log
expected goal count and its exponential is a rate ratio. `home_away` represents
venue and `opponent_rank` represents opposition strength. Dispersion must be
checked because a variance much larger than the mean would make the plain
Poisson model unsuitable.

**Match result.** `result` has a natural order (loss < draw < win) without equal
spacing, so an ordinal proportional-odds model is more suitable than treating it
as continuous. With a logit link, coefficients describe cumulative log-odds and
exponentiated coefficients are cumulative odds ratios, subject to the
proportional-odds assumption. Venue and opponent rank are the planned predictors
for the same reasons as in the goal models.

**Players grouped within teams.** Players at the same club may share training,
medical and selection environments, so their injury outcomes may be correlated.
A binomial GLMM with a random intercept for team can represent this clustering
without estimating 23 separate fixed team coefficients. Fixed-effect
coefficients are conditional log-odds, holding the team effect constant; their
exponentials are conditional odds ratios.

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
- [x] Final injury model: terms kept: (age, training_load & prev_injuries) and dropped, with test results (`04b`, Liha)
- [x] training_load numeric (chosen) vs factor in the logistic model (`04b`, Liha)
- [x] prev_injuries numeric (chosen) vs factor (`04b`, Liha)
- [x] Extensions rejected all of the following: age², interactions, log(minutes), link function (`04c`, Vish)
- [x] Team effect: likelihood ratio test result, and note for week 11 GLMM (`04d`, Liri)
- [x] Ashford win model results and small-sample caveat (`04e`, Zack)

The reasoning for each decision is in the dated entries below.

### 19/10/2026 — Full logistic model for injury (Yousuf, `04a`)
*Recorded by Zack (19/10/2026) from Yousuf's script; the model is Yousuf's.
Yousuf to check and reword.*

**Model:** `injured ~ position + age + minutes_per_1000 + training_load +
prev_injuries + bmi`, binomial GLM with logit link, GK baseline. Minutes were
rescaled to units of 1,000 so the odds ratio is readable.
**Why this model:** `injured` is binary, so a binomial GLM keeps fitted
probabilities in (0, 1) and the logit link gives odds ratios (week 3 decision).
All six candidate predictors from the week 3 roles table are included as the
starting point for model selection in `04b`.

| Term | Odds ratio | 95% CI | LRT p (given the other terms) |
|---|---|---|---|
| prev_injuries (per injury) | 1.66 | 1.39 to 1.99 | < 0.001 |
| age (per year) | 1.11 | 1.05 to 1.18 | < 0.001 |
| training_load (per level) | 1.35 | 1.08 to 1.69 | 0.008 |
| minutes (per 1,000) | 1.01 | 0.70 to 1.45 | 0.96 |
| bmi (per unit) | 0.96 | 0.83 to 1.11 | 0.58 |
| position (DEF / MID / FWD vs GK) | 0.56 / 0.65 / 0.59 | all CIs include 1 | 0.51 (3 df) |

- Holding the other terms fixed, previous injuries, age and training load are
  associated with higher odds of injury. Minutes, bmi and position show no
  evidence of association.
- Goalkeepers have the highest raw injury rate (27%), but the position effect
  disappears once the other variables are accounted for.
- Yousuf compared two term orders with `anova()`. Sequential tests depend on the
  order (position p = 0.25 entered first, 0.51 entered last), so the table uses
  `drop1()` tests, which don't.
- His low/medium/high training-load groups come out as 1–3, 4 and 5, because
  most players are on loads 2–4; injury rates 14%, 26%, 26%.

**Output:** `injury_full_odds_ratios.csv`.

### 14/10/2026 — Model selection and final injury model (Liha, `04b`)
*Recorded by Zack (19/10/2026) from the FINDING comment in Liha's script.
Liha to check.*

**Decision:** the final injury model is
`injured ~ age + training_load + prev_injuries`.
**How:** starting from Yousuf's full model, backward elimination by likelihood
ratio test (drop the term with the largest p, stop when every p < 0.05). `step()`
by AIC selects the same model.

| Dropped (in order) | LRT p when dropped |
|---|---|
| minutes | 0.96 |
| bmi | 0.58 |
| position (3 df) | 0.43 |

- AIC falls from 554.2 (full model) to 547.3 (final model).
- **training_load kept numeric:** the 5-level factor version is no
  improvement (LRT p = 0.24).
- **prev_injuries kept numeric:** the factor version is no improvement
  (LRT p = 0.77).
- **Interpretation:** holding the other terms fixed, each extra previous injury
  is associated with the odds of injury being multiplied by 1.67 (95% CI 1.40
  to 2.00); each extra training-load level by 1.38 (1.11 to 1.71); each extra
  year of age by 1.11 (1.05 to 1.18).
- **Position:** goalkeepers have the highest raw rate (27%), but with only 62
  goalkeepers the data can't distinguish a real position effect from chance.

**Alternatives considered:** keeping position for context; factor versions of
training_load and prev_injuries.
**Output:** `injury_drop1_full.csv`, `injury_final_odds_ratios.csv`.

### 18/10/2026 — Extensions to the final injury model (Vish, `04c`)
*Recorded by Zack (19/10/2026) from Vish's script comments. Vish to check.*

**Decision:** keep Liha's final model unchanged, with the logit link. Every
extension was tested against it with a likelihood ratio test (or AIC for the
link functions) and rejected.

| Extension | Test | Result |
|---|---|---|
| age² (non-linear age) | LRT | p = 0.40 |
| training_load × prev_injuries | LRT | p = 0.12 |
| position × training_load | LRT | p = 0.77 |
| log(minutes_played + 1) as exposure | LRT, AIC | p = 0.52; AIC 548.8 vs 547.3 |
| Probit link | AIC | 549.0 vs 547.3 (logit) |
| Cloglog link | AIC | 546.1 vs 547.3 (logit) |

- No evidence of curvature in age or of either interaction.
- Minutes played, even on the log scale, adds nothing once age, training load
  and previous injuries are in the model.
- The three links fit almost equally well (AIC differences under 2) and give
  nearly identical fitted probabilities (`link_functions_comparisons.png`).
  Logit is kept because its coefficients are odds ratios.
- **Note:** `position * training_load` also adds position as a main effect, so
  that test covers both. The interaction alone, given position, gives p = 0.91;
  the conclusion is the same.

**Output:** `injury_extensions_comparison.csv`, `link_functions_comparisons.png`.

### 16/10/2026 — Grouped binomial models and team effect (Liri, `04d`)

**Team-level grouped model.** Injury counts and squad sizes were aggregated for
the 24 teams and fitted as `cbind(injured, n - injured) ~ 1`. Raw injury rates
ranged from 8.3% (Moorfield and Penwick) to 44.4% (Grantwick), compared with the
overall fitted rate of 18.5%. Despite that range, the grouped model gives
residual deviance 24.12 on 23 df (ratio 1.05, p = 0.397) and Pearson dispersion
1.12. There is therefore no clear evidence of extra-binomial variation at team
level in these data.

**Fixed team effect.** Team was added to Person 2's final individual model,
`injured ~ age + training_load + prev_injuries`. Adding 23 team coefficients
reduced deviance by 20.88 on 23 df (likelihood-ratio p = 0.588) and increased AIC
from 547.27 to 572.39. **Decision:** do not keep team as a fixed effect because
it adds many parameters without improving fit. A random team intercept remains
a more parsimonious way to revisit possible clustering in the week 11 GLMM.
With only about 24–28 players per team, absence of evidence here should not be
treated as proof that clubs have identical underlying injury risks.

**Position-level grouped model.** A grouped binomial model with position as the
predictor exactly reproduced the raw injury proportions: DEF 15.7%, FWD 18.4%,
GK 27.4%, and MID 18.9% (differences only at numerical rounding precision).
This occurs because fitting one probability for each of four groups makes this
four-cell model saturated; it is a check that grouped successes/failures were
constructed correctly, not evidence that every position difference is real.

**Outputs:** `injury_team_grouped.csv`, `injury_team_grouped_gof.csv`,
`injury_team_lrt.csv`, and `injury_position_grouped.csv`.

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
file's content was changed except where noted. The only deletion was the
comment-only test file below. *(Correction, 19/10/2026: this entry originally
said no file was deleted.)*

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

*Reversed on 19/10/2026: see below.*

### 19/10/2026 — `code/drafts/` restored (Zack)
**What:** restored `code/drafts/02_linear_model_draft.R` (Vish's original week 2
file) and `code/drafts/02_linear_model_starter.R` (the old starter), unchanged,
from commit `6fc4269`.
**Why:** the brief and our workspace rules say to keep all code, including
superseded attempts, in the workspace itself. Git history alone isn't enough,
because the workspace is checked as a folder. `run_all.R` only runs numbered
files directly in `code/`, so the drafts are kept without being run.
**Alternative considered:** leaving them only in git history (the 15/10
decision above).

### 19/10/2026 — Yousuf's week 4 script renamed and made to run (edit by Zack)
**This is an edit, not new analysis. The model and code are Yousuf's.**

**What:** Yousuf uploaded his week 4 model as `code/Statistical Modelling
week4.R` (commit `8144dbc`). It was renamed to `code/04a_injury_logistic.R` in a
commit of its own, so the history shows it is the same file. A second commit
then:
- added `source("code/00_load_data.R")` (the original read from an object
  `league_players` that is never created, so it stopped at line 5);
- replaced `league_players` with `players`, the loader's name;
- added a section marked [Zack] at the end with `drop1()` tests and a written
  interpretation of each term, which the week 4 task asked for. Yousuf to
  review and reword.

All changes are listed in the script's header. His original version is
unchanged in the git history at `8144dbc`.
**Why:** the script didn't run and wasn't picked up by `run_all.R`, which only
runs files starting with a number.
**Alternative considered:** keeping both files side by side; not done, because
the renamed file contains all of Yousuf's code unchanged.

### 19/10/2026 — Week 4 workspace check (Zack)
- All 12 numbered scripts run cleanly from a fresh session with
  `source("run_all.R")`, and their outputs match the committed files.
- Every model was refitted independently and the numbers in these notes were
  checked against it.
- Notes, READMEs and project status updated to cover weeks 2–4.

