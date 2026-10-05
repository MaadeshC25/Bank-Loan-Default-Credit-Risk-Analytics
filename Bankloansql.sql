
CREATE DATABASE LoanRiskAnalytics;
GO

USE LoanRiskAnalytics;
GO


CREATE TABLE stg_loan_applicants (
    customer_id            NVARCHAR(20),
    age                    NVARCHAR(10),
    gender                 NVARCHAR(10),
    employment_type        NVARCHAR(30),
    annual_income           NVARCHAR(20),
    credit_score            NVARCHAR(10),
    loan_amount             NVARCHAR(20),
    loan_tenure_months      NVARCHAR(10),
    existing_emi            NVARCHAR(20),
    debt_to_income_ratio    NVARCHAR(10),
    branch_region           NVARCHAR(30),
    loan_purpose             NVARCHAR(30),
    application_date        NVARCHAR(20),
    default_flag            NVARCHAR(5)
);
GO

SELECT COUNT(*) AS row_count FROM stg_loan_applicants;
SELECT TOP 10 * FROM stg_loan_applicants;



IF OBJECT_ID('fact_loan_applications', 'U') IS NOT NULL
    DROP TABLE fact_loan_applications;
GO

CREATE TABLE fact_loan_applications (
    customer_id             NVARCHAR(20) PRIMARY KEY,
    age                     INT,
    gender                  NVARCHAR(10),
    employment_type         NVARCHAR(30),
    annual_income            DECIMAL(12,2),
    credit_score             INT,
    loan_amount              DECIMAL(12,2),
    loan_tenure_months       INT,
    existing_emi             DECIMAL(10,2),
    debt_to_income_ratio     DECIMAL(5,2),
    branch_region            NVARCHAR(30),
    loan_purpose              NVARCHAR(30),
    application_date         DATE,
    default_flag              BIT,
    credit_band               NVARCHAR(20),
    risk_category             NVARCHAR(20)
);
GO

INSERT INTO fact_loan_applications
SELECT
    customer_id,
    CAST(age AS INT),
    gender,
    employment_type,
    CAST(annual_income AS DECIMAL(12,2)),
    CAST(credit_score AS INT),
    CAST(loan_amount AS DECIMAL(12,2)),
    CAST(loan_tenure_months AS INT),
    CAST(existing_emi AS DECIMAL(10,2)),
    CAST(debt_to_income_ratio AS DECIMAL(5,2)),
    branch_region,
    loan_purpose,
    CAST(application_date AS DATE),
    CAST(default_flag AS BIT),

    -- Credit band segmentation
    CASE
        WHEN CAST(credit_score AS INT) < 580 THEN 'Poor (300-580)'
        WHEN CAST(credit_score AS INT) < 670 THEN 'Fair (580-670)'
        WHEN CAST(credit_score AS INT) < 740 THEN 'Good (670-740)'
        ELSE 'Excellent (740-900)'
    END,

    -- Overall risk category (credit score + debt-to-income combined)
    CASE
        WHEN CAST(credit_score AS INT) < 580 OR CAST(debt_to_income_ratio AS DECIMAL(5,2)) > 0.45
            THEN 'High Risk'
        WHEN CAST(credit_score AS INT) < 670 OR CAST(debt_to_income_ratio AS DECIMAL(5,2)) > 0.30
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END
FROM stg_loan_applicants;
GO

SELECT COUNT(*) AS rows_inserted FROM fact_loan_applications;




-- Branch-wise default rate ranking (RANK)
SELECT
    branch_region,
    COUNT(*) AS total_applications,
    SUM(CAST(default_flag AS INT)) AS total_defaults,
    CAST(SUM(CAST(default_flag AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS default_rate_pct,
    RANK() OVER (ORDER BY SUM(CAST(default_flag AS INT)) * 1.0 / COUNT(*) DESC) AS risk_rank
FROM fact_loan_applications
GROUP BY branch_region
ORDER BY risk_rank;
GO

-- Running total of defaults over time (SUM OVER with ORDER BY)
SELECT
    application_date,
    SUM(CAST(default_flag AS INT)) AS daily_defaults,
    SUM(SUM(CAST(default_flag AS INT))) OVER (ORDER BY application_date) AS running_total_defaults
FROM fact_loan_applications
GROUP BY application_date
ORDER BY application_date;
GO

--  Customer risk quartile within their branch (NTILE)
SELECT
    customer_id,
    branch_region,
    credit_score,
    debt_to_income_ratio,
    risk_category,
    NTILE(4) OVER (PARTITION BY branch_region ORDER BY credit_score ASC) AS risk_quartile
FROM fact_loan_applications;
GO

IF OBJECT_ID('vw_loan_risk_summary', 'V') IS NOT NULL
    DROP VIEW vw_loan_risk_summary;
GO

CREATE VIEW vw_loan_risk_summary AS
SELECT
    customer_id, age, gender, employment_type, annual_income,
    credit_score, credit_band, loan_amount, loan_tenure_months,
    existing_emi, debt_to_income_ratio, branch_region, loan_purpose,
    application_date, default_flag, risk_category
FROM fact_loan_applications;
GO

SELECT * FROM vw_loan_risk_summary;
