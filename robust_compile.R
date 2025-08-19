library(rmarkdown)
library(tidyverse)

# Find all .Rmd files 
files <- list.files("_posts", pattern = "\\.Rmd", recursive = TRUE, full.names = TRUE)
cat("Found", length(files), "files to render\n")

# Check which files have already been compiled
compiled_dirs <- list.dirs("docs/posts", recursive = FALSE, full.names = FALSE)
compiled_files <- paste0("_posts/", compiled_dirs, "/", 
                         sub("\\d{4}-\\d{2}-\\d{2}-", "", compiled_dirs), ".Rmd")

# Find files that still need to be compiled
remaining_files <- setdiff(files, compiled_files)
cat("Already compiled:", length(compiled_files), "files\n")
cat("Remaining to compile:", length(remaining_files), "files\n")

# Sort remaining files to ensure proper order
remaining_files <- sort(remaining_files)

# --- Problematic files that should be run in their own R sessions ---
# These were reported by the user as failing when run in the batch but working
# in fresh R sessions. We render them in isolated processes.
problem_files <- c(
  "_posts/2024-12-27-week13-3/week13-3.Rmd",
  "_posts/2024-12-27-week12-2/week12-2.Rmd",
  "_posts/2024-12-27-week10-5/week10-5.Rmd",
  "_posts/2024-12-27-week10-3/week10-3.Rmd",
  "_posts/2024-12-27-week09-02/week09-02.Rmd",
  "_posts/2024-12-27-week03-01/week03-01.Rmd"
)

# Helper: render a file in a new R process. Prefer callr if installed, else fall
# back to invoking Rscript. Returns invisible(TRUE) on success, otherwise throws.
render_in_new_session <- function(file) {
  if (requireNamespace("callr", quietly = TRUE)) {
    # callr::r will run the function in a separate R process
    res <- tryCatch({
      callr::r(function(f) {
        # load rmarkdown in the child and render
        library(rmarkdown)
        rmarkdown::render(f, quiet = TRUE)
      }, args = list(f = file))
      TRUE
    }, error = function(e) {
      stop("Rendering in new session failed: ", e$message)
    })
    return(invisible(res))
  }

  # Fallback: call Rscript -e "rmarkdown::render('file', quiet=TRUE)"
  cmd <- sprintf("rmarkdown::render(%s, quiet = TRUE)", shQuote(file))
  status <- system2("Rscript", args = c("-e", cmd))
  if (status != 0) stop("Rscript render failed with status ", status)
  invisible(TRUE)
}

# Continue compilation from remaining files
success_count <- 0
error_count <- 0
error_files <- character()

for (i in seq_along(remaining_files)) {
  f <- remaining_files[i]
  cat("Rendering file", i, "of", length(remaining_files), ":", f, "\n")
  tryCatch({
    if (f %in% problem_files) {
      cat(" -> Running in isolated R session:\n")
      render_in_new_session(f)
    } else {
      # regular in-process render
      rmarkdown::render(f, quiet = TRUE)
    }
    success_count <- success_count + 1
    cat("Successfully rendered", f, "\n")
  }, error = function(e) {
    error_count <- error_count + 1
    error_files <<- c(error_files, f)
    cat("Error rendering", f, ":", e$message, "\n")
  })

  # Progress update every 5 files
  if (i %% 5 == 0) {
    cat("Progress:", i, "/", length(remaining_files), "completed. Success:", success_count, "Errors:", error_count, "\n")
  }
}

cat("\nFinal summary:\n")
cat("Successfully compiled:", success_count, "additional files\n")
cat("Errors:", error_count, "\n")
if (error_count > 0) {
  cat("Files with errors:\n")
  for (f in error_files) cat("  -", f, "\n")
}
cat("Total files now compiled:", length(compiled_files) + success_count, "out of", length(files), "\n")
cat("Remaining files (including skipped):", length(files) - length(compiled_files) - success_count, "\n")

# After all individual files are done, render the site
cat("\nGenerating final site...\n")
rmarkdown::render_site()
cat("Site generation complete!\n")
