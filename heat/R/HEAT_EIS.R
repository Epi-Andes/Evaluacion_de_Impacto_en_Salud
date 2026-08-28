# Code edits by Paula Chaparro, based on code by Greg Genna AND  Thomas Gotschi, Feb. 2026
# Close all, clear all
rm(list=ls())
graphics.off()

# Set working directory
setwd()

#TODO set your path ####


my_path <- # "Set working directory"

# Adjusting Greg's original code:
# Comments ####
#HEAT automation
#
# This script requires an .rds exported from the HEAT GUI with the settings
# to be used in running multiple HEATs (to obtain .rds file, see accompanying 
# documentation). It reads in a file with the values for the variables of 
# interest for each run, and exports a table with the results.The input data
# file should be in wide format, with a column for each variable to be changed
# for each run. Only the variables that are going to be varied between runs
# need to be included.


# TODO should download a city-level case, so you have the proper template ####
Colombia_Bog_onecase_webapp_input <- readRDS(paste0(my_path,"Colombia_onecase_webapp_input.rds"))
#
#Comments ####
# The API is limited to 5 calls/minute. A 10 second pause has been added 
# between calls to ensure the rate limit is not hit.
#
# Note that the HEAT API does not error check the values going in. The API
# developers advise to double check 10% of the outputs

# GUI version of the HEAT: https://www.heatwalkingcycling.org/tool/
# API readme: https://api.heatwalkingcycling.org/apiv1/readme.html
# Methods folder: https://sustrans.sharepoint.com/:f:/s/INT-PUB-10017349/Er2HBrC7lqlKrwdTWeJhsoIBTMAnadUwDxmJ6UD0ps2s4w?e=lAtEGE


# To do:
#  Create interface app to do the following:
#    Add loop for various assessment periods with appropriate discount rates
#    Add option for outputting data for other benefits (eg carbon), not just
#       physical activity



library(httr)
library(dplyr)
library(openxlsx)
library(jsonlite)
library(readr)
library(writexl)

#Comments####
# change as needed for file location
#username <- Sys.getenv("USERNAME")
#setwd(paste0("C:/Users/",username,"/OneDrive - Sustrans/Informal Methods/HaaS/HaaS"))


# read RDS exported from UI - change as needed for input .rds from HEAT and make a working copy
#Index_HEAT <- readRDS("HaaS Index Test.rds")
#Index_HEAT <- readRDS("HaaS test.rds")
# read the .rds document ####
Index_HEAT <- Colombia_Bog_onecase_webapp_input

Working_HEAT <- Index_HEAT

#set cookie value
cookie_value <- "1525a17bfa86007eb7788adcec47a4ea62414b75"

#read data entry file
# change the inputs of the .csv 
EntryData <- read_delim("Colombia_HEAT_inputs.csv", 
                        delim = ";", escape_double = FALSE, trim_ws = TRUE)
### datos de entrada #

  # Fix typo
  EntryData <- EntryData %>%
    rename(raw_activemode_walk_ref_number = raw_activemode_walk_ref_numer) 

# Comments ####
# Apologies for being slow on this: when you work with different locations, 
# you need to use the correct location_id and country_location_id. These are 
# HEAT internal id's (I share the UK and Ireland values). 
# In theory, because you provide the population data yourself, and you don't
# work with air pollution data, you could run everything under the UK id. It 
# woudl not affect your results, but HEAT needs a valid id. 
# If you plan to use air pollution in the future, reach out - I would need to 
# that data with you as well, unless you use your own. 
  
  
# Fix location_ids ####
  # correct the name
  EntryData$Index_geography <- gsub("Distrito Capital de BogotÇ", "Distrito Capital de Bogotá", EntryData$Index_geography)
  
  # Extract SUSTRANS city names
  cities <- EntryData %>%
    distinct(ucc_location_id)
  
# Comments ####
  # Get HEAT location id's
  # all_locations_data <- read_csv("~/Github/HEAT/HEAT_data/data/heatr/locations_data/all_locations_data.csv")
  # 
  # # Filter for UK
  # UK_locations <- all_locations_data %>%
  #   filter(country_location_name %in% c("The United Kingdom", "Ireland")) %>%
  #   select(location_id, country_location_id, country_location_name, city_location_name)
  # 
  # write.csv(UK_locations, "~/Github/HEAT/API user support/UK_locations.csv")
  
# read CSV ####  
  Colombia_locations <- read_delim("Colombia_HEAT_location_ids.csv", 
                                           delim = ";", escape_double = FALSE, trim_ws = TRUE)
  
  
  # Comments ####
  # TODO check and add manually as necessary
  # Some city names differ from HEAT entries so need to be matched manually
    # Galway = Claregalway?
    # Greater Cambridge, Greater Manchester
    # Limerick
    # Orkney
    # Tower Hamlets
    # Tyneside
    # UK urban extrapolation
    # ^ all these return error (because no location_id assigned yet)
  # correct id affects air pollution value and population - though the latter you provide, so no problem)
  
  
  # Filter for Sustrans cities ####
  sustrans_cities <- Colombia_locations %>%
    filter(location_id %in% cities$ucc_location_id)
  
  
  EntryData <- EntryData %>%
    left_join(sustrans_cities, by = c("ucc_location_id" = "location_id"))
  
  # Assign id values to cols in the webapp_input template
  EntryData <- EntryData %>%
    mutate(ucc_country_location_id = country_location_id)
  
  #create empty df for results ####
  
  HEAT_total <- data.frame()
  
  # Run HEAT for each segment/scenario ####
  
  for(i in 1:nrow(EntryData)){
    
    entryvars <- EntryData[i, ]
    
    # Copy template
    Working_HEAT <- Index_HEAT
    
    # Replace values with Excel inputs
    for (variable in names(entryvars)){
      
      if (variable %in% names(Working_HEAT)){
        
        Working_HEAT[[variable]] <- entryvars[[variable]][1]
        
      }
      
    }
    
    # Check IDs
    print(Working_HEAT$ucc_location_id)
    print(Working_HEAT$ucc_country_location_id)
    
    if (is.na(Working_HEAT$ucc_location_id) | 
        is.na(Working_HEAT$ucc_country_location_id)) {
      
      stop("Location IDs are missing. Check inputs.")
      
    }
    
    # Call HEAT API
    resp <- httr::POST(
      "https://api.heatwalkingcycling.org/apiv1/heat_5_0/results?output_format=json",
      httr::set_cookies("user" = cookie_value),
      body = list(webapp_input = Working_HEAT),
      encode = "json"
    )
    
    # Parse response
    HEAT_output <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8")
    )
    
    if (!"error" %in% names(HEAT_output)) {
      
      HEAT_results <- HEAT_output[["results"]]
      
      # Filter Physical Activity
      HEAT_results_PA <- subset(
        HEAT_results,
        pathway_label == "Physical activity"
      )
      
      # Filter Carbon Emissions
      HEAT_results_CO2 <- subset(
        HEAT_results,
        pathway_label == "Carbon emissions"
      )
      
      # Remove empty denominators
      HEAT_results_PA <- subset(
        HEAT_results_PA,
        denominator != "NA"
      )
      
      HEAT_results_CO2 <- subset(
        HEAT_results_CO2,
        denominator != "NA"
      )
      
      # Merge both
      HEAT_results_all <- rbind(
        HEAT_results_PA,
        HEAT_results_CO2
      )
      
      # Add identifiers
      HEAT_results_all$segment <- EntryData$segment[i]
      HEAT_results_all$city <- entryvars$Index_geography
      
      # Append results
      HEAT_total <- rbind(
        HEAT_total,
        HEAT_results_all
      )
      
    } else {
      
      print(paste("Error for segment:", EntryData$segment[i]))
      print(HEAT_output[["error"]])
      
    }
    
    # API rate limit
    Sys.sleep(10)
    
  }
  
  # ---------------------------------------
  # SELECT COLUMNS FOR FINAL EXCEL
  # ---------------------------------------
  
  HEAT_total_clean <- HEAT_total %>%
    select(
      segment,
      city,
      pathway_label,
      activemode,
      activemodecontrast,
      denominator,
      activemodepop,
      popunit,
      impacttotal,
      impacttotalco2,
      moneytotal,
      monetization,
      scc
    )
  
  # ---------------------------------------
  # EXPORT RESULTS
  # ---------------------------------------
  write_xlsx(
    HEAT_total_clean,
    "HEAT_resultados_total.xlsx"
  )
 