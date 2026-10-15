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
2. Restart R, then run `source("run_all.R")`. It runs every script in `code/` in numerical order and lists any that fail.
3. Or run scripts one at a time in numerical order. Every script starts with `source("code/00_load_data.R")`.

All code is base R, except `01b_explore_matches.R` and `04b_injury_model_selection.R`, which load the tidyverse (`install.packages("tidyverse")` once before running them).

`run_all.R` only runs the numbered scripts. Other files in `code/` (rough drafts) are kept but not run.

## Scripts
| Script | Week | Purpose |
|---|---|---|
| `00_load_data.R` | — | Reads both datasets, sets factors, adds derived variables |
| `01_explore.R` | 2 | Original combined exploration (kept; superseded by 01a/01b) |
| `01a_explore_players.R` | 2 | Players dataset exploration |
| `01b_explore_matches.R` | 2 | Ashford matches exploration (tidyverse) |
| `02_linear_model.R` | 2 | Normal linear regression |
| `03a_variable_roles.R` | 3 | Responses vs explanatory variables |
| `03b_lm_vs_glm.R` | 3 | Why linear models fail for counts/binary; first GLMs |
| `04a_injury_logistic.R` | 4 | Full logistic model for injury, odds ratios |
| `04b_injury_model_selection.R` | 4 | Model selection, final injury model |
| `04c_injury_extensions.R` | 4 | age², interactions, exposure, link functions |
| `04d_grouped_binomial.R` | 4 | Grouped binomial, goodness of fit, team effect |
| `04e_ashford_wins_and_predictions.R` | 4 | Ashford win model, predicted-probability plots |
| `run_all.R` (project root) | — | Runs all scripts in order and reports failures |
| `Normal linear regression (week 2&3).R` | 2 | Rough draft of `02` (kept; not run by `run_all.R`) |
| `test2.R` | — | Test file (kept; not run by `run_all.R`) |

## Weekly progress
- [x] Week 2 — Exploration + normal linear regression
- [x] Week 3 — Responses vs explanatory variables
- [ ] Week 4 — Binomial regression
- [ ] Week 5 — Residuals and diagnostics (workspace link due end of week 5)
- [ ] Week 6 — Poisson regression
- [ ] Week 8 — Contingency tables I
- [ ] Week 9 — Contingency tables II
- [ ] Week 10 — Specialised models
- [ ] Week 11 — GLMMs
- [ ] Week 12 — Choose three analyses and plan the report
