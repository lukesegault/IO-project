Trade Policy Diagnostic: An Empirical Analysis of Structural Subsidies

This project presents a live, interactive diagnostic tool to test a core assumption underlying current global trade disputes: whether the frequency of a state’s industrial subsidy programs (structural support) correlates with measurable export success among G20 nations.

Live Interactive Dashboard

Explore the full analysis, correlation plots, and historical trends:

[https://lukesegault.shinyapps.io/Trade_Subsidies_Server/]

Core Finding and Geopolitical Implications

We tested the relationship between the Average Subsidy Count (2018–2023) and Export Share Growth across G20 industrial sectors.

Metric

Result

Political Science Interpretation

Correlation ($r$)

$r \approx -0.017$ (2023 Growth)

Regulatory Disconnect (Null Relationship)

Conclusion

The concentration of state interventions, when measured by program count, is not a statistically reliable factor for short-term trade distortion.



Strategic Implication

This null correlation highlights a fundamental regulatory disconnect in the global trading system. Trade friction observed at organizations like the WTO is likely driven by factors invisible to simple program-counting metrics—such as the political commitment of capital (financial magnitude) or non-transparent local content requirements.



Project Methodology and Technical Rigor

This study demonstrates the ability to execute a complex econometric pipeline and resolve significant data integration challenges on limited resources.

Data Fusion and Synthesis

Intervention Data: World Bank Unfair Advantage and Green Subsidies Database (Policy Measures). These measures align with the WTO definition, encompassing financial transfers, tax exemptions, and government actions that confer benefits to specific enterprises or industries.

Trade Outcome: CEPII BACI bilateral trade flows (HS 6-digit, 2017–2023, $\approx 77$ million rows).

Advanced R Skills & Data Handling

Big Data Processing: Employed data.table to manage and aggregate the large-scale trade panel data efficiently, mitigating common memory limitations.

Classification Bridging: Custom logic was developed in R to successfully bridge the granular product data (HS codes) with the industrial policy data (ISIC Rev 4 codes) based on the full concordance methodology.

Deliverable: Built a live, interactive dashboard using Shiny/Plotly to facilitate transparent exploration of the findings.

Repository Contents

File

Description

analysis_script.R

The complete, documented R data pipeline, from raw import to final correlation calculation.

ui.R & server.R

Source code for the interactive Shiny web application.

final_analysis_data.RData

The cleaned, pre-aggregated panel data used by the live app.
