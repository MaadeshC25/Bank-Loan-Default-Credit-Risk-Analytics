"""
Bank Loan Default & Credit Risk Analytics
Step 1-2: Synthetic Data Generation with Realistic Correlations
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta

np.random.seed(42)  

N = 7000  #number of loan applicants

#Step 1: Base attributes 

customer_id = [f"CUST{100000+i}" for i in range(N)]

age = np.random.randint(21, 65, N)

gender = np.random.choice(['Male', 'Female'], N, p=[0.58, 0.42])

employment_type = np.random.choice(
    ['Salaried', 'Self-Employed', 'Business'],
    N, p=[0.55, 0.25, 0.20]
)

branch_region = np.random.choice(
    ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Pondicherry', 'Salem'],
    N, p=[0.30, 0.18, 0.15, 0.12, 0.15, 0.10]
)

loan_purpose = np.random.choice(
    ['Home', 'Personal', 'Vehicle', 'Business Expansion', 'Education'],
    N, p=[0.30, 0.25, 0.20, 0.15, 0.10]
)

# Income depends loosely on employment type (business owners have wider spread)
income_base = {
    'Salaried': (35000, 90000),
    'Self-Employed': (25000, 120000),
    'Business': (30000, 150000)
}
annual_income = np.array([
    np.random.randint(*income_base[e]) * 12 // 1000 * 1000
    for e in employment_type
])

# Credit score: normal distribution, slightly lower for self-employed (real-world tendency)
credit_score = np.random.normal(650, 90, N)
credit_score = credit_score - np.where(employment_type == 'Self-Employed', 25, 0)
credit_score = np.clip(credit_score, 300, 900).astype(int)

loan_amount = (np.random.randint(50, 2000, N) * 1000)
loan_tenure_months = np.random.choice([12, 24, 36, 48, 60, 84, 120], N)

existing_emi = (annual_income / 12 * np.random.uniform(0.05, 0.35, N)).astype(int)
monthly_income = annual_income / 12
debt_to_income_ratio = np.round(existing_emi / monthly_income, 2)

# Application dates spread across last 24 months
start_date = datetime(2024, 8, 1)
application_date = [start_date + timedelta(days=int(x)) for x in np.random.randint(0, 730, N)]

#  Step 2: Default probability logic (the "correlation engine") 
# This is the core logic that makes the dataset realistic instead of random.

risk_score = (
    (900 - credit_score) / 600 * 0.45 +          # lower credit score -> higher risk
    debt_to_income_ratio * 0.35 +                 # higher DTI -> higher risk
    np.where(employment_type == 'Self-Employed', 0.10, 0) +
    np.where(employment_type == 'Business', 0.05, 0) +
    np.where(loan_amount > 1000000, 0.08, 0) +     # large loans slightly riskier
    np.random.normal(0, 0.08, N)                   # noise so it's not deterministic
)

default_prob = 1 / (1 + np.exp(-6 * (risk_score - 0.55)))  # logistic squashing
default_flag = (np.random.rand(N) < default_prob).astype(int)

# ---------- Assemble dataframe ----------

df = pd.DataFrame({
    'customer_id': customer_id,
    'age': age,
    'gender': gender,
    'employment_type': employment_type,
    'annual_income': annual_income,
    'credit_score': credit_score,
    'loan_amount': loan_amount,
    'loan_tenure_months': loan_tenure_months,
    'existing_emi': existing_emi,
    'debt_to_income_ratio': debt_to_income_ratio,
    'branch_region': branch_region,
    'loan_purpose': loan_purpose,
    'application_date': [d.strftime('%Y-%m-%d') for d in application_date],
    'default_flag': default_flag
})

# Quick sanity check prints (for us to verify correlation worked)
print("Total records:", len(df))
print("\nOverall default rate: {:.2f}%".format(df['default_flag'].mean() * 100))

print("\nDefault rate by credit score band:")
df['credit_band'] = pd.cut(df['credit_score'], bins=[300, 580, 670, 740, 900],
                            labels=['Poor(300-580)', 'Fair(580-670)', 'Good(670-740)', 'Excellent(740-900)'])
print(df.groupby('credit_band', observed=True)['default_flag'].mean().mul(100).round(2))

print("\nDefault rate by employment type:")
print(df.groupby('employment_type')['default_flag'].mean().mul(100).round(2))

df = df.drop(columns=['credit_band'])  # drop helper column before export

# ---------- Export ----------
output_path = 'loan_applicant_data.csv'
df.to_csv(output_path, index=False)
print(f"\nSaved to {output_path}")
