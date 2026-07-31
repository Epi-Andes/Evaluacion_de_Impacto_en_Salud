packages <- c(
  "httr",
  "dplyr",
  "openxlsx",
  "jsonlite",
  "readr",
  "writexl",
  "ggplot2",
  "stringr",
  "tidyr",
  "knitr",
  "kableExtra",
  "purrr",
  "readxl",
  "tidyverse",
  "shadowtext"
)

installed <- rownames(installed.packages())
missing <- setdiff(packages, installed)

if (length(missing) > 0) {
  install.packages(missing)
}
