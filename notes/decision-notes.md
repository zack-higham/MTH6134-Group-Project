# Decision notes

Record every analytical decision: **what** we decided, **when**, and **why**,
including the alternatives we considered.

---

## 2026-10-09 — Week 2: variable classification

| Variable | Dataset | Type |
|---|---|---|
| team | Players | Nominal categorical (24 levels, grouping variable) |
| position | Players | Nominal categorical (GK, DEF, MID, FWD) |
| age | Players | Continuous (recorded as whole years) |
| minutes_played | Players | Continuous, capped at 3960 |
| training_load | Players | Ordinal (1-5) |
| prev_injuries | Players | Count |
| bmi | Players | Continuous |
| injured | Players | Binary |
| home_away | Matches | Binary categorical |
| goals_scored | Matches | Count |
| goals_conceded | Matches | Count |
| opponent_rank | Matches | Ordinal (1-24), treated as numeric |

**Decision:** treat `training_load` as numeric for now (one slope).
**Alternative:** treat it as a factor (4 extra parameters). To be compared later.

## 2026-10-09 — Week 2: unusual observation

The 8-0 home win against the rank-24 side is a potential outlier/influential point.
**Decision:** keep it for now; check its influence in the week 5 diagnostics.

## Week 3: candidate responses

| Response | Outcome type | Model | Week |
|---|---|---|---|
| injured | Binary | Binomial (logistic) GLM | 4 |
| goals_scored / goals_conceded | Count | Poisson GLM | 6 |
| result (W/D/L, derived) | Ordinal | Ordinal model | 10 |
| minutes_played | Continuous | Normal linear model | 2 |
| Players within teams | Grouped | GLMM | 11 |

(Add reasoning here.)
