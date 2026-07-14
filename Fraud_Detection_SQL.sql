CREATE TABLE  transactions (
    step INT,
    type VARCHAR(20),
    amount NUMERIC,
    nameOrig VARCHAR(50),
    oldbalanceOrg NUMERIC,
    newbalanceOrig NUMERIC,
    nameDest VARCHAR(50),
    oldbalanceDest NUMERIC,
    newbalanceDest NUMERIC,
    isFraud INT,
    isFlaggedFraud INT
);

SELECT column_name,data_type
FROM information_schema.columns
WHERE table_name = 'transactions';

SELECT
    COUNT(*) FILTER (WHERE step IS NULL) AS step_null,
    COUNT(*) FILTER (WHERE type IS NULL) AS type_null,
    COUNT(*) FILTER (WHERE amount IS NULL) AS amount_null,
    COUNT(*) FILTER (WHERE nameOrig IS NULL) AS nameOrig_null,
    COUNT(*) FILTER (WHERE oldBalanceOrg IS NULL) AS oldBalanceOrg_null,
    COUNT(*) FILTER (WHERE newBalanceOrig IS NULL) AS newBalanceOrig_null,
    COUNT(*) FILTER (WHERE nameDest IS NULL) AS nameDest_null,
    COUNT(*) FILTER (WHERE oldBalanceDest IS NULL) AS oldBalanceDest_null,
    COUNT(*) FILTER (WHERE newBalanceDest IS NULL) AS newBalanceDest_null,
    COUNT(*) FILTER (WHERE isFraud IS NULL) AS isFraud_null,
    COUNT(*) FILTER (WHERE isFlaggedFraud IS NULL) AS isFlaggedFraud_null
FROM transactions;

SELECT
    COUNT(*) AS duplicate_rows
FROM (
    SELECT
        step,
        type,
        amount,
        nameOrig,
        oldBalanceOrg,
        newBalanceOrig,
        nameDest,
        oldBalanceDest,
        newBalanceDest,
        isFraud,
        isFlaggedFraud,
        COUNT(*)
    FROM transactions
    GROUP BY
        step,
        type,
        amount,
        nameOrig,
        oldBalanceOrg,
        newBalanceOrig,
        nameDest,
       oldBalanceDest,newBalanceDest,
        isFraud,isFlaggedFraud
    HAVING COUNT(*) > 1) AS duplicates;

SELECT * FROM transactions
WHERE amount<0;

SELECT * FROM transactions
WHERE oldbalanceOrg<0 OR newbalanceOrig<0 OR oldbalanceDest<0 OR newbalanceDest<0; 

SELECT DISTINCT isfraud FROM transactions;

SELECT DISTINCT isFlaggedfraud FROM transactions;

SELECT DISTINCT type FROM transactions;

SELECT COUNT(*) AS total_transaction
FROM transactions;

SELECT isFraud,COUNT(*) FROM transactions
GROUP BY isFraud;

SELECT isFlaggedFraud,COUNT(*) FROM transactions
GROUP BY isFlaggedFraud;

SELECT ROUND((COUNT(*) FILTER (WHERE isFraud = 1) * 100.0)
/ COUNT(*),2) AS fraud_percentage
FROM transactions;

SELECT ROUND((COUNT(*) FILTER (WHERE isFlaggedFraud=1)*100.0)/COUNT(*),4)
AS flaggedfraud_percentage
FROM transactions;

SELECT COUNT(DISTINCT type ) AS types
FROM transactions;

SELECT
    SUM(amount) AS total_amount,
    AVG(amount) AS average_amount,
    MAX(amount) AS max_amount,
    MIN(amount) AS min_amount,
    STDDEV(amount) AS stddev_amount
FROM transactions;

SELECT type,isfraud,COUNT(*) AS transaction_count
FROM transactions
GROUP BY type,isfraud
ORDER BY type;

SELECT step,COUNT(*) AS transactions_count
FROM transactions
GROUP BY step
ORDER BY step;

SELECT step,COUNT(*) AS fraud_count
FROM transactions
WHERE isfraud=1
GROUP BY step
ORDER BY fraud_count DESC;

SELECT type,ROUND((COUNT(*) FILTER (WHERE isfraud=1)*100.0)/COUNT(*),2) AS  fraud_rate_percent,
COUNT(*) AS fraud_count
FROM transactions
GROUP BY type
ORDER BY  fraud_rate_percent DESC;

SELECT ROUND(AVG(amount) FILTER(WHERE isfraud=1),2) AS avg_fraud_amount,
ROUND(AVG(amount) FILTER(WHERE isfraud=0),2) AS avg_non_fraud_amount
FROM transactions;

SELECT nameOrig,COUNT(*) AS fraud_transactions,
SUM(amount) AS total_fraud_amount,
ROUND(AVG(amount),2) AS avg_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY nameOrig
ORDER BY total_fraud_amount DESC
LIMIT 10;

SELECT nameDest,COUNT(*) AS fraud_transactions,
SUM(amount) AS total_fraud_amount,
ROUND(AVG(amount),2) AS avg_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY nameDest
ORDER BY total_fraud_amount DESC
LIMIT 10;

SELECT step,type,nameOrig,nameDest, amount AS Amount
FROM transactions
WHERE isfraud=1
ORDER BY amount DESC
LIMIT 10;

SELECT nameOrig, COUNT(*) AS fraud_transaction
FROM transactions
WHERE isFraud=1
GROUP BY nameOrig
HAVING COUNT(*)>1;

SELECT nameDest, COUNT(*) AS fraud_transaction
FROM transactions
WHERE isFraud=1
GROUP BY nameDest
HAVING COUNT(*)>1;

SELECT type,COUNT(*) AS total_transactions,
COUNT(*) FILTER (WHERE isFraud = 1) AS fraud_transactions,
ROUND((COUNT(*) FILTER (WHERE isFraud = 1) * 100.0) / 
COUNT(*),2) AS fraud_rate_percent,
ROUND(AVG(amount),2) AS avg_transaction_amount,
MAX(amount) AS max_transaction_amount,
SUM(amount) AS total_transaction_amount
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
GROUP BY type
ORDER BY fraud_rate_percent DESC;

SELECT step, COUNT(*) AS fraud_count
FROM transactions
WHERE isfraud=1
GROUP BY step
ORDER BY step;

SELECT 
CASE 
	WHEN amount>=10000000 THEN 'High Value'
	WHEN amount>=100000 THEN 'Medium Value'
	ELSE 'Low Value'
END	AS transaction_level,
COUNT(*) AS transaction_count
FROM transactions
GROUP BY CASE 
	WHEN amount>=10000000 THEN 'High Value'
	WHEN amount>=100000 THEN 'Medium Value'
	ELSE 'Low Value'
END	;

SELECT nameOrig,SUM(amount) AS total_transaction
FROM transactions
GROUP BY nameOrig
HAVING SUM(amount)>(SELECT AVG(total_transaction)
FROM(SELECT SUM(amount) AS total_transaction
FROM transactions
GROUP BY nameOrig)t);

WITH customer_total AS (
SELECT nameOrig,SUM(amount) AS total_transaction
FROM transactions
GROUP BY nameOrig
) SELECT * FROM customer_total
WHERE total_transaction>500000;

WITH customer_total AS (SELECT nameOrig,SUM(amount)
AS total_transaction
FROM transactions
GROUP BY nameOrig
) SELECT * FROM customer_total
ORDER BY total_transaction DESC
LIMIT 10;

SELECT step,isFraud,SUM(isFraud) 
OVER (ORDER BY step
) AS running_fraud_count
FROM transactions
ORDER BY step;

WITH customer_total AS (SELECT
nameOrig,SUM(amount) AS total_transaction
FROM transactions
GROUP BY nameOrig)
SELECT * ,
DENSE_RANK() OVER(ORDER BY total_transaction DESC) AS risk_rank
FROM customer_total;

SELECT step,COUNT(*) OVER(
ORDER BY step)
FROM transactions;

WITH  risk_engine AS (SELECT step
,type
,amount
,nameOrig
,nameDest ,
(CASE 
	WHEN amount>500000 THEN 25
	ELSE 0 END)+
(CASE
	WHEN type='TRANSFER' THEN 20
	ELSE 0 END)+
(CASE
	WHEN type='CASH_OUT' THEN 15
	ELSE 0 END)+
(CASE
	WHEN isflaggedfraud=1 THEN 20
	ELSE 0 END)+
(CASE
	WHEN isfraud=1 THEN 20
	ELSE 0 END ) AS risk_score
FROM transactions)
SELECT *,
CASE
    WHEN risk_score BETWEEN 0 AND 30 THEN 'Low Risk'
    WHEN risk_score BETWEEN 31 AND 60 THEN 'Medium Risk'
    ELSE 'High Risk'
END AS risk_level
FROM risk_engine;

SELECT step,nameOrig,COUNT(*) AS transaction_count
FROM transactions
GROUP BY step,nameOrig
HAVING COUNT(*)>1;

WITH z_customer AS (
SELECT
AVG(amount) AS avg_amount,
STDDEV(amount) AS stddev_amount
FROM transactions)
SELECT step,type,amount,nameOrig,
nameDest,CASE
    WHEN ABS((amount - avg_amount) / stddev_amount) > 3
    THEN 'Anomaly'
    ELSE 'Normal'
END AS anomaly_status,
(amount - avg_amount) / stddev_amount AS z_score
FROM transactions, z_customer
WHERE ABS((amount - avg_amount) / stddev_amount) > 3;

SELECT step,COUNT(*) FILTER(WHERE isfraud=1) AS fraud_transaction,
COUNT(*) AS total_transaction
FROM transactions
GROUP BY step
ORDER BY step;

CREATE VIEW fraud_risk_view AS
WITH  risk_engine AS (SELECT step
,type
,amount
,nameOrig
,nameDest ,
(CASE 
	WHEN amount>500000 THEN 25
	ELSE 0 END)+
(CASE
	WHEN type='TRANSFER' THEN 20
	ELSE 0 END)+
(CASE
	WHEN type='CASH_OUT' THEN 15
	ELSE 0 END)+
(CASE
	WHEN isflaggedfraud=1 THEN 20
	ELSE 0 END)+
(CASE
	WHEN isfraud=1 THEN 20
	ELSE 0 END ) AS risk_score
FROM transactions)
SELECT *,
CASE
    WHEN risk_score BETWEEN 0 AND 30 THEN 'Low Risk'
    WHEN risk_score BETWEEN 31 AND 60 THEN 'Medium Risk'
    ELSE 'High Risk'
END AS risk_level
FROM risk_engine;
SELECT * FROM fraud_risk_view
WHERE risk_level='High Risk';

CREATE MATERIALIZED VIEW fraud_risk_mv AS
WITH  risk_engine AS (SELECT step
,type
,amount
,nameOrig
,nameDest ,
(CASE 
	WHEN amount>500000 THEN 25
	ELSE 0 END)+
(CASE
	WHEN type='TRANSFER' THEN 20
	ELSE 0 END)+
(CASE
	WHEN type='CASH_OUT' THEN 15
	ELSE 0 END)+
(CASE
	WHEN isflaggedfraud=1 THEN 20
	ELSE 0 END)+
(CASE
	WHEN isfraud=1 THEN 20
	ELSE 0 END ) AS risk_score
FROM transactions)
SELECT *,
CASE
    WHEN risk_score BETWEEN 0 AND 30 THEN 'Low Risk'
    WHEN risk_score BETWEEN 31 AND 60 THEN 'Medium Risk'
    ELSE 'High Risk'
END AS risk_level
FROM risk_engine;
SELECT * FROM fraud_risk_mv
WHERE risk_score>75;

CREATE INDEX idx_nameOrig
ON transactions(nameOrig);
EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE nameOrig = 'C123456789';

CREATE INDEX idx_isFraud
ON transactions(isFraud);
EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE isFraud = 1;

CREATE INDEX idx_step
ON transactions(step);