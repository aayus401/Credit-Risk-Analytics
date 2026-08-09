


-- ------------------------------------------------------------
-- Q1: Default rate by loan grade and home ownership
-- Business question: Which combination of risk grade and
-- housing status carries the highest default risk?
-- ------------------------------------------------------------

SELECT
    loan_grade,
    person_home_ownership,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_grade, person_home_ownership
ORDER BY loan_grade, default_rate_pct DESC;


-- ------------------------------------------------------------
-- Q2: Which loan intent has the highest average interest rate
--     AND highest default rate at the same time?
-- ------------------------------------------------------------

SELECT
    loan_intent,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_intent
ORDER BY default_rate_pct DESC, avg_interest_rate DESC;


-- ------------------------------------------------------------
-- Q3: How much riskier are customers who already have a prior
--     default on file, for each loan grade?
-- ------------------------------------------------------------

SELECT
    loan_grade,
    cb_person_default_on_file,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_grade, cb_person_default_on_file
ORDER BY loan_grade, cb_person_default_on_file;


-- ------------------------------------------------------------
-- Q4: Compare how many loans / how much money is given out per
--     loan grade (exposure) vs. how risky that grade actually is.
-- ------------------------------------------------------------

SELECT
    loan_grade,
    COUNT(*) AS num_loans,
    SUM(loan_amnt) AS total_exposure,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_grade
ORDER BY total_exposure DESC;



-- ------------------------------------------------------------
-- Q5: Default rate by income bracket.
-- ------------------------------------------------------------

SELECT
    income_bracket,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY income_bracket
ORDER BY default_rate_pct DESC;


-- ------------------------------------------------------------
-- Q6: Top 20 highest-risk loans (highest risk_score, then
--     highest loan amount) - candidates for manual review.
-- ------------------------------------------------------------

SELECT
    person_age,
    person_income,
    loan_grade,
    loan_amnt,
    risk_score,
    loan_status
FROM loans
ORDER BY risk_score DESC, loan_amnt DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q7: Debt-to-income (DTI) bucket vs default rate - check if
--     higher DTI really means higher default rate.
-- ------------------------------------------------------------

SELECT
    dti_bucket,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_percent_income) * 100, 2) AS avg_dti_pct,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY dti_bucket
ORDER BY avg_dti_pct;


-- ------------------------------------------------------------
-- Q8: Which loan_intent + home_ownership groups (with at least
--     100 loans, so the sample is meaningful) default MORE than
--     the overall average default rate?
-- ------------------------------------------------------------

SELECT
    loan_intent,
    person_home_ownership,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY loan_intent, person_home_ownership
HAVING COUNT(*) >= 100
   AND AVG(loan_status) > (SELECT AVG(loan_status) FROM loans)
ORDER BY default_rate_pct DESC;


-- ------------------------------------------------------------
-- Q9: Simple check - average default rate for people ABOVE vs
--     BELOW average credit history length (an easy stand-in
--     for a full correlation calculation).
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN cb_person_cred_hist_length >= (SELECT AVG(cb_person_cred_hist_length) FROM loans)
            THEN 'Above average credit history'
        ELSE 'Below average credit history'
    END AS credit_history_group,
    COUNT(*) AS num_loans,
    ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct
FROM loans
GROUP BY credit_history_group;