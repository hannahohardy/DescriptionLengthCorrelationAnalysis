# Description Length Correlation Analysis
Used at an internship to clean, analyze, and visualize metrics. Correlation between description length and leads submitted were analyzed with Pearson's. SQL Query is used to gather the needed variables and backfill the missing data.

# 1. Introduction
This documentation outlines the process of analyzing the correlation between Description Length in listings and Email Lead Volume for the purpose of optimizing the Listing Score thresholds.
# 2. Data Collection
2.1 Locating Relevant Data and Variables
Identifying the required variables, including:
Description Length
Email Lead 
Condition
Portal
FSBO
Additional for joining purposes:
imt_id
id
ownerID
Source_date
Tables used:
keboola_replacement.[out].[c_bwd_reports.gap3_views_leads_connections_impstotal] 
Extracts.imt.products 
Description
The actual contents of it
Keboola_replacement.[in].[c_main_rs.parties]
FSBO
2.2 Data Collection Process
Investigated the data lineage to find where the needed variables were located and how to connect them to each other.
administrative.metadata.TableNames to find the TableID of gap3
310
administrative.metadata.Dependencies
look at the which processID feed into Table 310
82
5453
administrative.metadata.Process
Build_out_c_bwd_reports_gap3_views_leads_connections_impstotal
Build_out_Update_gap3_metrics
Located the procedure that is the function to fill in Description Lengths: isnull(len(p.Description),0) DescriptionLength



Backfill from where source_actual_date  '20220823'
<img width="571" alt="Screenshot 2023-09-11 at 1 39 26 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/e59e795a-298e-4eb8-ae9b-8e8c8e3df810">


To collect variables and backfill: 
Created a CTE:
Query 1 (AnalysisVarsQuery):
Imt_id
products.id
Condition
Portal
Description
DescriptionLength (ones that arent missing)
Source-date
Leads_email
Leads_total
FSBO
owner_id
OEM
Is model
Later use for NLP analysis
Query 2 (DescriptionLengthQuery):
missing description dates


# 3. Data Extraction
3.1 Exporting Data to CSV
Detail the process of extracting the collected data and exporting it into a CSV (Comma-Separated Values) file for further analysis.
All csv found in s3 Bucket: description-length-correlation-analysis-csv
# 4. Data Analysis
4.1 Correlation Analysis
Used Pearson’s as standard since they were all close by each other.
<img width="575" alt="Screenshot 2023-09-11 at 1 39 47 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/f89a5a14-3ce4-46ef-8d36-1fb2e54fc11a">
<img width="574" alt="Screenshot 2023-09-11 at 1 40 09 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/2512600e-4928-4fb5-a215-33360de3bb99">


No correlation since the coefficient is less than 1%


4.2 Sentiment Analysis 
Used WordCloud to find most frequent words or phrases.
<img width="577" alt="Screenshot 2023-09-11 at 1 40 26 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/0de3d231-0701-4330-bd22-3c0c1ed35c78">


# 5. Data Visualization
5.1 Visualizing Correlation Results
Scatterplot
<img width="564" alt="Screenshot 2023-09-11 at 1 40 43 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/1efe7c89-45d8-4fe6-ba9e-625954b7b966">

Heatmaps
<img width="673" alt="Screenshot 2023-09-11 at 1 41 04 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/fd88fec3-5c08-449f-af6d-26902018f7d7">
<img width="640" alt="Screenshot 2023-09-11 at 1 41 22 AM" src="https://github.com/hannahohardy/DescriptionLengthCorrelationAnalysis/assets/80282921/84d6a9a7-f56d-4da2-8384-9b7073fe2407">

