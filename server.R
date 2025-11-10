# Project: Trade Distortion Monitor
# Author: SEGAULT Luke
# Purpose: Server logic for the interactive dashboard.

library(shiny)
library(plotly)
library(dplyr)
library(ggplot2)

# Load the final, prepared data table containing all aggregated and calculated metrics
load("final_analysis_data.RData") 

server <- function(input, output, session) {
  
  # --- Setup: Populate Selector Boxes ---
  # Dynamically populates the sidebar selectors when the app starts.
  observe({
    # Filter out NA from choices before populating the selector boxes
    valid_country_choices <- unique(df_analysis_ready$Country_Name[!is.na(df_analysis_ready$Country_Name)])
    
    updateSelectInput(session, "country_select", 
                      choices = valid_country_choices, 
                      selected = "China")
    updateSelectInput(session, "sector_select", 
                      choices = unique(df_analysis_ready$ISIC_2D), 
                      selected = "24")
  })
  
  # --- TAB 1: Correlation Plot Logic ---
  
  # Calculate the Correlation Value once for display in the infoBox
  correlation_result <- cor(df_analysis_ready$Avg_Subsidy_Count[df_analysis_ready$Year == max(df_analysis_ready$Year)], 
                            df_analysis_ready$Export_Share_Growth[df_analysis_ready$Year == max(df_analysis_ready$Year)], 
                            use = "complete.obs")
  
  # Output the Correlation Value
  output$correlation_output <- renderText({
    paste0(round(correlation_result * 100, 2), "%")
  })
  
  # Output the Correlation Plot (Scatter plot: Global View)
  output$correlation_plot <- renderPlotly({
    plot_data <- df_analysis_ready %>%
      filter(Year == max(Year)) %>% 
      # Remove NA countries from the scatter plot data
      filter(!is.na(Country_Name))
    
    p <- ggplot(plot_data, aes(x = Avg_Subsidy_Count, y = Export_Share_Growth, 
                               text = paste("Country:", Country_Name, "<br>Sector:", ISIC_2D))) +
      geom_point(aes(color = Country_Name), alpha = 0.7, size = 3) +
      geom_smooth(method = "lm", color = "black", se = FALSE, linetype = "dashed") +
      labs(title = "Subsidy Intensity vs. Global Export Share Growth (2017-2023)",
           x = "Average Subsidy Count (Structural Support)",
           y = "Export Share Growth Rate (%)") +
      coord_cartesian(ylim = c(-1, 2)) + # Sets Y-axis from -100% to +200% (the fix)
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
  
  # --- TAB 2: Time Series Plot Logic ---
  
  # Define the reactive data source for the Time Series tab (Case Study View)
  timeseries_data <- reactive({
    req(input$country_select, input$sector_select)
    df_analysis_ready %>%
      filter(Country_Name == input$country_select,
             ISIC_2D == input$sector_select) %>%
      # Remove NA countries from the time series plot data
      filter(!is.na(Country_Name))
  })
  
  # Output the Time Series Plot (Subsidy Count over time)
  output$timeseries_plot <- renderPlotly({
    plot_data <- timeseries_data()
    
    if (nrow(plot_data) == 0) return(NULL)
    
    # Restructure data from wide to long format for easier plotting (Subsidy_Count and Export_Share)
    p <- plot_data %>%
      select(Year, Subsidy_Count, Export_Share) %>%
      tidyr::pivot_longer(cols = c(Subsidy_Count, Export_Share), names_to = "Metric", values_to = "Value") %>%
      
      ggplot(aes(x = Year, y = Value, color = Metric)) +
      geom_line(size = 1) +
      geom_point(size = 3) +
      labs(title = paste("Trends for", input$country_select, " - Sector:", input$sector_select),
           y = "Value", x = "Year", color = "Metric") +
      scale_x_continuous(breaks = unique(plot_data$Year)) +
      scale_color_manual(values = c("Subsidy_Count" = "blue", "Export_Share" = "red")) +
      theme_minimal()
    
    ggplotly(p)
  })
}