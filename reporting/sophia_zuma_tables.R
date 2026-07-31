######################## AirQ+ & GreenUr Tables - METRO #######################

# Close all, clear all
rm(list=ls())
graphics.off()

# Set working directory
setwd("~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Fulbright/Breathe Cities") #Change this based on user

# Load required packages
library(ggplot2);library(dplyr);library(stringr);library(tidyr);library(knitr)
library(kableExtra);library(purrr);library(readxl);library(tidyverse)
library(shadowtext)

# Read in data
airq <- read_excel("ZUMA_AIRQ+.xlsx")
greenur <- read_excel("resultados_greenur_ZUMA.xlsx")
#heat <- read_excel("HEAT_zuma_resultados.xlsx")
# heat <- heat %>%
#   mutate(across(3:9, ~ {
#     x <- as.character(.)
#     x <- str_replace_all(x, ",", ".")      
#     x <- str_replace_all(x, "[^0-9.-]", "") 
#     as.numeric(x)
#   }))
# names(heat) <- trimws(names(heat))

airq_pm25_it4 <- read.csv("AIRQ_PM25_ZUMA_IT4_10.csv",
                          colClasses = c(SETU_CCNCT = "character"))
airq_pm25_oms <- read.csv("AIRQ_PM25_ZUMA_OMS_5.csv",
                          colClasses = c(SETU_CCNCT = "character"))
airq_pm25_pa <- read.csv("AIRQ_PM25_ZUMA_PA_15.csv",
                         colClasses = c(SETU_CCNCT = "character"))

airq_pm10_it4 <- read.csv("AIRQ_PM10_ZUMA_IT4_20.csv",
                          colClasses = c(SETU_CCNCT = "character"))
airq_pm10_oms <- read.csv("AIRQ_PM10_ZUMA_OMS_15.csv",
                          colClasses = c(SETU_CCNCT = "character"))
airq_pm10_pa <- read.csv("AIRQ_PM10_ZUMA_PA_30.csv",
                         colClasses = c(SETU_CCNCT = "character"))

airq_no2_it3 <- read.csv("AIRQ_NO2_ZUMA_IT3_20.csv",
                         colClasses = c(SETU_CCNCT = "character"))
airq_no2_oms <- read.csv("AIRQ_NO2_ZUMA_OMS_10.csv",
                         colClasses = c(SETU_CCNCT = "character"))
airq_no2_pa <- read.csv("AIRQ_NO2_ZUMA_PA_40.csv",
                        colClasses = c(SETU_CCNCT = "character"))

#combine 
# 1. List the dataframes to merge into airq
dfs_to_add <- list(
  airq_pm25_it4, airq_pm25_oms, airq_pm25_pa,
  airq_pm10_it4, airq_pm10_oms, airq_pm10_pa,
  airq_no2_it3, airq_no2_oms, airq_no2_pa
)

# 2. Overwrite airq by joining only unique columns
for (df in dfs_to_add) {
  # Get names of columns in the new DF that are NOT already in airq
  new_cols <- setdiff(names(df), names(airq))
  
  # Join only SETU_CCNCT and the truly new variables
  airq <- left_join(airq, df[, c("SETU_CCNCT", new_cols)], by = "SETU_CCNCT")
}

# 3. Remove columns where every value is identical (constant columns)
airq <- airq %>%
  select(where(~ n_distinct(.x, na.rm = TRUE) > 1))

# Check data
colnames(airq)
table(airq$SETU_CCNCT)
length(unique(airq$SETU_CCNCT))
str(airq)
summary(airq)

colnames(greenur)
table(greenur$SETU_CCNCT)
length(unique(greenur$SETU_CCNCT))
str(greenur)
summary(greenur)

# Devuelve un vector lógico
is.na(airq)
# Devuelve un único valor lógico, cierto o falso, si existe algún valor ausente
any(is.na(airq))
# Devuelve el número de NAs que presenta la tabla
sum(is.na(airq))
# Devuelve el % de valores perdidos
mean(is.na(airq))
# Detección del número de valores perdidos en cada una de las columnas que presenta la tabla
colSums(is.na(airq))
# Detección del % de valores perdidos en cada una de las columnas que presenta la tabla
colMeans(is.na(airq)*100)

# Devuelve un vector lógico
is.na(greenur)
# Devuelve un único valor lógico, cierto o falso, si existe algún valor ausente
any(is.na(greenur))
# Devuelve el número de NAs que presenta la tabla
sum(is.na(greenur))
# Devuelve el % de valores perdidos
mean(is.na(greenur))
# Detección del número de valores perdidos en cada una de las columnas que presenta la tabla
colSums(is.na(greenur))
# Detección del % de valores perdidos en cada una de las columnas que presenta la tabla
colMeans(is.na(greenur)*100)

#===============================================================================
# Population stats
get_stats <- function(data, vars, label) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      n       = format(sum(value, na.rm = TRUE), big.mark = ","),
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(sd(value, na.rm = TRUE), 0), big.mark = ",")),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 0), big.mark = ",")),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(max(value, na.rm = TRUE), 0), big.mark = ","))
    ) %>%
    mutate(Población = label) %>%
    select(Población, Total = n, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# Execution
table_combined <- bind_rows(
  get_stats(airq, "MAYORES_30AÑOS", "ZUMA ≥30 años"),
  get_stats(greenur, "MAYORES_20AÑOS", "ZUMA ≥20 años"),
  get_stats(airq, "POBLACION", "Bogotá total")
)

# Render
kable(
  table_combined,
  align = "lcccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 24
  ) %>%
  column_spec(2:5, extra_css = "padding-left: 15px; padding-right: 15px;")

#===============================================================================
# Area
get_area_stats <- function(data, vars, label) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    # Division applied here
    mutate(value = value / 1000000) %>% 
    group_by(name) %>%
    summarise(
      n       = format(round(sum(value, na.rm = TRUE), 1), big.mark = ",", nsmall = 1),
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 1), big.mark = ",", nsmall = 1),
                        format(round(sd(value, na.rm = TRUE), 1), big.mark = ",", nsmall = 1)),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 1), big.mark = ",", nsmall = 1),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 1), big.mark = ",", nsmall = 1),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 1), big.mark = ",", nsmall = 1)),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 1), big.mark = ",", nsmall = 1),
                        format(round(max(value, na.rm = TRUE), 1), big.mark = ",", nsmall = 1))
    ) %>%
    mutate(Sector = label) %>%
    select(Sector, Total = n, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# Execution
table_area <- get_area_stats(airq, "area_m2", "Area (km²)")

# Render
kable(table_area, align = "lcccc", booktabs = TRUE) %>%
  kable_styling(full_width = FALSE, font_size = 24) %>%
  column_spec(2:5, extra_css = "padding-left: 15px; padding-right: 15px;")

#===============================================================================
# NDVI
get_ndvi_stats <- function(data, vars) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 2), big.mark = ",", nsmall = 2),
                        format(round(sd(value, na.rm = TRUE), 2), big.mark = ",", nsmall = 2)),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 2), big.mark = ",", nsmall = 2),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 2), big.mark = ",", nsmall = 2),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 2), big.mark = ",", nsmall = 2)),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 2), big.mark = ",", nsmall = 2),
                        format(round(max(value, na.rm = TRUE), 2), big.mark = ",", nsmall = 2))
    ) %>%
    select(`Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# Run for NDVI
table_ndvi <- get_ndvi_stats(greenur, "NDVI_2022_mean")

# Render
kable(
  table_ndvi, 
  align = "ccc", 
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 24
  ) %>%
  column_spec(1:3, extra_css = "padding-left: 20px; padding-right: 20px;")

#===============================================================================
# PM2.5 Muertes prevenibles
get_stats <- function(data, vars, label) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      n       = format(round(sum(value, na.rm = TRUE), 0), big.mark = ","),
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(sd(value, na.rm = TRUE), 0), big.mark = ",")),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 0), big.mark = ",")),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(max(value, na.rm = TRUE), 0), big.mark = ","))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, Total = n, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution using your variables
table_combined_pm25 <- bind_rows(
  get_stats(airq, "muertes_atr_OMS_5", "OMS (5 µg/m³)"),
  get_stats(airq, "muertes_atr_IT4_10", "OMS IT-4 (10 µg/m³)"),
  get_stats(airq, "muertes_atr_PA_15", "Plan Aire (15 µg/m³)")
)

# 3. Render
kable(
  table_combined_pm25,
  align = "lcccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 24
  ) %>%
  column_spec(2:5, extra_css = "padding-left: 15px; padding-right: 15px;")

# PM2.5 PAF
get_paf_stats <- function(data, var, label) {
  data %>%
    select(all_of(var)) %>%
    pivot_longer(everything()) %>%
    summarise(
      avg_sd  = sprintf("%.1f%% (%.1f%%)", 
                        mean(value * 100, na.rm = TRUE), 
                        sd(value * 100, na.rm = TRUE)),
      med_iqr = sprintf("%.1f%% (%.1f%%–%.1f%%)", 
                        median(value * 100, na.rm = TRUE), 
                        quantile(value * 100, 0.25, na.rm = TRUE), 
                        quantile(value * 100, 0.75, na.rm = TRUE)),
      range   = sprintf("%.1f%%–%.1f%%", 
                        min(value * 100, na.rm = TRUE), 
                        max(value * 100, na.rm = TRUE))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution with updated variable names
table_combined_paf <- bind_rows(
  get_paf_stats(airq, "PAF_OMS_5", "OMS (5 µg/m³)"),
  get_paf_stats(airq, "PAF_IT4_10", "OMS IT-4 (10 µg/m³)"),
  get_paf_stats(airq, "PAF_PA_15", "Plan Aire (15 µg/m³)")
)

# 3. Render
kable(
  table_combined_paf,
  align = "lccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 24
  ) %>%
  column_spec(1:3, extra_css = "padding-left: 20px; padding-right: 20px;")

#===============================================================================
# PM10 Muertes prevenibles
get_stats <- function(data, vars, label) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      n       = format(round(sum(value, na.rm = TRUE), 0), big.mark = ","),
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(sd(value, na.rm = TRUE), 0), big.mark = ",")),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 0), big.mark = ",")),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(max(value, na.rm = TRUE), 0), big.mark = ","))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, Total = n, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution using your variables
table_combined_pm10 <- bind_rows(
  get_stats(airq, "muertes_atr_OMS_15", "OMS (15 µg/m³)"),
  get_stats(airq, "muertes_atr_IT4_20", "OMS IT-4 (20 µg/m³)"),
  get_stats(airq, "muertes_atr_PA_30", "Plan Aire (30 µg/m³)")
)

# 3. Render
kable(
  table_combined_pm10,
  align = "lcccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 24
  ) %>%
  column_spec(2:5, extra_css = "padding-left: 15px; padding-right: 15px;")

# PM10 PAF
get_paf_stats <- function(data, var, label) {
  data %>%
    select(all_of(var)) %>%
    pivot_longer(everything()) %>%
    summarise(
      avg_sd  = sprintf("%.1f%% (%.1f%%)", 
                        mean(value * 100, na.rm = TRUE), 
                        sd(value * 100, na.rm = TRUE)),
      med_iqr = sprintf("%.1f%% (%.1f%%–%.1f%%)", 
                        median(value * 100, na.rm = TRUE), 
                        quantile(value * 100, 0.25, na.rm = TRUE), 
                        quantile(value * 100, 0.75, na.rm = TRUE)),
      range   = sprintf("%.1f%%–%.1f%%", 
                        min(value * 100, na.rm = TRUE), 
                        max(value * 100, na.rm = TRUE))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution with updated variable names
table_combined_paf_pm10 <- bind_rows(
  get_paf_stats(airq, "PAF_OMS_15", "OMS (15 µg/m³)"),
  get_paf_stats(airq, "PAF_IT4_20", "OMS IT-4 (20 µg/m³)"),
  get_paf_stats(airq, "PAF_PA_30", "Plan Aire (30 µg/m³)")
)

# 3. Render
kable(
  table_combined_paf_pm10,
  align = "lccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 30
  ) %>%
  column_spec(1:3, extra_css = "padding-left: 20px; padding-right: 20px;")

#===============================================================================
# NO2 Muertes prevenibles 
get_stats <- function(data, vars, label) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      n       = format(round(sum(value, na.rm = TRUE), 0), big.mark = ","),
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(sd(value, na.rm = TRUE), 0), big.mark = ",")),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 0), big.mark = ",")),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(max(value, na.rm = TRUE), 0), big.mark = ","))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, Total = n, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution using your variables
table_combined_no2 <- bind_rows(
  get_stats(airq, "muertes_atr_OMS_10", "OMS (10 µg/m³)"),
  get_stats(airq, "muertes_atr_IT3_20", "OMS IT-3 (20 µg/m³)")
)

# 3. Render
kable(
  table_combined_no2,
  align = "lcccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 30
  ) %>%
  column_spec(2:5, extra_css = "padding-left: 15px; padding-right: 15px;")

# NO2 PAF
get_paf_stats <- function(data, var, label) {
  data %>%
    select(all_of(var)) %>%
    pivot_longer(everything()) %>%
    summarise(
      avg_sd  = sprintf("%.1f%% (%.1f%%)", 
                        mean(value * 100, na.rm = TRUE), 
                        sd(value * 100, na.rm = TRUE)),
      med_iqr = sprintf("%.1f%% (%.1f%%–%.1f%%)", 
                        median(value * 100, na.rm = TRUE), 
                        quantile(value * 100, 0.25, na.rm = TRUE), 
                        quantile(value * 100, 0.75, na.rm = TRUE)),
      range   = sprintf("%.1f%%–%.1f%%", 
                        min(value * 100, na.rm = TRUE), 
                        max(value * 100, na.rm = TRUE))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution with updated variable names
table_combined_paf_no2 <- bind_rows(
  get_paf_stats(airq, "PAF_OMS_10", "OMS (10 µg/m³)"),
  get_paf_stats(airq, "PAF_IT3_20", "OMS IT-3 (20 µg/m³)")
)

# 3. Render
kable(
  table_combined_paf_no2,
  align = "lccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 30
  ) %>%
  column_spec(1:3, extra_css = "padding-left: 20px; padding-right: 20px;")

#===============================================================================
# NDVI Muertes prevenibles 
get_stats <- function(data, vars, label) {
  data %>%
    select(all_of(vars)) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise(
      n       = format(round(sum(value, na.rm = TRUE), 0), big.mark = ","),
      avg_sd  = sprintf("%s (%s)", 
                        format(round(mean(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(sd(value, na.rm = TRUE), 0), big.mark = ",")),
      med_iqr = sprintf("%s (%s–%s)", 
                        format(round(median(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.25, na.rm = TRUE), 0), big.mark = ","),
                        format(round(quantile(value, 0.75, na.rm = TRUE), 0), big.mark = ",")),
      range   = sprintf("%s–%s", 
                        format(round(min(value, na.rm = TRUE), 0), big.mark = ","),
                        format(round(max(value, na.rm = TRUE), 0), big.mark = ","))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, Total = n, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution using your variables
table_combined_ndvi <- bind_rows(
  get_stats(greenur, "vidas_salvadas_q75_5", "5%"),
  get_stats(greenur, "vidas_salvadas_q75_10", "10%")
)

# 3. Render
kable(
  table_combined_ndvi,
  align = "lcccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 30
  ) %>%
  column_spec(2:5, extra_css = "padding-left: 15px; padding-right: 15px;")

# NDVI PAF
get_paf_stats <- function(data, var, label) {
  data %>%
    select(all_of(var)) %>%
    pivot_longer(everything()) %>%
    summarise(
      avg_sd  = sprintf("%.1f%% (%.1f%%)", 
                        mean(value * 100, na.rm = TRUE), 
                        sd(value * 100, na.rm = TRUE)),
      med_iqr = sprintf("%.1f%% (%.1f%%–%.1f%%)", 
                        median(value * 100, na.rm = TRUE), 
                        quantile(value * 100, 0.25, na.rm = TRUE), 
                        quantile(value * 100, 0.75, na.rm = TRUE)),
      range   = sprintf("%.1f%%–%.1f%%", 
                        min(value * 100, na.rm = TRUE), 
                        max(value * 100, na.rm = TRUE))
    ) %>%
    mutate(Escenario = label) %>%
    select(Escenario, `Media (DE)` = avg_sd, `Mediana (RIC)` = med_iqr, `Min–Max` = range)
}

# 2. Execution with updated variable names
table_combined_paf_ndvi <- bind_rows(
  get_paf_stats(greenur, "PAF_q75_5", "5%"),
  get_paf_stats(greenur, "PAF_q75_10", "10%")
)

# 3. Render
kable(
  table_combined_paf_ndvi,
  align = "lccc",
  booktabs = TRUE
) %>%
  kable_styling(
    full_width = FALSE, 
    font_size = 30
  ) %>%
  column_spec(1:3, extra_css = "padding-left: 20px; padding-right: 20px;")



