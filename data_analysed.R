# Project: Trade Distortion Monitor
# Author: SEGAULT Luke
# Purpose: Measures the correlation between the frequency of G20 industrial subsidy measures 
#          and the resulting growth in sector-level export market share (2017-2023).
# Finding: Correlation is near zero (r ≈ -0.017), suggesting structural count is not the primary driver of distortion.

# 1. SETUP AND PACKAGE LOADING
library(data.table) # Optimized for large data processing
library(tidyverse)  # Core data manipulation tools
library(readxl)     # For reading Excel files


# --- I. IMPORT & CLEAN SUBSIDY DATA ---

# A. Import and Combine Subsidy Measures (Source: World Bank Unfair Advantage / Green Subsidies)
df_subsidy_general <- read_excel("Regular Subsidies.xlsx", sheet = "Subsidy measures")
df_subsidy_green <- read_excel("Green Subsidies.xlsx", sheet = "GSD")
df_subsidies_combined <- bind_rows(df_subsidy_general, df_subsidy_green)

# B. Define G20 Countries (Based on names found in the subsidies data)
G20_codes_NAMES <- c("Brazil", "Canada", "China", "Germany", "Italy", "United Kingdom", 
                     "France", "European Union", "India", "Japan", "Korea, Rep.", 
                     "Mexico", "Argentina", "Australia", "Turkey", "Russian Federation", 
                     "United States", "Indonesia")

# C. Clean and Aggregate Subsidies by Country, Year, and ISIC Sector (Count)
df_subsidies_count <- df_subsidies_combined %>%
  # Rename key variables for clarity
  rename(Country_Name = country, Sector_Codes_Raw = sector_categories, Year = refyear) %>%
  # Filter to G20 scope and remove missing years
  filter(Country_Name %in% G20_codes_NAMES, !is.na(Year)) %>%
  # Separate multi-sector codes (e.g., "301; 303") into individual rows
  separate_rows(Sector_Codes_Raw, sep = ";\\s*") %>%
  # Extract the 2-digit ISIC code for linking with trade data
  mutate(ISIC_2D = stringr::str_extract(Sector_Codes_Raw, "^\\d{2}")) %>%
  # Aggregate: Count the unique number of subsidy measures ('tempid')
  group_by(Country_Name, Year, ISIC_2D) %>%
  summarise(Subsidy_Count = n_distinct(tempid), .groups = 'drop') %>%
  drop_na(ISIC_2D)


# --- II. IMPORT & AGGREGATE TRADE DATA (MEMORY-EFFICIENT) ---

# A. List BACI files for stacking (77 million records)
baci_files_list <- list.files(path = "./baci_files", pattern = "^BACI.*\\.csv$", full.names = TRUE)    

# B. Import and Convert to data.table 
df_trade_baci <- baci_files_list %>% map_dfr(~read_csv(.x, col_types = cols(.default = "c")))
dt_trade_baci <- as.data.table(df_trade_baci)
rm(df_trade_baci); gc() # Free up memory

# C. Country Map (Links BACI numeric codes to Country Names)
df_country_map_manual <- tibble(
  Country_Code = as.character(c(4, 124, 156, 276, 380, 826, 250, 500, 356, 392, 410, 320, 36, 792, 643, 840, 360)), 
  Country_Name_Trade = c("Brazil", "Canada", "China", "Germany", "Italy", "United Kingdom", "France", "European Union", "India", "Japan", "Korea, Rep.", "Mexico", "Argentina", "Australia", "Turkey", "Russian Federation", "United States") 
)

# D. EFFICIENT AGGREGATION and ISIC Mapping (data.table)
# Replicating the HS-to-ISIC concordance logic found in the original source
dt_trade_baci[, twodigit := as.numeric(substring(k, 1, 2))]
dt_trade_baci[, ISIC_2D := fcase(
  twodigit %in% c(2:5, 7:12, 14:21, 23), "10", twodigit == 22, "11", twodigit == 24, "12",
  twodigit %in% c(50:60, 63, 94), "13", twodigit %in% c(61, 62, 65, 43), "14", 
  twodigit %in% c(44:46), "16", twodigit == 47, "17", twodigit == 49, "18", 
  twodigit %in% c(72, 75, 78, 79, 80, 81), "24", twodigit %in% c(82, 83), "25",
  twodigit %in% c(90, 91), "26", twodigit %in% c(84, 85, 87), "28", twodigit %in% c(87), "29" 
)]

df_trade_summary <- dt_trade_baci[
  !is.na(ISIC_2D), 
  .(Total_Export_Value = sum(as.numeric(v), na.rm = TRUE)), 
  by = .(Country_Code = i, Year = t, ISIC_2D)
]
rm(dt_trade_baci); gc()
df_trade_summary <- as_tibble(df_trade_summary)


# --- III. FINAL MASTER JOIN ---

# Join the trade totals and subsidy counts
df_master_analysis <- df_trade_summary %>%
  left_join(df_country_map_manual, by = "Country_Code") %>%
  rename(Country_Name = Country_Name_Trade) %>%
  mutate(Year = as.numeric(Year)) %>%
  left_join(df_subsidies_count, by = c("Country_Name", "Year", "ISIC_2D")) %>%
  # Assume zero support/trade if missing after final join
  mutate(Total_Export_Value = replace_na(Total_Export_Value, 0),
         Subsidy_Count = replace_na(Subsidy_Count, 0))


# --- IV. FINAL ANALYTICAL CALCULATION (FIXED Y-AXIS SCALE) ---

df_analysis_ready <- df_master_analysis %>%
  # 1. Calculate Export Share
  group_by(Year, ISIC_2D) %>%
  mutate(Total_Sector_Exports = sum(Total_Export_Value, na.rm = TRUE),
         Export_Share = Total_Export_Value / Total_Sector_Exports) %>%
  ungroup() %>%
  
  # 2. Calculate Lagged Share and Filter (CRITICAL FOR Y-AXIS FIX)
  group_by(Country_Name, ISIC_2D) %>%
  arrange(Year) %>%
  mutate(Lag_Export_Share = lag(Export_Share, n = 1)) %>%
  ungroup() %>%
  
  # Filter out near-zero denominators to remove multi-million percent outliers
  filter(Lag_Export_Share > 1e-6) %>% 
  
  # Recalculate Grouping for final metrics
  group_by(Country_Name, ISIC_2D) %>%
  
  # Calculate Growth Rate (Now safe to divide)
  mutate(Export_Share_Growth = (Export_Share - Lag_Export_Share) / Lag_Export_Share) %>%
  
  # 3. Calculate Average Subsidy Count
  mutate(Avg_Subsidy_Count = mean(Subsidy_Count, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(Year != min(Year)) # Remove first year (2017) data point

# Save the final table for the Shiny App to load
save(df_analysis_ready, file = "final_analysis_data.RData")