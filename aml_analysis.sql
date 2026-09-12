-- Meridian Financial Group
-- Week 6: Payments, Fraud & AML Analytics
-- Analyst: Nicole
-- Date: September 8, 2026

-- Task 1: Transaction activity overview
-- Return transaction_type, transaction_count, total_amount, average_amount.
SELECT transaction_type, 
	COUNT(DISTINCT transaction_id) AS transaction_count,
	SUM(amount) AS total_transactions_amount,
	ROUND(AVG(amount), 2) AS avg_transactions_amount
FROM aml_transactions
GROUP BY transaction_type;

-- Task 2: Customer transaction intensity
-- For each customer, calculate transaction_count, total_inflow, total_outflow,
-- total_cash_deposits, total_wire_out, and international_wire_out_amount.
SELECT customer_id,
	COUNT(DISTINCT transaction_id) AS transaction_count,
	SUM(amount) FILTER (WHERE direction = 'In') AS total_inflow, 
	SUM(amount) FILTER (WHERE direction = 'Out') AS total_outflow,
	SUM(amount) FILTER (WHERE transaction_type = 'Cash Deposit') AS total_cash_deposits,
	SUM(amount) FILTER (WHERE transaction_type = 'Wire Out') AS total_wire_out,
	SUM(amount) FILTER (WHERE transaction_type = 'Wire Out' AND country_code != 'US') AS international_wire_out_amount

FROM aml_transactions
GROUP BY customer_id;

-- Task 3: High-risk customer review
-- Join customer profiles to transaction summaries.
-- Compare Low, Medium, and High risk_rating groups using customer_count,
-- total transaction amount, cash deposit amount, and international wire-out amount.
SELECT c.risk_rating, 
	COUNT(DISTINCT c.customer_id) AS customer_count,
	SUM(amount) AS total_transaction_amount, 
	SUM(amount) FILTER(WHERE transaction_type = 'Cash Deposit') AS total_cash_deposit,
	SUM(amount) FILTER(WHERE transaction_type = 'Wire Out' AND country_code != 'US') AS total_international_wire_out

FROM aml_customers AS c
JOIN aml_transactions AS t ON c.customer_id = t.customer_id
GROUP BY c.risk_rating;

-- Task 4: Potential rapid-movement activity
-- Identify customers with both incoming and outgoing wire activity occurring close together.
-- Your goal is to create a candidate list for analyst review, not declare fraud or money laundering.
SELECT 
    t_in.customer_id,
    t_in.transaction_ts  AS incoming_wire_ts,
    t_in.amount          AS incoming_wire_amount,
    t_out.transaction_ts AS outgoing_wire_ts,
    t_out.amount         AS outgoing_wire_amount,
    (t_out.transaction_ts - t_in.transaction_ts) AS time_between_transactions

FROM aml_transactions t_in
JOIN aml_transactions t_out 
    ON t_in.customer_id = t_out.customer_id

WHERE t_in.direction = 'In'
  AND t_in.transaction_type = 'Wire In'
  AND t_out.direction = 'Out'
  AND t_out.transaction_type = 'Wire Out'
  AND t_out.transaction_ts > t_in.transaction_ts
  AND t_out.transaction_ts <= t_in.transaction_ts + INTERVAL '24 hours'

ORDER BY t_in.customer_id, t_in.transaction_ts;