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
| `outputs/` | Plots and tables produced along the way (kept even if unused) |
| `notes/` | `decision-notes.md` and `who-did-what.md` |
| `reports/` | Final group report and individual reports |

## How to run
1. Open `MTH6134-project.Rproj` in RStudio (this sets the working directory to the project folder).
2. Run scripts in `code/` in numerical order. Every script starts with `source("code/00_load_data.R")`.

## Scripts
| Script | Week | Purpose |
|---|---|---|
| `00_load_data.R` | — | Reads both datasets, sets factors, adds derived variables |
| `01a_explore_players.R` | 2 | Players dataset exploration |
| `01b_explore_matches.R` | 2 | Ashford matches exploration |
| `02_linear_model.R` | 2 | Normal linear regression |
| `03a_variable_roles.R` | 3 | Responses vs explanatory variables |
| `03b_lm_vs_glm.R` | 3 | Why linear models fail for counts/binary; first GLMs |

## Weekly progress
- [ ] Week 2 — Exploration + normal linear regression
- [ ] Week 3 — Responses vs explanatory variables
- [ ] Week 4 — Binomial regression
- [ ] Week 5 — Residuals and diagnostics (workspace link due end of week 5)
- [ ] Week 6 — Poisson regression
- [ ] Week 8 — Contingency tables I
- [ ] Week 9 — Contingency tables II
- [ ] Week 10 — Specialised models
- [ ] Week 11 — GLMMs
- [ ] Week 12 — Choose three analyses and plan the report
