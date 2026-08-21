-- Credit Risk Intelligence Platform
-- Risk Segmentation & FICO × DTI Analysis
-- Purpose: Quantify the interaction between borrower credit quality
-- and debt burden identified during portfolio EDA.

USE credit_risk;

-- ============================================================
-- 1. FICO × DTI SEGMENTATION
-- ============================================================

-- Basic segment counts.
SELECT
    CASE
        WHEN fico_n < 580 THEN 'Very Low'
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
    CASE
        WHEN dti_n < 10 THEN 'Very Low'
        WHEN dti_n < 20 THEN 'Low'
        WHEN dti_n < 30 THEN 'Moderate'
        WHEN dti_n < 40 THEN 'High'
        WHEN dti_n >= 40 THEN 'Very High'
        ELSE 'Unknown'
    END AS dti_band,
    COUNT(*) AS total_loans
FROM loans
GROUP BY fico_band, dti_band
ORDER BY fico_band, dti_band;


-- Full FICO × DTI risk table.
SELECT
    CASE
        WHEN fico_n < 580 THEN 'Very Low'
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
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
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END) AS defaulted_exposure
FROM loans
GROUP BY fico_band, dti_band
ORDER BY default_rate DESC;


-- ============================================================
-- 2. STABLE SEGMENTS FOR DASHBOARD ANALYSIS
-- ============================================================

-- Exclude very small segments from the heatmap.
SELECT
    CASE
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
    CASE
        WHEN dti_n < 10 THEN 'Very Low'
        WHEN dti_n < 20 THEN 'Low'
        WHEN dti_n < 30 THEN 'Moderate'
        WHEN dti_n < 40 THEN 'High'
        WHEN dti_n >= 40 THEN 'Very High'
        ELSE 'Unknown'
    END AS dti_band,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END) AS defaulted_exposure
FROM loans
GROUP BY fico_band, dti_band
HAVING COUNT(*) >= 1000
ORDER BY default_rate DESC;


-- ============================================================
-- 3. SEGMENT EXPOSURE SHARE
-- ============================================================

SELECT
    CASE
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
    CASE
        WHEN dti_n < 10 THEN 'Very Low'
        WHEN dti_n < 20 THEN 'Low'
        WHEN dti_n < 30 THEN 'Moderate'
        WHEN dti_n < 40 THEN 'High'
        WHEN dti_n >= 40 THEN 'Very High'
        ELSE 'Unknown'
    END AS dti_band,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(loan_amnt) / (SELECT SUM(loan_amnt) FROM loans),
        2
    ) AS portfolio_exposure_pct,
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END) AS defaulted_exposure
FROM loans
GROUP BY fico_band, dti_band
HAVING COUNT(*) >= 1000
ORDER BY portfolio_exposure_pct DESC;


-- ============================================================
-- 4. DEFAULTED EXPOSURE BY SEGMENT
-- ============================================================

SELECT
    CASE
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
    CASE
        WHEN dti_n < 10 THEN 'Very Low'
        WHEN dti_n < 20 THEN 'Low'
        WHEN dti_n < 30 THEN 'Moderate'
        WHEN dti_n < 40 THEN 'High'
        WHEN dti_n >= 40 THEN 'Very High'
        ELSE 'Unknown'
    END AS dti_band,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(
            CASE WHEN `Default` = 1 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS default_rate,
    ROUND(
        100.0 * SUM(loan_amnt) / (SELECT SUM(loan_amnt) FROM loans),
        2
    ) AS portfolio_exposure_pct,
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END) AS defaulted_exposure
FROM loans
GROUP BY fico_band, dti_band
HAVING COUNT(*) >= 1000
ORDER BY defaulted_exposure DESC;


-- ============================================================
-- 5. RISK RELATIVE TO PORTFOLIO BASELINE
-- ============================================================

SELECT
    CASE
        WHEN fico_n BETWEEN 580 AND 669 THEN 'Fair'
        WHEN fico_n BETWEEN 670 AND 739 THEN 'Good'
        WHEN fico_n BETWEEN 740 AND 799 THEN 'Very Good'
        WHEN fico_n >= 800 THEN 'Excellent'
        ELSE 'Unknown'
    END AS fico_band,
    CASE
        WHEN dti_n < 10 THEN 'Very Low'
        WHEN dti_n < 20 THEN 'Low'
        WHEN dti_n < 30 THEN 'Moderate'
        WHEN dti_n < 40 THEN 'High'
        WHEN dti_n >= 40 THEN 'Very High'
        ELSE 'Unknown'
    END AS dti_band,
    COUNT(*) AS total_loans,
    ROUND(
        100.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS default_rate,
    ROUND(
        (
            1.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END) / COUNT(*)
        ) / (
            SELECT
                1.0 * SUM(CASE WHEN `Default` = 1 THEN 1 ELSE 0 END)
                / COUNT(*)
            FROM loans
        ),
        2
    ) AS risk_vs_portfolio,
    ROUND(
        100.0 * SUM(loan_amnt) / (SELECT SUM(loan_amnt) FROM loans),
        2
    ) AS portfolio_exposure_pct,
    SUM(loan_amnt) AS total_exposure,
    SUM(CASE WHEN `Default` = 1 THEN loan_amnt ELSE 0 END) AS defaulted_exposure
FROM loans
GROUP BY fico_band, dti_band
HAVING COUNT(*) >= 1000
ORDER BY risk_vs_portfolio DESC;
