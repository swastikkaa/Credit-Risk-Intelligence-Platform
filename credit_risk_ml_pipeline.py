
# ========================================================================
# # Credit Risk Intelligence Platform — ML Pipeline
# 
# This notebook builds and evaluates the default-risk model used in the Credit Risk Intelligence Platform.
# 
# **Workflow**
# 1. Prepare application-time features
# 2. Incorporate the SQL-derived FICO × DTI risk profile
# 3. Build the preprocessing pipeline
# 4. Train the final XGBoost classifier
# 5. Evaluate classification performance
# 6. Test the standalone signal in loan descriptions
# 7. Evaluate threshold trade-offs
# 8. Translate predictions into portfolio financial impact
# 9. Export the test-set predictions used by Tableau
# ========================================================================


# ========================================================================
# ## 1. Setup and data preparation
# ========================================================================

import numpy as np
import pandas as pd

from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.metrics import (
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier


RANDOM_STATE = 42
TEST_SIZE = 0.20

df = pd.read_csv("LC_loans_granting_model_dataset.csv")

df["issue_d"] = pd.to_datetime(df["issue_d"], format="%b-%Y")
df["issue_year"] = df["issue_d"].dt.year
df["issue_month"] = df["issue_d"].dt.month

print(f"Dataset shape: {df.shape}")
print(f"Default rate: {df['Default'].mean():.2%}")


# ========================================================================
# ## 2. SQL-informed FICO × DTI feature
# ========================================================================

# Risk bands identified during SQL portfolio EDA
df["fico_band"] = pd.cut(
    df["fico_n"],
    bins=[-np.inf, 669, 739, 799, np.inf],
    labels=["Fair", "Good", "Very Good", "Excellent"],
)

df["dti_band"] = pd.cut(
    df["dti_n"],
    bins=[-np.inf, 8, 18, 25, 30, np.inf],
    labels=["Very Low", "Low", "Moderate", "High", "Very High"],
)

df["fico_dti_profile"] = (
    df["fico_band"].astype(str) + " + " + df["dti_band"].astype(str)
)

# Split once so the same rows are used throughout the structured model.
train_idx, test_idx = train_test_split(
    df.index,
    test_size=TEST_SIZE,
    random_state=RANDOM_STATE,
    stratify=df["Default"],
)

# Derive profile risk from the training set only.
train_profile_stats = (
    df.loc[train_idx]
    .groupby("fico_dti_profile")["Default"]
    .agg(["mean", "count"])
    .rename(columns={"mean": "profile_risk"})
)

df["fico_dti_risk"] = df["fico_dti_profile"].map(
    train_profile_stats["profile_risk"]
)

# Fallback for profiles not observed in training data.
train_default_rate = df.loc[train_idx, "Default"].mean()
df["fico_dti_risk"] = df["fico_dti_risk"].fillna(train_default_rate)

print("Highest-risk FICO × DTI profiles:")
print(
    train_profile_stats
    .sort_values("profile_risk", ascending=False)
    .head(10)
)

print(f"\nMissing risk encodings: {df['fico_dti_risk'].isna().sum()}")


# ========================================================================
# ## 3. Feature selection and preprocessing
# ========================================================================

numeric_features = [
    "fico_n",
    "dti_n",
    "loan_amnt",
    "revenue",
    "issue_year",
    "issue_month",
    "experience_c",
    "fico_dti_risk",
]

categorical_features = [
    "purpose",
    "home_ownership_n",
    "addr_state",
    "emp_length",
]

features = numeric_features + categorical_features

X = df[features]
y = df["Default"]

X_train = X.loc[train_idx]
X_test = X.loc[test_idx]
y_train = y.loc[train_idx]
y_test = y.loc[test_idx]

preprocessor = ColumnTransformer(
    transformers=[
        (
            "num",
            Pipeline([
                ("imputer", SimpleImputer(strategy="median")),
                ("scaler", StandardScaler()),
            ]),
            numeric_features,
        ),
        (
            "cat",
            Pipeline([
                ("imputer", SimpleImputer(strategy="most_frequent")),
                ("encoder", OneHotEncoder(handle_unknown="ignore")),
            ]),
            categorical_features,
        ),
    ]
)

print(f"Training rows: {len(X_train):,}")
print(f"Test rows: {len(X_test):,}")


# ========================================================================
# ## 4. Final XGBoost model
# ========================================================================

xgb_model = Pipeline([
    ("preprocessor", preprocessor),
    ("model", XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        objective="binary:logistic",
        eval_metric="logloss",
        tree_method="hist",
        scale_pos_weight=4.0,
        n_jobs=-1,
        random_state=RANDOM_STATE,
    )),
])

xgb_model.fit(X_train, y_train)

print("XGBoost training complete.")


# ========================================================================
# ## 5. Model evaluation
# ========================================================================

xgb_prob = xgb_model.predict_proba(X_test)[:, 1]
xgb_pred = (xgb_prob >= 0.50).astype(int)

precision = precision_score(y_test, xgb_pred)
recall = recall_score(y_test, xgb_pred)
f1 = f1_score(y_test, xgb_pred)
roc_auc = roc_auc_score(y_test, xgb_prob)

print("XGBoost — threshold 0.50")
print("-------------------------")
print(f"Precision : {precision:.4f}")
print(f"Recall    : {recall:.4f}")
print(f"F1 Score  : {f1:.4f}")
print(f"ROC-AUC   : {roc_auc:.4f}")

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, xgb_pred))


# ========================================================================
# ## 6. Threshold analysis
# ========================================================================

threshold_results = []

for threshold in np.arange(0.50, 0.85, 0.05):
    predictions = (xgb_prob >= threshold).astype(int)

    threshold_results.append({
        "threshold": round(threshold, 2),
        "precision": precision_score(
            y_test, predictions, zero_division=0
        ),
        "recall": recall_score(
            y_test, predictions, zero_division=0
        ),
        "f1": f1_score(
            y_test, predictions, zero_division=0
        ),
    })

threshold_results = pd.DataFrame(threshold_results)
threshold_results


# ========================================================================
# ## 7. Research-inspired text experiment
# ========================================================================

text_df = df[df["desc"].notna()][["desc", "Default"]].copy()

X_text_train, X_text_test, y_text_train, y_text_test = train_test_split(
    text_df["desc"],
    text_df["Default"],
    test_size=TEST_SIZE,
    random_state=RANDOM_STATE,
    stratify=text_df["Default"],
)

tfidf = TfidfVectorizer(
    max_features=20_000,
    stop_words="english",
    ngram_range=(1, 2),
    min_df=5,
)

X_train_tfidf = tfidf.fit_transform(X_text_train)
X_test_tfidf = tfidf.transform(X_text_test)

text_model = LogisticRegression(
    max_iter=1000,
    class_weight="balanced",
)

text_model.fit(X_train_tfidf, y_text_train)

text_prob = text_model.predict_proba(X_test_tfidf)[:, 1]
text_auc = roc_auc_score(y_text_test, text_prob)

print(f"Text-only TF-IDF ROC-AUC: {text_auc:.4f}")
print(f"TF-IDF train shape: {X_train_tfidf.shape}")
print(f"TF-IDF test shape:  {X_test_tfidf.shape}")


# ========================================================================
# ## 8. Portfolio financial impact
# ========================================================================

test_eval = X_test.copy()
test_eval["actual_default"] = y_test
test_eval["predicted_default"] = xgb_pred
test_eval["pred_prob"] = xgb_prob

LGD = 0.70
INTEREST_RATE = 0.10

# Status quo: approve all loans and absorb losses from actual defaults.
baseline_defaults = test_eval[test_eval["actual_default"] == 1]
baseline_loss = (baseline_defaults["loan_amnt"] * LGD).sum()

# True positives: defaults identified by the model.
true_positives = test_eval[
    (test_eval["predicted_default"] == 1)
    & (test_eval["actual_default"] == 1)
]
loss_saved = (true_positives["loan_amnt"] * LGD).sum()

# False positives: good loans rejected by the model.
false_positives = test_eval[
    (test_eval["predicted_default"] == 1)
    & (test_eval["actual_default"] == 0)
]
opportunity_cost = (
    false_positives["loan_amnt"] * INTEREST_RATE
).sum()

# False negatives: defaults not caught by the model.
false_negatives = test_eval[
    (test_eval["predicted_default"] == 0)
    & (test_eval["actual_default"] == 1)
]
remaining_loss = (false_negatives["loan_amnt"] * LGD).sum()

net_dollar_savings = loss_saved - opportunity_cost
portfolio_loss_reduction = (net_dollar_savings / baseline_loss) * 100

print(f"Test-set loan volume:       ${test_eval['loan_amnt'].sum():,.2f}")
print(f"Baseline loss:              ${baseline_loss:,.2f}")
print(f"Default losses saved:      ${loss_saved:,.2f}")
print(f"Opportunity cost:          ${opportunity_cost:,.2f}")
print(f"Net dollar savings:        ${net_dollar_savings:,.2f}")
print(f"Portfolio loss reduction:   {portfolio_loss_reduction:.2f}%")


# ========================================================================
# ## 9. Export predictions for Tableau
# ========================================================================

OUTPUT_FILE = "test_eval_tableau.csv"

test_eval.to_csv(OUTPUT_FILE, index=False)

print(f"Saved: {OUTPUT_FILE}")
