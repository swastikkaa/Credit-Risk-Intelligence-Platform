-- Credit Risk Intelligence Platform
-- Portfolio EDA
-- Purpose: Understand default risk, exposure and portfolio concentration
-- before applying machine learning.

USE credit_risk;

-- ============================================================
-- 1. PORTFOLIO BASELINE
-- ============================================================

SELECT
    COUNT(*) AS total_loans,
    SUM(loan_amnt) AS total_loan_exposure,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS overall_default_rate
FROM loans;


-- ============================================================
-- 2. PURPOSE RISK & EXPOSURE
-- ============================================================

-- Default rate and exposure by loan purpose.
SELECT
    purpose,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY purpose
ORDER BY default_rate DESC;

-- Purpose categories with both above-baseline default rates
-- and material portfolio exposure.
WITH portfolio AS (
    SELECT
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*) AS baseline_default_rate
    FROM loans
)
SELECT
    purpose,
    COUNT(*) AS total_loans,
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate
FROM loans
CROSS JOIN portfolio
GROUP BY purpose
HAVING default_rate > baseline_default_rate
   AND total_exposure > 100000000
ORDER BY total_exposure DESC;

-- Defaulted exposure by purpose.
SELECT
    purpose,
    COUNT(*) AS total_loans,
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END) AS defaulted_exposure,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END)
        / SUM(loan_amnt),
        2
    ) AS defaulted_exposure_pct
FROM loans
GROUP BY purpose
ORDER BY defaulted_exposure DESC;


-- ============================================================
-- 3. FICO RISK
-- ============================================================

SELECT
    CASE
        WHEN fico_n < 580 THEN 'Very Low'
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY fico_band
ORDER BY default_rate DESC;


-- ============================================================
-- 4. DTI RISK
-- ============================================================

SELECT
    CASE
        WHEN dti_n < 10 THEN 'Very Low'
        WHEN dti_n < 20 THEN 'Low'
        WHEN dti_n < 30 THEN 'Moderate'
        WHEN dti_n < 40 THEN 'High'
        WHEN dti_n >= 40 THEN 'Very High'
        ELSE 'Unknown'
    END AS dti_band,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY dti_band
ORDER BY default_rate DESC;


-- ============================================================
-- 5. LOAN SIZE RISK
-- ============================================================

SELECT
    CASE
        WHEN loan_amnt < 5000 THEN 'Under 5K'
        WHEN loan_amnt < 10000 THEN '5K-10K'
        WHEN loan_amnt < 15000 THEN '10K-15K'
        WHEN loan_amnt < 20000 THEN '15K-20K'
        WHEN loan_amnt >= 20000 THEN '20K+'
        ELSE 'Unknown'
    END AS loan_size_band,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY loan_size_band
ORDER BY default_rate DESC;


-- ============================================================
-- 6. EMPLOYMENT & HOME OWNERSHIP
-- ============================================================

SELECT
    emp_length,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY emp_length
ORDER BY default_rate DESC;

SELECT
    home_ownership_n,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY home_ownership_n
ORDER BY default_rate DESC;


-- ============================================================
-- 7. GEOGRAPHIC RISK
-- ============================================================

SELECT
    addr_state,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY addr_state
ORDER BY default_rate DESC;

-- State-level risk ranking, restricted to states with
-- at least 5,000 loans to avoid unstable small-sample rankings.
WITH state_risk AS (
    SELECT
        addr_state,
        COUNT(*) AS total_loans,
        SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
        ROUND(
            100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS default_rate,
        SUM(loan_amnt) AS total_exposure
    FROM loans
    GROUP BY addr_state
    HAVING COUNT(*) >= 5000
)
SELECT
    addr_state,
    total_loans,
    defaulted_loans,
    default_rate,
    total_exposure,
    RANK() OVER (ORDER BY default_rate DESC) AS risk_rank
FROM state_risk
ORDER BY risk_rank;


-- ============================================================
-- 8. TIME TRENDS
-- ============================================================

SELECT
    STR_TO_DATE(issue_d, '%b-%Y') AS issue_month,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY issue_month
ORDER BY issue_month;

SELECT
    RIGHT(issue_d, 4) AS issue_year,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure
FROM loans
GROUP BY issue_year
ORDER BY issue_year;
