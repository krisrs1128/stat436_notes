# Script to fix dates in all course notes for proper ordering
library(tidyverse)
library(yaml)

# Find all .Rmd files in _posts directories
files <- list.files("_posts", pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)

# Extract week and lesson numbers from filenames
file_info <- tibble(
  path = files,
  filename = basename(files),
  # Extract week and lesson numbers using regex
  week = as.numeric(str_extract(filename, "(?<=week)\\d+")),
  lesson = as.numeric(str_extract(filename, "(?<=-)\\d+(?=\\.Rmd)")),
  # Some files might have different patterns, let's check
  week_alt = as.numeric(str_extract(filename, "(?<=week\\d{2}-)\\d+")),
  lesson_alt = as.numeric(str_extract(filename, "(?<=week\\d{2}-\\d)\\d+"))
) %>%
  # Use alternative extraction if main one failed
  mutate(
    week = ifelse(is.na(week), str_extract(filename, "\\d+") %>% as.numeric(), week),
    lesson = ifelse(is.na(lesson), week_alt, lesson),
    lesson = ifelse(is.na(lesson), lesson_alt, lesson),
    lesson = ifelse(is.na(lesson), 1, lesson)  # default to lesson 1 if can't extract
  ) %>%
  arrange(week, lesson) %>%
  # Assign dates in reverse order (latest date = earliest course content)
  mutate(
    date_order = row_number(),
    # Start from a high date and count down
    date = as.Date("2024-12-31") - (date_order - 1)
  )

# Display the mapping for verification
cat("Date assignments for proper ordering:\n")
print(file_info %>% select(filename, week, lesson, date))

# Function to update YAML date in a file
update_yaml_date <- function(file_path, new_date) {
  # Read the file
  lines <- readLines(file_path, warn = FALSE)
  
  # Find YAML front matter boundaries
  yaml_start <- which(lines == "---")[1]
  yaml_end <- which(lines == "---")[2]
  
  if (is.na(yaml_start) || is.na(yaml_end)) {
    cat("Warning: Could not find YAML front matter in", file_path, "\n")
    return(FALSE)
  }
  
  # Extract and parse YAML
  yaml_lines <- lines[(yaml_start + 1):(yaml_end - 1)]
  yaml_text <- paste(yaml_lines, collapse = "\n")
  
  tryCatch({
    yaml_data <- yaml::yaml.load(yaml_text)
    yaml_data$date <- format(new_date, "%Y-%m-%d")
    
    # Convert back to YAML
    new_yaml <- yaml::as.yaml(yaml_data)
    new_yaml_lines <- strsplit(new_yaml, "\n")[[1]]
    
    # Reconstruct file
    new_lines <- c(
      lines[1:yaml_start],
      new_yaml_lines,
      lines[yaml_end:length(lines)]
    )
    
    # Write back to file
    writeLines(new_lines, file_path)
    cat("Updated", basename(file_path), "with date", format(new_date, "%Y-%m-%d"), "\n")
    return(TRUE)
  }, error = function(e) {
    cat("Error updating", file_path, ":", e$message, "\n")
    return(FALSE)
  })
}

# Apply date updates to all files
cat("\n\nUpdating files...\n")
for (i in 1:nrow(file_info)) {
  update_yaml_date(file_info$path[i], file_info$date[i])
}

cat("\nCompleted date assignments for", nrow(file_info), "files.\n")
