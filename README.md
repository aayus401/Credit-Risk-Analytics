# Credit Risk Analytics — Loan Default Analytics for Lending Decisioning

An end-to-end data analytics project that analyzes a portfolio of **31,522 loan applications** to answer a practical lending question: *which borrower and loan characteristics actually predict default, and is the current interest-rate pricing risk-adjusted?*

The project moves through the full analytics stack — data cleaning and EDA in Python, feature engineering, SQL-based business analysis in PostgreSQL, and an interactive Power BI dashboard — and ends with specific, numbers-backed underwriting recommendations.

## Table of Contents
- [Business Problem](#business-problem)
- [Dataset](#dataset)
- [Project Workflow](#project-workflow)
- [Repository Structure](#repository-structure)
- [Key Findings](#key-findings)
- [Power BI Dashboard](#power-bi-dashboard)
- [Business Recommendations](#business-recommendations)
- [Tech Stack](#tech-stack)
- [How to Reproduce](#how-to-reproduce)

## Business Problem

Lending institutions approve loans using credit bureau data, income verification, and an internal risk grade — then carry that risk on their books until the loan is repaid or defaults. Undetected mispricing of risk compounds into major losses; overly conservative underwriting turns away good borrowers. This project investigates three sub-problems:

1. **Risk concentration** — is portfolio dollar exposure concentrated in the segments that are actually highest-risk?
2. **Pricing accuracy** — do riskier loan purposes and borrower profiles carry appropriately higher interest rates?
3. **Underwriting signal quality** — which borrower attributes genuinely predict default, and which commonly-assumed risk factors don't hold up once tested?

Full write-up: [`Problem&Report/problem_statement.pdf`](Problem&Report/problem_statement.pdf)

## Dataset

- **Source:** Credit Risk Dataset (Kaggle, public)
- **Raw size:** 32,581 rows × 12 columns, one row per loan application
- **Cleaned size:** 31,522 rows (902 rows removed for biologically impossible age/employment combinations, 157 duplicates dropped)
- **Target variable:** `loan_status` (0 = no default, 1 = default)

| Category | Columns |
|---|---|
| Borrower demographics | `person_age`, `person_income`, `person_home_ownership`, `person_emp_length` |
| Loan details | `loan_intent`, `loan_grade`, `loan_amnt`, `loan_int_rate`, `loan_percent_income` |
| Credit bureau history | `cb_person_default_on_file`, `cb_person_cred_hist_length` |
| Outcome | `loan_status` |

**Missing data:** `loan_int_rate` was missing in 9.56% of rows (missingness varied by grade, so it was imputed with the median *within each grade*); `person_emp_length` was missing in 2.75% of rows and imputed with the overall median.

## Project Workflow

**1. Data Cleaning** — [`notebooks/Data Cleaning.ipynb`](notebooks/Data%20Cleaning.ipynb)
Loaded and profiled the raw data, quantified missingness as a percentage of total rows before choosing an imputation strategy, removed biologically impossible records (e.g. employment length exceeding age minus 14), checked income outliers with the IQR method (retained — high earners are plausible applicants), dropped exact duplicates, and ran final validation checks before exporting `cleaned_loans.csv`.

**2. Exploratory Data Analysis** — [`notebooks/Exploratory Data Analysis.ipynb`](notebooks/Exploratory%20Data%20Analysis.ipynb)
Univariate distributions for all numeric and categorical features, default rate breakdowns by grade / home ownership / loan intent / prior default history, a correlation heatmap, and chi-square significance tests to confirm which categorical relationships with default are statistically real rather than noise.

**3. Feature Engineering** — [`notebooks/Feature Engineering.ipynb`](notebooks/Feature%20Engineering.ipynb)
Built seven new features on top of the cleaned data: `risk_tier`, `dti_bucket`, `is_renter_or_other`, `credit_history_bucket`, `high_risk_intent`, `income_bracket`, and a composite `risk_score` (0–4). Every threshold was chosen from a pattern confirmed during EDA rather than picked arbitrarily, and the composite score was validated against real default rates before being used downstream. Exported as `loans_features.csv` and loaded into PostgreSQL via SQLAlchemy.

**4. SQL Analysis** — [`Sql/analysis_queries.sql`](Sql/analysis_queries.sql)
Ten business questions answered in PostgreSQL using GROUP BY aggregation, CTEs, window functions (`AVG() OVER`, `RANK()`, `NTILE()`), `HAVING` filters, and native statistical functions (`CORR()`), ending in a reusable `vw_risk_summary` view for the dashboard to connect to.

**5. Power BI Dashboard** — [`Powerbi/credit_risk_dashboard.pbix`](Powerbi/credit_risk_dashboard.pbix)
A four-page interactive dashboard connected directly to the PostgreSQL view for stakeholder-facing exploration.

## Repository Structure

```
Credit-Risk-Analytics/
├── data/
│   ├── credit_risk_dataset.csv     # Raw data (32,581 rows)
│   ├── cleaned_loans.csv           # After cleaning (31,522 rows)
│   └── loans_features.csv          # After feature engineering (31,522 rows, 19 columns)
├── notebooks/
│   ├── Data Cleaning.ipynb
│   ├── Exploratory Data Analysis.ipynb
│   └── Feature Engineering.ipynb
├── Sql/
│   └── analysis_queries.sql        # 10 business-question queries + BI view
├── Powerbi/
│   └── credit_risk_dashboard.pbix  # 4-page interactive dashboard
├── Problem&Report/
│   ├── problem_statement.pdf       # Business context, scope, objectives
│   └── Credit_Risk_Analytics_Report .pdf   # Full findings & recommendations
└── README.md
```

## Key Findings

- **Default rate climbs sharply by grade:** from 9.56% (Grade A) to 98.44% (Grade G), with the steepest jump between Grade C (20.31%) and Grade D (58.78%).
- **Home ownership matters even within a grade:** in Grade A alone, renters default at 16.94% vs. 4.04% for mortgage holders — a 4x gap that grade alone doesn't capture.
- **Pricing is not risk-adjusted by loan purpose:** interest rates are flat around 11% across all loan intents, despite default rates ranging from 14.70% (venture) to 28.45% (debt consolidation).
- **Prior default history is largely a Simpson's Paradox:** raw comparison shows prior defaulters defaulting at 37.6% vs. 18.1%, but once loan grade is held constant the gap nearly disappears (e.g. within Grade D: 59.8% vs. 57.7%) — grade already absorbs most of that signal.
- **Grade B carries the most dollar exposure** ($101.9M) while only ranking 6th out of 7 in default risk — most portfolio capital sits in comparatively safer grades.
- **A 35% DTI cutoff is a defensible hard rule:** default rate jumps from 28.74% to 71.09% the moment loan-to-income crosses 35% — the sharpest single cliff in the data.
- **Credit history length is essentially uncorrelated with default** (Pearson r = -0.0178), confirmed independently in both the Python EDA and native SQL `CORR()` — despite being commonly assumed to matter.
- **The engineered composite `risk_score` (0–4) separates risk 16x** from lowest to highest tier: 5.0% default at score 0 vs. 83.9% at score 4, without needing a black-box model.

Full findings with tables and charts: [`Problem&Report/Credit_Risk_Analytics_Report .pdf`](Problem&Report/Credit_Risk_Analytics_Report%20.pdf)

## Power BI Dashboard

| Page | Contents |
|---|---|
| **Portfolio Overview** | KPI cards (Total Loans, Total Exposure, Default Rate %, Avg Interest Rate), default rate by grade, portfolio split by risk tier |
| **Risk Segmentation** | Default rate matrix (grade × home ownership), default rate by loan intent, default rate by DTI bucket, with slicers for grade / home ownership / loan intent |
| **Borrower Deep Dive** | Income vs. loan amount scatter (colored by default status), default rate by income bracket, default rate by credit history bucket |
| **Underwriting Recommendations** | Total vs. high-risk exposure KPIs ($304.62M vs. $56M, 18.4%), ranked shortlist of highest-risk loans, risk-score slicer, written recommendation summary |

## Business Recommendations

1. **Tighten approval criteria for Grade D+ applicants** — default rate nearly triples from Grade C to Grade D, and $56M (18.4%) of the $304.62M portfolio already sits in Grade D–G.
2. **Reprice loans by purpose, not just by grade** — interest rates are flat (~11%) despite a 2x gap in default rate between the riskiest and safest loan purposes.
3. **Apply a hard DTI cutoff at 35%** — the sharpest single risk cliff identified in the analysis.
4. **Deprioritize credit history length as an underwriting factor** — correlation with default is effectively zero; grade and DTI are far stronger, evidence-backed signals.

## Tech Stack

- **Python:** pandas, NumPy, Matplotlib, Seaborn, SciPy (`scipy.stats` for chi-square testing)
- **Database:** PostgreSQL, SQLAlchemy (for loading the DataFrame into SQL)
- **SQL techniques:** CTEs, window functions (`AVG() OVER`, `RANK()`, `NTILE()`), `HAVING`, native correlation (`CORR()`), views
- **BI / Visualization:** Power BI (4-page interactive dashboard)
- **Environment:** Jupyter Notebook

## How to Reproduce

1. Clone the repo and open the notebooks in order: `Data Cleaning.ipynb` → `Exploratory Data Analysis.ipynb` → `Feature Engineering.ipynb`.
2. Install dependencies: `pip install pandas numpy matplotlib seaborn scipy sqlalchemy psycopg2-binary`.
3. Set up a local PostgreSQL instance and update the connection credentials in the feature engineering notebook (**do not commit real credentials** — use environment variables or a `.env` file instead).
4. Run [`Sql/analysis_queries.sql`](Sql/analysis_queries.sql) against the loaded `loans` table to reproduce the business-question analysis and create `vw_risk_summary`.
5. Open [`Powerbi/credit_risk_dashboard.pbix`](Powerbi/credit_risk_dashboard.pbix) in Power BI Desktop and point the data source at `vw_risk_summary`.

---
**Author:** [Aayush](https://github.com/aayus401)
