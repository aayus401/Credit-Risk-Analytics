


-- ------------------------------------------------------------
-- Q1: Default rate by loan grade and home ownership
-- Technique: GROUP BY on multiple columns
-- Business question: Which combination of risk grade and
-- housing status carries the highest default risk?
-- ------------------------------------------------------------

SELECT
    loan_grade,
    person_home_ownership,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status)::numeric * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_grade, person_home_ownership
ORDER BY loan_grade, default_rate_pct DESC;


-- ------------------------------------------------------------
-- Q2: Which loan intent has the highest average interest rate
--     AND highest default rate simultaneously?
-- ------------------------------------------------------------
WITH intent_summary AS (
    SELECT
        loan_intent,
        COUNT(*) AS num_loans,
        ROUND(AVG(loan_int_rate)::numeric, 2) AS avg_interest_rate,
        ROUND(AVG(loan_status)::numeric * 100, 2) AS default_rate_pct
    FROM loans
    GROUP BY loan_intent
)
SELECT
    *,
    ROUND(default_rate_pct / NULLIF(avg_interest_rate, 0), 2) AS risk_per_rate_point
FROM intent_summary
ORDER BY risk_per_rate_point DESC;


-- ------------------------------------------------------------
-- Q3: How much riskier are customers with a prior default on
--     file, controlling for loan grade?
-- ------------------------------------------------------------
SELECT DISTINCT
    loan_grade,
    cb_person_default_on_file,
    ROUND(
        AVG(loan_status::numeric) OVER (
            PARTITION BY loan_grade, cb_person_default_on_file
        ) * 100, 2
    ) AS default_rate_pct,
    COUNT(*) OVER (
        PARTITION BY loan_grade, cb_person_default_on_file
    ) AS num_loans
FROM loans
ORDER BY loan_grade, cb_person_default_on_file;


-- ------------------------------------------------------------
-- Q4: Rank loan grades by portfolio exposure vs their default
--     rate - identify risk-concentration mismatches.
-- ------------------------------------------------------------
WITH grade_exposure AS (
    SELECT
        loan_grade,
        COUNT(*) AS num_loans,
        SUM(loan_amnt) AS total_exposure,
        ROUND(AVG(loan_status)::numeric * 100, 2) AS default_rate_pct
    FROM loans
    GROUP BY loan_grade
)
SELECT
    loan_grade,
    num_loans,
    total_exposure,
    default_rate_pct,
    RANK() OVER (ORDER BY total_exposure DESC) AS exposure_rank,
    RANK() OVER (ORDER BY default_rate_pct DESC) AS risk_rank
FROM grade_exposure
ORDER BY exposure_rank;


-- ------------------------------------------------------------
-- Q5: Default rate by income bracket, with running cumulative
--     share of total loans (rolling/cumulative calculation).

-- ------------------------------------------------------------
WITH income_summary AS (
    SELECT
        income_bracket,
        COUNT(*) AS num_loans,
        ROUND(AVG(loan_status)::numeric * 100, 2) AS default_rate_pct
    FROM loans
    GROUP BY income_bracket
)
SELECT
    income_bracket,
    num_loans,
    default_rate_pct,
    SUM(num_loans) OVER (ORDER BY default_rate_pct DESC) AS running_total_loans,
    ROUND(
        SUM(num_loans) OVER (ORDER BY default_rate_pct DESC)::numeric
        / SUM(num_loans) OVER () * 100, 2
    ) AS cumulative_pct_of_portfolio
FROM income_summary
ORDER BY default_rate_pct DESC;


-- ------------------------------------------------------------
-- Q6: Top 5% highest-risk loans by risk_score and loan amount -
--     candidates for manual underwriting review.
-- ------------------------------------------------------------
WITH risk_percentiles AS (
    SELECT
        person_age,
        person_income,
        loan_grade,
        loan_amnt,
        risk_score,
        loan_status,
        NTILE(20) OVER (ORDER BY risk_score DESC, loan_amnt DESC) AS percentile_bucket
    FROM loans
)
SELECT
    person_age,
    person_income,
    loan_grade,
    loan_amnt,
    risk_score,
    loan_status
FROM risk_percentiles
WHERE percentile_bucket = 1
ORDER BY risk_score DESC, loan_amnt DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q7: DTI bucket vs default rate - validate the underwriting-
--     standard debt-to-income bands against actual outcomes.

-- ------------------------------------------------------------
SELECT
    dti_bucket,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_percent_income)::numeric * 100, 2) AS avg_dti_pct,
    ROUND(AVG(loan_status)::numeric * 100, 2) AS default_rate_pct
FROM loans
GROUP BY dti_bucket
ORDER BY avg_dti_pct;


-- ------------------------------------------------------------
-- Q8: Which loan_intent x home_ownership segments (with a
--     meaningful sample size) default above the portfolio
--     average?

-- ------------------------------------------------------------
SELECT
    loan_intent,
    person_home_ownership,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status)::numeric * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_intent, person_home_ownership
HAVING COUNT(*) >= 100
   AND AVG(loan_status) > (SELECT AVG(loan_status) FROM loans)
ORDER BY default_rate_pct DESC;


-- ------------------------------------------------------------
-- Q9: Statistical correlation with default status, computed
--     natively in SQL (not just in pandas).
-- ------------------------------------------------------------
SELECT
    ROUND(CORR(loan_percent_income, loan_status)::numeric, 4) AS corr_dti_default,
    ROUND(CORR(loan_int_rate, loan_status)::numeric, 4) AS corr_intrate_default,
    ROUND(CORR(person_income, loan_status)::numeric, 4) AS corr_income_default,
    ROUND(CORR(cb_person_cred_hist_length, loan_status)::numeric, 4) AS corr_credhist_default
FROM loans;


-- ------------------------------------------------------------
-- Q10: Create a reusable view for Power BI to connect to,
--      instead of querying the raw table directly.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_risk_summary;

CREATE VIEW vw_risk_summary AS
SELECT
    loan_grade,
    loan_intent,
    person_home_ownership,
    dti_bucket,
    income_bracket,
    credit_history_bucket,
    risk_tier,
    risk_score,
    loan_amnt,
    loan_int_rate,
    loan_percent_income,
    loan_status
FROM loans;

-- Power BI connects to vw_risk_summary, not the raw 'loans' table.

select * from [dbo].[Loan_default]