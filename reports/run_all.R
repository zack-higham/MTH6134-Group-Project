# run_all.R — runs every script in code/ in numerical order, from a clean state.
# Use before each lecturer check (weeks 5, 8, 11):
#   1. Restart R (Session > Restart R) with the .Rproj open.
#   2. source("run_all.R")
# Each script runs in its own environment, so one script can't silently rely on
# objects left over from another. A failing script is reported, not fatal.

# Only the numbered scripts (00_..., 01a_..., 04e_...). Other files in code/,
# such as rough drafts, are kept but not run.
scripts <- sort(list.files("code", pattern = "^[0-9].*\\.R$", full.names = TRUE))

results <- data.frame(script = basename(scripts), status = "", message = "",
                      stringsAsFactors = FALSE)

for (i in seq_along(scripts)) {
  cat("\n==== Running", scripts[i], "====\n")
  res <- tryCatch({
    source(scripts[i], local = new.env(), echo = FALSE)
    c("OK", "")
  }, error = function(e) c("FAILED", conditionMessage(e)))
  # close any plotting device a failed script left open
  while (!is.null(dev.list())) dev.off()
  results$status[i]  <- res[1]
  results$message[i] <- res[2]
}

cat("\n==== Summary ====\n")
print(results, right = FALSE)
if (any(results$status == "FAILED")) {
  cat("\nSome scripts failed: fix them before the lecturer check.\n")
}
