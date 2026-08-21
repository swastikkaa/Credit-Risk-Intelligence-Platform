-- Credit Risk Intelligence Platform
-- SQL Setup
-- Database: MySQL 8+
--
-- This script creates the database and loans table.
-- The raw dataset is intentionally NOT included in the repository.
-- Update the LOCAL INFILE path below when running locally.

CREATE DATABASE IF NOT EXISTS credit_risk;
USE credit_risk;

DROP TABLE IF EXISTS loans;

CREATE TABLE loans (
    id BIGINT PRIMARY KEY,
    issue_d VARCHAR(20),
    revenue DECIMAL(12, 2),
    dti_n DECIMAL(8, 2),
    loan_amnt INT,
    fico_n INT,
    experience_c TINYINT,
    emp_length VARCHAR(20),
    purpose VARCHAR(50),
    home_ownership_n VARCHAR(30),
    addr_state VARCHAR(5),
    zip_code VARCHAR(10),
    `Default` TINYINT,
    title VARCHAR(255),
    `desc` TEXT
);

-- Load the dataset locally.
-- Requires LOCAL INFILE to be enabled in MySQL.
--
-- LOAD DATA LOCAL INFILE 'PATH_TO_DATASET/LC_loans_granting_model_dataset.csv'
-- INTO TABLE loans
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 LINES;

-- Verify that the data loaded correctly.
SELECT COUNT(*) AS total_loans
FROM loans;
