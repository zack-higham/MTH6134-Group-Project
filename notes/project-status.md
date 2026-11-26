# MTH6134 Group Project — Final Submission Plan and Status

*Last updated: 26/11/2026 (week 10). From now on we work towards the final
submission, not the weekly lab topics. Deadline: **23:59, Wed 6 January 2027**
(QM+). Lecturer workspace check: **week 11**.*

## 0. Where we are (26/11)

- **Done since 23/11:** `09a` ordinal model (Zack), `11b` opponent GLMM
  (Zack), `09d` paired goals (Liri, 23/11). All 27 numbered scripts run from a
  fresh session with `source("run_all.R")` (checked 26/11, R 4.3.3).
- **Still open for the 26/11 analysis deadline:** `06a` and `09b` (Liha, no
  commits since 26/10), `11a` (Liri).
- **Output mismatches found on 26/11** (details in decision-notes, 26/11):
  `05c`'s committed `win_influence_comparison.csv` is out of date (Vish);
  `05d_grouped` standardised residuals differ under R 4.3.3, Grantwick 3.15 v
  3.54 committed (Liri).

## 1. What we submit (from the group project brief)

| Item | Who | Spec |
|---|---|---|
| Group report (PDF) | All | ≤ 4 pages of narrative; executive summary ≤ ½ page stating the three main findings; for each analysis: data explored, model and why, results with CIs, brief diagnostic check; short conclusions with limitations. Then an R code appendix (not counted) that reproduces every result and figure, plus the workspace link |
| Group Contribution Summary | All (Zack drafts) | 1 page, a short, specific entry per member covering analyses, modelling, writing, code and coordination. Distilled from who-did-what and decision-notes. Sets each member's contribution factor (default 1; levels 0.75 / 0.5 / 0.25 / 0) |
| Individual report | Each member, **independently** | (1) 500-word analysis using `shots_on_target` and/or `possession` from `ashford_matches_individual.csv`, plus one figure or table and a code appendix; (2) 100-word reflection on week 7 feedback (received and given); (3) 100-word reflection on AI use |
| Workspace | Zack (owner) | Repo as is: all code incl. drafts, outputs, decision-notes, who-did-what; runs with `source("run_all.R")` |

**Weighting:** 60% of the module. Group report 40 points (× contribution
factor), individual report 20 points.
**Group report marks:** interpretation 30, model choice/selection/fit 20,
presentation and code 20 (reproducibility counts here), choice of questions 15,
exploratory analysis 15.
**Individual report marks:** analysis 50, feedback reflection 25, AI reflection 25.

## 2. The three questions (proposed 23/11; group to confirm and log in decision-notes)

Selection logic (worth putting in the report's intro, since choice of questions
is 15 marks): each question is relevant to the client (Ashford United), has
several candidate predictors so model selection matters, and uses a different
model family. Together they cover binomial GLM → GLMM, Poisson GLM → GLMM, and
ordinal / contingency-table / matched-pairs models.

### Q1. Which player characteristics are associated with injury risk, and does risk vary between clubs beyond them?
*League-wide, 620 players. Response: `injured` (binary).*

| Part | Evidence | Status |
|---|---|---|
| Exploration | `01a`: 18.5% injured; rate rises 11% → 43% with prev injuries; load 4–5 ~26% v 11–16% | Done |
| Model and selection | `04a` full model; `04b` final `injured ~ age + training_load + prev_injuries` (LRT and AIC agree, AIC 554.2 → 547.3); `04c` extensions rejected (age², interactions, log minutes, other links) | Done |
| Results | ORs: prev_injuries 1.67 (1.40–2.00), training_load 1.38 (1.11–1.71), age 1.11 (1.05–1.18) per year; position and minutes not associated (`08a`: no position effect once prev injuries allowed for) | Done |
| Fit and diagnostics | `05b` grouped GoF (1/23 cells \|r\| > 2); `05a` player residuals, Cook's ≤ 0.025, binned residual plot (2/24 bins outside ±2 SE, no pattern); `06d`/`08d` table models agree with numeric terms | Done |
| Club variation | `04d` fixed team effect not needed (LRT p = 0.59); `05d_grouped` Grantwick the only team outside ±2 (std residual 3.54 committed, 3.15 when re-run on R 4.3.3; Liri to confirm which) | Done (value to confirm) |
| **GLMM** | `11a`: `lme4::glmer(injured ~ age + training_load + prev_injuries + (1 | team))`; random-effect variance, LRT v the GLM (boundary: halve the p-value), whether ORs change, Grantwick's predicted effect. **Note from 11b:** compare log-likelihoods on the same scale (use Laplace, `nAGQ = 1`, or check; `lme4`'s AGQ logLik isn't comparable with `glm()` for Poisson) | **To do — Liri** |

### Q2. Is Ashford's home advantage driven by scoring more, conceding less, or both — and how does it depend on opponent strength?
*Ashford's 46 matches. Responses: `goals_scored` and `goals_conceded` (counts).*

| Part | Evidence | Status |
|---|---|---|
| Exploration | `01b`: scored 1.74 home v 0.87 away; conceded 0.57 v 1.09; 8–0 the only source of apparent overdispersion | Done |
| Why Poisson | `03b`: LM predicts negative goals; Poisson dispersion ≈ 0.99 | Done |
| Goals scored | `05e`/`06b`: away RR 0.50 (0.29–0.84), rank RR 1.056 (1.017–1.098) per place; no interaction (p = 0.55); linear rank preferred (AIC 133.4 v 136.1); 8–0 Cook's 0.64, without it away 0.59 (p = 0.058) — sensitivity analysis | Done |
| **Goals conceded** | `06a`: same workflow as 05e/06b (selection, dispersion, RRs with CIs, diagnostics) | **To do — Liha (overdue since week 6)** |
| Within-opponent check | `09d`: paired away/home RR 0.500 (0.287–0.844), LRT p = 0.009; without the 8–0 pair 0.531 (0.289–0.944), p = 0.031; Bradley–Terry not used (decision logged) | Done (Liri, 23/11) |
| GLMM | `11b`: random opponent effect, variance 0.108, boundary LRT v GLM p = 0.14 (not needed); away RR 0.500 (0.287–0.844) as in 06b and 09d; rank RR 1.052 (1.006–1.099); variance 0 without the 8–0. Keep the 06b GLM; mention in one sentence | Done (Zack, 26/11) |

### Q3. How do venue and opponent strength shift Ashford's chances of winning, drawing and losing?
*Response: `result` (ordered L < D < W).*

| Part | Evidence | Status |
|---|---|---|
| Exploration / tables | `06e`: home W15 D5 L3, away W7 D6 L10; X² = 6.77 on 2 df, p = 0.034; holds given rank band (p = 0.019) | Done |
| Binary benchmark | `04e`/`05c`: win ~ venue + rank, away OR 0.205 (0.050–0.723); influence checked | Done. `05c` code uses profile CIs since 22/11, but the committed `win_influence_comparison.csv` is still the old Wald version — **Vish to re-run and commit** |
| Ordinal model | `09a`: `polr(result ~ home_away + opponent_rank)`; away OR (better result) 0.190 (0.052–0.625), rank OR 1.125 (1.030–1.240) per place; no interaction (p = 0.60); PO holds (v multinom p = 0.42; cumulative logits parallel); grouped fit X² 4.65, ~8 df; 8–0 not influential; v rank 12, P(W) 0.64 home v 0.26 away. Figure 3 and Table 3 saved | Done (Zack, 26/11) |
| Matched pairs | `09c`: conditional logistic, opponent as stratum: away OR 0.27 (0.08–0.98), LRT p = 0.027 | Done (Vish, 22/11) |
| **Matched pairs** | `09b`: McNemar (won home v won away); 3 × 3 home × away result table (symmetry, quasi-symmetry, marginal homogeneity) | **To do — Liha** |

### Considered but not chosen (keep in workspace; mention briefly or not at all)
- **Minutes played** (`02`, `05d_minutes`): R² = 0.28, dominated by position; the
  3960 ceiling needs a censored model. Less useful to the club than Q1–Q3 and it
  would need a fourth model family. **`10b` (Tobit) dropped** unless someone
  wants it for an individual report; log in decision-notes.
- `03a` (variable roles) and `03b` (LM v GLM) feed the methods paragraphs.

**Alternative if the group prefers fewer Ashford questions:** merge Q2 and Q3
into one "Ashford home advantage" question and use minutes played (censored
model) as Q3. Weaker: minutes is mainly a position story and leaves the
richest Ashford material compressed into one page.

## 3. Report plan (group report, 4 pages)

Write in **R Markdown** (`reports/group_report.Rmd`), so the appendix is the code
itself and the numbers in the text come from the scripts. Formal language, "we",
no raw R output, no causal language, numbered figures and tables.

| Section | Length | Content | Lead writer (proposed) |
|---|---|---|---|
| Executive summary | ≤ ½ page | Three findings, one sentence of uncertainty each | Zack |
| Introduction and data | ¼ page | Client, the two datasets, why these three questions | Zack |
| Q1 Injury risk | ~1 page | Fig 1: fitted injury probability v prev injuries by training load (with CI bands). Table 1: ORs (GLM v GLMM) | Yousuf (with Liri for 11a) |
| Q2 Goals | ~1 page | Fig 2: predicted goals scored and conceded v opponent rank, home and away. Table 2: RRs with CIs, incl. without the 8–0, within-opponent (09d) and GLMM (11b) | Zack (with Liha 06a, Liri 09d) |
| Q3 Results | ~1 page | Fig 3: fitted P(L), P(D), P(W) v opponent rank, home and away (`result_ordinal_fitted_probs.png`). Table 3: away v home OR across 06e / 04e / 09a / 09c (`result_away_or_comparison.csv`, add 09b) | Vish (with Zack 09a, Liha 09b) |
| Conclusions and limitations | ¼ page | Simulated data; Ashford n = 46 and the 8–0; associations not causes; injury predictors limited to those recorded | Zack |
| Appendix | not counted | All code, workspace link | Zack |

Each question section must show: why this model for this response; model
selection with the criterion and conclusion; a goodness-of-fit check suited to
the family; diagnostics with comment; interpretation in context with CIs.

## 4. Timeline

| By | What | Status (26/11) |
|---|---|---|
| **Thu 26/11** | Remaining analyses committed: `09a` (Zack), `06a` + `09b` (Liha), `09d` (Liri), `11a` (Liri), `11b` (Zack, optional). Everyone checks their own who-did-what rows | 09a, 09d, 11b done; 06a, 09b, 11a open |
| **Week 11 check** | All analysis committed and noted; the three questions logged in decision-notes; `run_all.R` passes from a fresh session | `run_all.R` passes (27 scripts) |
| **Week 12** | Group meeting: confirm questions and writers; final figures/tables saved to `outputs/report_*`; `group_report.Rmd` skeleton knitting | |
| **Fri 18/12** | Full draft of the group report; draft Contribution Summary circulated for every member to check their own entry | |
| **Christmas break** | Individual reports (independently); everyone reads the full draft once | |
| **Sat 2/1** | Final edits; page count checked in the PDF; repo re-run from a fresh clone | |
| **Mon 4/1** | Submit (two days' buffer before 6/1) | |

## 5. Risks and open actions

- **Liha: no commits since 26/10.** Both `06a` and `09b` feed the final report,
  and the 26/11 date has now passed. Reassign (`06a` → Zack, `09b` → Vish),
  log it in decision-notes, and **tell the lecturer before or at the week 11
  check**. The brief says to raise problems early, and the Contribution
  Summary must reflect what actually happened. Also: fix the date on her
  week 4 row; check her 05b row.
- **Liri:** `11a` (injury GLMM); confirm the Grantwick standardised residual
  (3.54 v 3.15) and the R version; optional rename of
  `05d_grouped_diagnostics.R` → `05f`.
- **Vish:** re-run `05c` and commit `win_influence_comparison.csv`; check his
  22/11 who-did-what row (added by Zack); add a 09c decision-notes entry.
- **Yousuf:** review the [Zack] section of `04a` and the 04a entry; fix the
  week 4 row date (17/10 → 19/10).
- **Zack:** confirm QM+ workspace link; Contribution Summary draft by 18/12;
  take `06a` if reassigned. README `lme4` note done 26/11.
- **Group:** confirm the three questions and log them; confirm dropping `10b`.

## 6. Individual reports (each member's own work)

Must be written independently, so the group shouldn't co-write or share these.
Practical points only:
- Get `ashford_matches_individual.csv` from QM+. It is **not** part of the group
  workspace; keep it and your code out of the shared repo.
- The task: use `shots_on_target` and/or `possession` to extend a group analysis,
  fit a model the group didn't, or answer a new question. Fit, check, interpret,
  compare with the group's work, and discuss pros and cons of the new variables.
  One figure or table; 500 words.
- Feedback reflection: the week 7 individual report feedback, received and given.
- AI reflection: what AI was used for, where it was wrong and how you noticed,
  and what judgement it couldn't supply. Keep your own notes as you go.

## 7. Workspace

- Repo: `zack-higham/mth6134-group-project`. Structure: `code/` (numbered
  scripts, `drafts/`), `data/`, `outputs/`, `notes/` (decision-notes,
  who-did-what, project-status), `reports/`. Lowercase, case-sensitive paths.
- Every script starts with `source("code/00_load_data.R")` (`players`,
  `matches`, `result` ordered L < D < W). Base R plus tidyverse (`01b`, `04b`),
  `MASS`, `nnet`, `survival`, and `lme4` (`11a`, `11b`; install once).
- Scripts in the repo as of 26/11 (27 numbered): `00`–`08d` plus `05a`, `08a`,
  `09a`, `09c`, `09d`, `11b`. Old `Week4 and Week5.R` is in `code/drafts/`.
- Rules unchanged: own scripts only, commit under your own account, never delete
  code, log decisions with dates, add a who-did-what row for every task.
  Restart R and `source("run_all.R")` before the week 11 check and before submission.

---

## 8. Weekly history (summaries to 19/11/2026)

The week-by-week summaries below are kept as a record. The week 9 task list and
"remaining work" table that followed them were replaced by the plan above on
23/11 (see git history for the earlier version).

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
