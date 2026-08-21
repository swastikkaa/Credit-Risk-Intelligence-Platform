# Credit Risk Intelligence Platform

An end-to-end credit risk analytics platform combining **SQL, machine learning, research-driven experimentation, and financial impact modelling** to evaluate loan default risk and translate predictions into lending decisions.

## 🔗 Interactive Dashboard

**[View the Credit Risk Intelligence Platform on Tableau Public](https://public.tableau.com/views/CreditRiskIntelligenceplatform/Dashboard1?:language=en-GB&:sid=&:display_count=n&:origin=viz_share_link)**

---

## 📌 Project Overview

I analyzed a portfolio of **1.35M loans** to investigate where default risk is concentrated, build a predictive default model, and quantify the financial impact of risk-based lending decisions.

The project follows three stages:

**Portfolio Intelligence → Predictive Modelling → Financial Impact**

### 1. Portfolio Risk Analysis

I used SQL-based exploratory analysis to identify the strongest risk patterns across borrower and loan characteristics.

The key finding was the interaction between **FICO score and Debt-to-Income ratio (DTI)**. Default rates ranged from **5.81% to 39.44%** across the FICO × DTI segments, revealing a substantially sharper risk gradient than either variable alone.

### 2. Machine Learning

I built an **XGBoost binary classification model** to predict loan default using application-time borrower and loan characteristics.

The final model achieved:

| Metric | Result |
|---|---:|
| ROC-AUC | **0.682** |
| Recall | **0.645** |
| F1 Score | **0.406** |
| Baseline Default Rate | **19.98%** |

I selected the operating threshold based on the financial consequences of lending decisions rather than optimising a single classification metric.

### 3. Financial Impact

I translated model predictions into portfolio-level financial outcomes.

| Financial Metric | Result |
|---|---:|
| Default Loss Saved | **$413.9M** |
| Opportunity Cost | **$135.6M** |
| Net Dollar Savings | **$278.2M** |
| Portfolio Loss Reduction | **47.41%** |

---

## 🔬 Research-Inspired Experiment

Inspired by *Credit Meets LLM: Building a Risk Indicator from Loan Descriptions in P2P Lending*, I tested whether unstructured loan descriptions carried standalone default signal on this dataset.

A **TF-IDF + Logistic Regression** text-only model achieved **0.58 ROC-AUC**, below the **0.68 ROC-AUC** achieved using structured borrower and loan features alone.

This suggests that hard credit variables such as **FICO, DTI and loan characteristics** dominate the predictive signal in this dataset, while text may still be worth testing as an additional feature source.

---

## 🧠 SQL → ML Connection

The SQL EDA directly informed the machine learning workflow.

I tested a **train-only target-encoded FICO × DTI risk feature** derived from the SQL risk segmentation analysis. Adding the feature produced no measurable improvement in ROC-AUC or F1, suggesting that the tree-based model was already recovering the interaction through its splits.

The experiment was still useful from an **interpretability and governance** perspective because it provided an auditable connection between the SQL analysis and model features.

---

## 🛠️ Tech Stack

**Languages & Analysis**
- Python
- SQL

**Machine Learning**
- XGBoost
- scikit-learn
- TF-IDF
- Logistic Regression

**Data**
- pandas
- NumPy

**Visualisation & BI**
- Tableau Public
- Matplotlib

---

## 📁 Repository Structure

Credit-Risk-Intelligence-Platform/
│
├── SQL/
│   ├── 01_setup.sql
│   ├── 02_portfolio_eda.sql
│   └── 03_risk_segmentation.sql
│
├── ML/
│   ├── credit_risk_ml_pipeline.ipynb
│   └── credit_risk_ml_pipeline.py
│
├── Documentation/
│   └── SQL_Findings.docx
│
├── Tableau/
│   └── README.md
│
├── requirements.txt
└── README.md

📊 Dashboard

The Tableau dashboard presents the analysis as a connected story:

01 — Financial Impact
What is the financial value of identifying risky loans?
<img width="1120" height="759" alt="image" src="https://github.com/user-attachments/assets/d92ef082-c6e1-4125-9f77-23f89b958c6c" />


02 — Portfolio Risk Segmentation
Where is default risk concentrated?
<img width="1096" height="792" alt="image" src="https://github.com/user-attachments/assets/411b4d03-aecf-496c-a3b6-47f77962ac08" />


03 — ML Diagnostics
Can that risk be predicted and converted into a lending decision?
<img width="1120" height="801" alt="image" src="https://github.com/user-attachments/assets/e88eeac3-5177-43df-812c-3ca9a8b93ca7" />


## ➡️Model Performance
Metric	Score
ROC-AUC	0.682
Recall	0.645
F1	0.406
Precision	0.296

### ➡️Model interpretation

I evaluated the model based on its usefulness for lending decisions, not on a single headline metric. The model uses application-time features including FICO, DTI, loan amount, purpose, employment length, home ownership and geography. The resulting 0.682 ROC-AUC provides meaningful risk separation, consistent with the 5.81%–39.44% default-rate range identified in my FICO × DTI segmentation analysis.

### ➡️Threshold selection

Precision at 0.296 reflects a deliberate threshold choice rather than a standalone model objective. My threshold sweep showed that increasing the cutoff to 0.80 raised precision to 0.57 but reduced recall to 0.02. I therefore selected 0.5, where recall is 0.645, because it produced the strongest financial outcome — $278M in net portfolio savings on the test set.

###➡️Class imbalance

With a 19.98% default rate, I used XGBoost's scale_pos_weight=4.0 to account for class imbalance rather than using synthetic resampling such as SMOTE.
