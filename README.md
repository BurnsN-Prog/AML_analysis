# Meridian Financial Group — AML Transaction Monitoring Analysis

> A fictional financial-crime analytics case study created for portfolio practice. All customers and transactions are fictional. This project identifies transactional risk indicators and prioritizes accounts for further review; it does not establish fraud or money laundering.

## Business Problem

Financial Crime Compliance needed a clear overview of payment activity and an explainable way to prioritize customers for analyst review. The analysis summarizes the transaction population, identifies customers with elevated activity indicators, and translates those indicators into a ranked case review table. The intended output is a review queue supported by observable transaction patterns.

## Dataset

The analysis covers January–June 2026 and uses two fictional CSV datasets linked by `customer_id`:

| File | Grain | Coverage and key fields |
|---|---|---|
| `aml_customers.csv` | One row per customer | 250 customers; region, segment, existing risk rating, occupation, approximate normal monthly inflow, and account tenure |
| `aml_transactions.csv` | One row per transaction | 3,729 transactions; transaction ID, customer ID, timestamp, type, direction, amount in USD, country code, and channel |

Total transaction amount is gross activity: inflows plus outflows, rather than net cash flow or account balances. Customer-level dollar metrics cover the entire six-month period. International wire activity is defined as incoming or outgoing wires with a country code other than `US`.

## Tools

- PostgreSQL
- Python with pandas and NumPy
- Matplotlib and seaborn 
- Jupyter Notebook and IPython 

## Analytical Questions

1. What does the overall transaction population look like by count, amount, type, and direction?
2. Which customers have elevated transaction volume, cash deposits, international wires, or rapid wire activity?
3. Which customers should be prioritized for analyst review, and why?
4. What additional evidence would be needed before considering escalation?

## Analytical Approach

### SQL transaction aggregation

The SQL script groups transactions by type to calculate counts, total amounts, and average amounts. It also aggregates customer activity, joins transactions to customer profiles for comparisons by existing risk rating, and self-joins incoming and outgoing wires to identify same-customer pairs occurring within 24 hours.

Tasks 2 and 3 define international wire-out activity as transactions where `transaction_type = 'Wire Out' AND country_code != 'US'`. The Python scoring metric includes non-US wires in both directions, so its international-wire totals have a broader scope than the SQL wire-out metric. The findings and review scores below come from the Python analysis.

### Python customer-level analysis

The notebook loads the two CSVs directly and summarizes transaction counts, amounts, types, and inflow versus outflow. It aggregates total transaction amounts, cash deposits, and international wires by customer, then joins those metrics to customer profiles. Missing totals from activity-specific joins are filled with zero to represent no observed activity of that type.

Three amount-based indicators use the 90th percentile across all 250 customers. A fourth indicator identifies customers with at least one outgoing wire occurring more than zero and no more than 24 hours after an incoming wire. This timing indicator identifies a sequence for review; it does not trace the same funds between transactions.

## Three Strongest Findings

1. **Outflows dominate the observed payment population.** The dataset contains 3,729 transactions totaling **$8,863,840.64**. Outflows account for **2,361 transactions (63.3%)** and **$5,035,710.27 (56.8% of gross value)**. Card purchases are the largest individual transaction type by both count and total amount: **1,001 transactions totaling $2,006,495.12**.

2. **Activity indicators identify 59 customers for potential attention.** Each of the three amount-based indicators flags **25 customers**, while the rapid-wire indicator flags **11**. These groups overlap: **38 customers trigger one activity flag, 15 trigger two, and 6 trigger three**. No customer triggers all four; **191 trigger none**. The six customers with three activity flags are **23, 45, 60, 84, 114, and 151**.

3. **The combined framework produces a seven-customer higher-priority queue.** Adding the existing High risk rating to the four activity indicators results in **7 Higher**, **72 Medium**, and **171 Lower** review-priority customers. Customer **84** has the highest score of **4**, reflecting elevated total volume, cash deposits, international wires, and an existing High risk rating. This ranking directs analyst attention without treating an indicator as evidence of wrongdoing.

## Review Prioritization

Each condition contributes one point, producing a possible score of **0–5**. Percentile cutoffs are calculated using full precision; the displayed dollar thresholds below are rounded.

| Indicator | Rule | Points |
|---|---|---:|
| Elevated total volume | Six-month total transaction amount at or above the 90th percentile, approximately $72,661.39 | +1 |
| Elevated cash deposits | Six-month cash deposits at or above the 90th percentile, approximately $13,894.84 | +1 |
| Elevated international wires | Six-month non-US incoming and outgoing wires at or above the 90th percentile, approximately $6,312.81 | +1 |
| Rapid wire activity | At least one same-customer outgoing wire more than zero and no more than 24 hours after an incoming wire | +1 |
| Existing High risk rating | Customer profile has `risk_rating = 'High'` | +1 |

The cash indicator uses the implemented percentile rule, not a fixed $10,000 threshold. It is an analytical triage measure, not a regulatory reporting determination.

| Review priority | Score | Customers |
|---|---|---:|
| Lower | 0 | 171 |
| Medium | 1–2 | 72 |
| Higher | 3–5 | 7 |

The observed score distribution is **0: 171, 1: 52, 2: 20, 3: 6, 4: 1, and 5: 0**. Existing customer risk ratings and calculated review-priority tiers are separate concepts: a customer with a Low existing rating can still receive Higher review priority based on observed activity.

### Recommended case review queue

| Customer | Existing risk rating | Score | Reasons for analyst review |
|---|---|---:|---|
| 84 | High | 4 | Elevated total volume, cash deposits, international wires, and existing High risk rating |
| 23 | Medium | 3 | Elevated total volume, international wires, and rapid wire activity |
| 45 | Low | 3 | Elevated total volume, international wires, and rapid wire activity |
| 60 | Medium | 3 | Elevated total volume, international wires, and rapid wire activity |
| 67 | High | 3 | Elevated cash deposits, international wires, and existing High risk rating |
| 114 | Low | 3 | Elevated total volume, cash deposits, and international wires |
| 151 | Low | 3 | Elevated total volume, international wires, and rapid wire activity |

The notebook's final case review table also displays each customer's total transaction amount, cash deposits, international wire amount, and rapid-movement flag. Customers are sorted by descending score and then customer ID; the ID tie-breaker does not imply greater concern. Customer 23 does not trigger the cash-deposit flag.

An analyst would use this queue to examine the underlying transactions and request supporting customer information, including expected activity, source of funds, counterparties, and transaction purpose. Those findings would inform whether further review or escalation is appropriate.

## Visualizations

The notebook contains two charts:

1. **Overall transaction activity:** total transaction amount by type and flow direction.
2. **Review-priority score distribution:** customer counts by calculated score.

![Overall transaction amount by type and flow direction](chart1_overall_activity.png)

![Customer review-priority score distribution](chart2_score_distribution.png)

## Limitations


- **Limited customer context:** Profiles include basic attributes and an existing rating, but no supporting KYC documentation, beneficial ownership records, or source-of-funds information.
- **Limited transaction context:** There are no transaction descriptions or supporting documents establishing business purpose. A non-US country code is an activity classification, not evidence of illicit activity.
- **Short observation window:** Six months of activity may not capture seasonality or a customer's longer-term behavior. The score does not compare observed inflows with a time-aligned expected-inflow baseline.
- **Simple thresholds:** Percentile thresholds are population-relative, are not adjusted for customer segment, and are not validated regulatory cutoffs. Equal weights are an explainable design choice rather than an empirically calibrated model. Total volume overlaps with cash and wire amounts, so some indicators are correlated.
- **Timing is a proxy:** Wire proximity alone does not establish that incoming funds funded an outgoing payment. The analysis does not match amounts or trace funds through counterparties.
- **Indicators are not findings of misconduct:** Higher priority means more reasons for analyst review. Lower priority does not certify legitimate activity. Transactional indicators do not prove fraud, money laundering, or AML violations.

## Repository Structure

The current package uses a flat directory structure:

```text
aml_customers.csv
aml_transactions.csv
data_dictionary.csv
aml_analysis.sql
aml_transaction_monitoring.ipynb
chart1_overall_activity.png
chart2_score_distribution.png
README.md
```

## Reproducing the Analysis

1. Keep the notebook and both CSV files in the same directory.
2. Use a Python environment with `pandas`, `numpy`, `matplotlib`, `seaborn`, `ipython`, `jinja2`, and Jupyter installed. Open Jupyter from the project directory and run the notebook from a fresh kernel, top to bottom. The plotting cells regenerate the two PNG files.
3. For the SQL analysis, load the CSVs into PostgreSQL tables named `aml_customers` and `aml_transactions`, using appropriate numeric types and a timestamp type for `transaction_ts`.

