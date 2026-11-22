# MTH6134 Statistical Modelling II — Group Project

Analysis of the fictional Midland Premier League 2023/24 season.

## Group members
- Zack
- Vish
- Yousuf
- Liri
- Liha

## Folder structure
| Folder | Contents |
|---|---|
| `data/` | `league_players.csv` (620 players, 24 clubs) and `ashford_matches.csv` (46 Ashford United fixtures) |
| `code/` | All R code, including rough exploratory work. Scripts are numbered by week. |
| `outputs/` | Plots and tables produced along the way (kept even if unused); `outputs/README.md` lists every file and the script that makes it |
| `notes/` | `decision-notes.md` and `who-did-what.md` |
| `reports/` | Final group report and individual reports |

## How to run
1. Open `MTH6134-project.Rproj` in RStudio (this sets the working directory to the project folder).
2. Restart R, then run `source("run_all.R")`. It runs every script in `code/` in numerical order, clears the global environment before each one (so a script that forgets to load the data fails instead of borrowing the previous script's), and lists any that fail.
3. Or run scripts one at a time in numerical order. Every script starts with `source("code/00_load_data.R")`.

All code is base R, except `01b_explore_matches.R` and `04b_injury_model_selection.R`, which load the tidyverse (`install.packages("tidyverse")` once before running them). From week 9, scripts also use `MASS`, `nnet` and `survival`, which come with R.

`run_all.R` runs every numbered script directly in `code/`. Superseded drafts are kept in `code/drafts/` (Vish's original week 2 file and the old starter) and are not run.

## Scripts
| Script | Week | Purpose |
|---|---|---|
| `00_load_data.R` | — | Reads both datasets, sets factors, adds derived variables |
| `01_explore.R` | 2 | Original combined exploration (kept; superseded by 01a/01b) |
| `01a_explore_players.R` | 2 | Players dataset exploration |
| `01b_explore_matches.R` | 2 | Ashford matches exploration (tidyverse) |
| `02_linear_model.R` | 2 | Normal linear regression (Vish) |
| `03a_variable_roles.R` | 3 | Responses vs explanatory variables |
| `03b_lm_vs_glm.R` | 3 | Why linear models fail for counts/binary; first GLMs |
| `04a_injury_logistic.R` | 4 | Full logistic model for injury, odds ratios (Yousuf) |
| `04b_injury_model_selection.R` | 4 | Model selection, final injury model |
| `04c_injury_extensions.R` | 4 | age², interactions, exposure, link functions |
| `04d_grouped_binomial.R` | 4 | Grouped binomial, goodness of fit, team effect |
| `04e_ashford_wins_and_predictions.R` | 4 | Ashford win model, predicted-probability plots |
| `05a_injury_diagnostics.R` | 5 | Player-level diagnostics for the final injury model: residuals, leverage, Cook's distance, refit without the five most influential players, binned residual plot (Yousuf) |
| `05b_injury_grouped_gof.R` | 5 | Grouped goodness of fit for the final injury model (Liha) |
| `05c_win_diagnostics.R` | 5 | Residuals, leverage and Cook's distance for the Ashford win model (Vish) |
| `05d_grouped_diagnostics.R` | 5 | Residuals, leverage and influence for the grouped binomial models, by team and by position × training load (Liri) |
| `05d_minutes_diagnostics.R` | 5 | Minutes linear model: the 3960-minute ceiling, leverage, Cook's distance (Vish) |
| `05e_goals_influence.R` | 5 | Poisson goals model: diagnostics and influence of the 8–0 match |
| `06b_goals_scored_selection.R` | 6 | Poisson model selection for goals scored |
| `06d_injury_loglinear.R` | 6 | Previous injuries × training load × injury table and log-linear models (Liri) |
| `06e_venue_result_table.R` | 6 | Home/away × result contingency table and log-linear models |
| `08a_position_injury_table.R` | 8 | Position × injury table: chi-squared test, grouped logistic v log-linear, three-way table with previous-injury band, marginal v partial ORs (Yousuf) |
| `08d_age_prev_injury_table.R` | 8 | Age band × previous injuries × injury: log-linear v logistic |
| `drafts/` | 2 | Superseded drafts, kept but not run |
| `run_all.R` (project root) | — | Runs all scripts in order and reports failures |

## Weekly progress
- [x] Week 2 — Exploration + normal linear regression
- [x] Week 3 — Responses vs explanatory variables
- [x] Week 4 — Binomial regression
- [x] Week 5 — Residuals and diagnostics (05a, 05b, 05c, both 05d, 05e done)
- [ ] Week 6 — Poisson regression (goals scored done in 05e/06b; goals conceded still open). 06d and 06e contingency tables done
- [x] Week 8 — Contingency tables I (06d, 06e, 08a, 08d)
- [ ] Week 9 — Ordinal (proportional-odds) and matched-pairs models (09a–09d, owners in `notes/project-status.md`)
- [ ] Week 10 — Specialised models
- [ ] Week 11 — GLMMs
- [ ] Week 12 — Choose three analyses and plan the report
