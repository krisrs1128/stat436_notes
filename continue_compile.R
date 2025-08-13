library(rmarkdown)
library(tidyverse)

# Find all .Rmd files 
files <- list.files("_posts", pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)
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

# Continue compilation from remaining files
success_count <- 0
error_count <- 0

for (i in seq_along(remaining_files)) {
  cat("Rendering file", i, "of", length(remaining_files), ":", remaining_files[i], "\n")
  tryCatch({
    render(remaining_files[i])
    success_count <- success_count + 1
    cat("Successfully rendered", remaining_files[i], "\n")
  }, error = function(e) {
    error_count <- error_count + 1
    cat("Error rendering", remaining_files[i], ":", e$message, "\n")
  })
  
  # Progress update every 5 files
  if (i %% 5 == 0) {
    cat("Progress:", i, "/", length(remaining_files), "remaining completed. Success:", success_count, "Errors:", error_count, "\n")
  }
}

cat("\nFinal summary:\n")
cat("Successfully compiled:", success_count, "additional files\n")
cat("Errors:", error_count, "\n")
cat("Total files now compiled:", length(compiled_files) + success_count, "out of", length(files), "\n")

# After all individual files are done, render the site
cat("\nGenerating final site...\n")
rmarkdown::render_site()
cat("Site generation complete!\n")
