library(rmarkdown)
library(tidyverse)

# Find all .Rmd files 
files <- list.files("_posts", pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)
cat("Found", length(files), "files to render\n")

# Render all files
cat("Starting full compilation...\n")
success_count <- 0
error_count <- 0

for (i in seq_along(files)) {
  cat("Rendering file", i, "of", length(files), ":", files[i], "\n")
  tryCatch({
    render(files[i])
    success_count <- success_count + 1
    cat("Successfully rendered", files[i], "\n")
  }, error = function(e) {
    error_count <- error_count + 1
    cat("Error rendering", files[i], ":", e$message, "\n")
  })
  
  # Progress update every 10 files
  if (i %% 10 == 0) {
    cat("Progress:", i, "/", length(files), "completed. Success:", success_count, "Errors:", error_count, "\n")
  }
}

cat("Compilation complete. Success:", success_count, "Errors:", error_count, "\n")
cat("Now rendering site...\n")
render_site()
cat("Site rendering complete!\n")
