# Project: Trade Distortion Monitor
# Author: SEGAULT Luke
# Purpose: User Interface (UI) for the interactive dashboard.

library(shiny)
library(plotly)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(title = "Trade Distortion Monitor"),
  
  dashboardSidebar(
    # Defines the navigation menu items
    sidebarMenu(
      menuItem("Correlation Plot", tabName = "correlation", icon = icon("chart-bar")),
      menuItem("Time Series Trend", tabName = "timeseries", icon = icon("chart-line"))
    ),
    
    # --- Input Widgets for Case Study Filtering ---
    # Widget 1: Country Selector (Choices populated dynamically in server.R)
    selectInput("country_select", "Select Country:", 
                choices = NULL),
    
    # Widget 2: Sector Selector (Choices populated dynamically in server.R)
    selectInput("sector_select", "Select ISIC Sector:", 
                choices = NULL)
  ),
  
  dashboardBody(
    tabItems(
      # --- TAB 1: Correlation Visualization (Global View) ---
      tabItem(tabName = "correlation",
              h2("Sectoral Subsidy Intensity vs. Trade Competitiveness (2017-2023)"),
              fluidRow(
                # InfoBox 1: Displays the calculated correlation result (e.g., -1.74%)
                infoBox("Correlation (Subsidy Count vs. Export Growth)", 
                        textOutput("correlation_output"), 
                        icon = icon("handshake-angle"), 
                        color = "yellow", 
                        width = 6),
                
                # InfoBox 2: Policy Interpretation of the null correlation
                infoBox(title = "Policy Finding", 
                        value = "Structural support (by count of measures) is decoupled from export growth.", 
                        subtitle = "IO focus should shift to financial magnitude or subsidy design.",
                        icon = icon("lightbulb"), 
                        color = "blue", 
                        width = 6)
              ),
              # Space for the main scatter plot (plotlyOutput is defined in server.R)
              plotlyOutput("correlation_plot")
      ),
      
      # --- TAB 2: Time Series Trend (Case Study View) ---
      tabItem(tabName = "timeseries",
              h2("Subsidy Count and Export Share Over Time (2018-2023)"),
              # Space for the time series line plot (plotlyOutput is defined in server.R)
              plotlyOutput("timeseries_plot")
      )
    )
  )
)