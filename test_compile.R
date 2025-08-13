library(rmarkdown)
library(tidyverse)

# Find all .Rmd files 
files <- list.files("_posts", pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)
cat("Found", length(files), "files to render\n")

# Just render the first few to test
test_files <- files[1:5]
cat("Testing with first 5 files:\n")
print(test_files)

for (i in 1:length(test_files)) {
  cat("Rendering file", i, "of", length(test_files), ":", test_files[i], "\n")
  tryCatch({
    render(test_files[i])
    cat("Successfully rendered", test_files[i], "\n")
  }, error = function(e) {
    cat("Error rendering", test_files[i], ":", e$message, "\n")
  })
}

cat("Now rendering site...\n")
render_site()
