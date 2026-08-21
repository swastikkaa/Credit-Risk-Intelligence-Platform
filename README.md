# Credit Risk Intelligence Platform

Turning 1.35M+ loan records into decision-useful credit risk intelligence — from SQL-based portfolio analytics through a scored ML model to a financial-impact dashboard.

🔗 **[Live Tableau Dashboard](https://public.tableau.com/app/profile/swastika.singh/viz/CreditRiskIntelligenceplatform/Dashboard1)**

![Financial Impact Dashboard]<img width="1140" height="772" alt="image" src="https://github.com/user-attachments/assets/5e7f85e0-1fb2-43f8-b081-7c7e1054551d" />


## Why this project

Inspired by *[Credit Meets LLM: Building a Risk Indicator from Loan Descriptions in P2P Lending]([Reasearch paper.pdf](https://github.com/user-attachments/files/31297804/Reasearch.paper.pdf)
)*, which explores whether unstructured loan-description text carries default signal beyond hard credit variables. I used it as a starting question rather than a blueprint — the pipeline here is SQL-driven EDA + a structured-feature XGBoost model, with the paper's premise tested (not assumed) as a side experiment. See [Findings](#key-findings) below for what that test actually showed.

## Project structure
├── sql/ # Portfolio EDA & risk segmentation queries
├── notebooks/
│ └── crip_ML.ipynb # Modeling pipeline: preprocessing, XGBoost, threshold tuning, text experiment
├── docs/
│ └── Credit_Risk_Intelligence_SQL_Findings.docx
└── README.md

## Data

1.35M+ loan records, $19.42B total exposure.

## Pipeline

**1. SQL — Portfolio EDA & Risk Segmentation**
Queried the loan portfolio to establish baseline risk and find the strongest risk-differentiating variable combination.

**2. Feature Engineering**
Built a train-only target-encoded FICO×DTI risk feature based on the SQL finding, plus a standard preprocessing pipeline (imputation, scaling, one-hot encoding).

**3. Modeling — XGBoost**
Binary default classifier with `scale_pos_weight=4.0` to handle class imbalance (19.98% base rate). Threshold tuned against the loan portfolio's actual loss economics rather than default 0.5 cutoff assumptions — see Findings.

**4. Financial Impact Translation**
Converted model outputs into dollar terms (savings, opportunity cost, portfolio loss reduction) for a business-facing dashboard.

**5. Dashboard — Tableau Public**
Three-part story: portfolio risk segmentation → model diagnostics → financial impact.

## Key Findings

**Portfolio risk segmentation (SQL EDA)**
FICO × DTI is the strongest risk-differentiating combination in the dataset — default rates span **5.81%** (Excellent FICO + Low DTI) to **39.44%** (Fair FICO + Very High DTI), against a 19.98% baseline. Notably, the highest-risk segment is only 0.08% of total portfolio exposure, while the largest concentration of capital (54.52%, $10.58B) sits in Good FICO + Low/Moderate DTI — a moderate-risk, high-volume zone that matters more for total dollar exposure than the extreme-risk tail does.

**Model performance**
XGBoost — Precision 0.296, Recall 0.645, F1 0.406, ROC-AUC 0.682 — using only application-time features (no bureau trade-line history, no post-origination behavior). Threshold set at 0.5 rather than a higher-precision cutoff: at 0.80 threshold, precision rises to 0.57 but recall collapses to 0.02. Given LGD (70%) is ~7x the interest margin (10%) on a performing loan, missing a default is far more costly than over-declining — so the threshold was chosen to maximize dollar impact, not headline accuracy metrics.

**Financial impact**
At the chosen threshold: **$413.9M in default losses avoided**, **$135.6M in opportunity cost** (interest missed from declined applicants who wouldn't have defaulted), netting **$278.2M in savings** and a **47.41% reduction in portfolio loss** on the test set.

**Did the SQL-derived feature actually help the model?**
Tested XGBoost with and without the SQL-derived FICO×DTI target-encoded feature — **no measurable difference in ROC-AUC or F1.** Tree-based models recover this interaction natively through splits, making the engineered feature redundant for predictive lift. Its actual value was **interpretability and governance** — an auditable, SQL-traceable justification for the interaction, independent of what the model's internal splits were doing. This is a genuinely useful distinction for regulated lending contexts, where explainability often matters as much as raw performance.

**Does loan-description text add standalone signal?**
Tested a TF-IDF + Logistic Regression model on loan description text alone: **ROC-AUC 0.58**, notably below the 0.68 from structured features. On this dataset, hard credit variables (FICO, DTI, loan terms) dominate; text may still add marginal value *combined* with structured features, but doesn't stand on its own as a primary signal here — a more modest result than the inspiring paper's core premise, and worth noting as a real (not assumed) finding.

## Stack

Python — pandas, scikit-learn (imputation, scaling, one-hot encoding pipeline), XGBoost, TF-IDF/Logistic Regression (text experiment) · SQL · Tableau Public

## Limitations & Next Steps

- Compare `scale_pos_weight` vs. SMOTE resampling for imbalance handling
- Test a combined text + structured feature model
- No bureau/trade-line or macro data available — future work if extended

## Author

Swastika Singh — Linkden[https://www.linkedin.com/in/swastika-singh-77303a33a/] 
