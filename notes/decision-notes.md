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
- [ ] Ashford win model results and small-sample caveat (`04e`, Zack)

(Add reasoning here.)
