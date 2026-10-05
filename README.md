Bank Loan Default & Credit Risk Analytics

An end-to-end analytics project that studies loan default patterns and segments borrowers by credit risk, from data generation to an interactive dashboard.

Note: This project uses a synthetic dataset of 7,000 loan applications (Aug 2024 to Jul 2026) with built-in correlations between credit score, debt-to-income ratio, employment type and default probability. It was built to practise the complete analytics workflow.

Objective

Identify which borrower segments carry the highest default risk and present the findings in an interactive dashboard that supports lending decisions.

Tools & Workflow
Stage	Tool	What was done
1. Data generation	Python (pandas, NumPy)	Created 7,000 loan applications with realistic correlations and a logistic default-probability model
2. Storage & transformation	SQL Server	Staging table, typed fact table, credit-band and risk-category segmentation, analytical queries, reporting view
3. Visualisation	Power BI	3-page interactive dashboard
4. Web version	HTML + Chart.js	Standalone interactive dashboard
SQL Highlights
Credit band segmentation: Poor (300-580), Fair (580-670), Good (670-740), Excellent (740-900)
Risk category (High / Medium / Low) using credit score and debt-to-income ratio together
Window functions: RANK() for branch-wise default ranking, running total of defaults with SUM() OVER, and NTILE(4) for risk quartiles within each branch
Reporting view vw_loan_risk_summary as the Power BI data source
Key Insights
Overall default rate: 24.4% (1,708 of 7,000 applications)
Credit score drives risk: default rate falls from 34.3% (Poor) to 25.3% (Fair), 18.7% (Good) and 14.5% (Excellent)
Self-employed borrowers default most: 32.8%, compared with 23.5% for Business and 21.0% for Salaried
Risk category works as a filter: High Risk 34.3%, Medium Risk 24.8%, Low Risk 16.4%
Branch variation is small: Coimbatore is highest at 25.8% and Trichy lowest at 21.5%, so credit profile matters more than location
Repository Structure
loan_applicant_data.csv: synthetic dataset (7,000 loan applications)
Python_Script_Bankloan.py: data generation script
Bankloansql.sql: SQL Server staging, segmentation, analysis queries and reporting view
How to Run
Run the Python script to generate the dataset (the script saves the CSV in the same folder).
Create the database and tables with the SQL script, then import the CSV into stg_loan_applicants.
Run the rest of the SQL script to build the fact table and the reporting view.
Connect Power BI to the vw_loan_risk_summary view.
Author

Maadesh | MBA (Finance & Business Analytics) | LinkedIn
