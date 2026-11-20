-- =============================================================
-- China-Africa Trade Monitoring Dataset
-- SQL analysis for SQLite
--
-- Expected table: china_africa_trade
-- Each row represents one shipment.
-- =============================================================

-- 1. Dataset overview
-- Question: How many shipment records and columns do we have, and
-- what are the minimum and maximum trade values?
SELECT
    COUNT(*) AS shipment_count,
    COUNT(DISTINCT shipment_id) AS unique_shipment_ids,
    COUNT(DISTINCT export_country) AS export_country_count,
    COUNT(DISTINCT import_country) AS import_country_count,
    COUNT(DISTINCT commodity) AS commodity_count,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(MIN(declared_value_usd), 2) AS min_declared_value_usd,
    ROUND(MAX(declared_value_usd), 2) AS max_declared_value_usd
FROM china_africa_trade;


-- 2. Data quality and missing values
-- Question: Does the data contain missing values or duplicate shipment IDs?
SELECT
    SUM(shipment_id IS NULL) AS missing_shipment_id,
    SUM(export_country IS NULL) AS missing_export_country,
    SUM(import_country IS NULL) AS missing_import_country,
    SUM(commodity IS NULL) AS missing_commodity,
    SUM(quantity IS NULL) AS missing_quantity,
    SUM(declared_value_usd IS NULL) AS missing_declared_value,
    SUM(transit_time_days IS NULL) AS missing_transit_time,
    SUM(anomaly_flag IS NULL) AS missing_anomaly_flag,
    COUNT(*) - COUNT(DISTINCT shipment_id) AS duplicate_id_rows
FROM china_africa_trade;


-- 3. Trade value by African import country
-- Question: Which African countries receive the highest total shipment value?
SELECT
    import_country,
    COUNT(*) AS shipment_count,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(AVG(declared_value_usd), 2) AS avg_shipment_value_usd,
    ROUND(100.0 * SUM(declared_value_usd) /
        SUM(SUM(declared_value_usd)) OVER (), 2) AS pct_of_total_value
FROM china_africa_trade
GROUP BY import_country
ORDER BY total_declared_value_usd DESC;


-- 4. Trade volume and value by commodity
-- Question: Which commodity categories dominate in number of shipments and value?
SELECT
    commodity,
    COUNT(*) AS shipment_count,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(AVG(declared_value_usd), 2) AS avg_shipment_value_usd
FROM china_africa_trade
GROUP BY commodity
ORDER BY total_declared_value_usd DESC;


-- 5. Highest-value commodity-country pairs
-- Question: Which commodity and destination combinations generate the most trade?
SELECT
    commodity,
    import_country,
    COUNT(*) AS shipment_count,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd
FROM china_africa_trade
GROUP BY commodity, import_country
ORDER BY total_declared_value_usd DESC
LIMIT 20;


-- 6. Transport mode usage
-- Question: How is shipment volume distributed across transport modes?
SELECT
    transport_mode,
    COUNT(*) AS shipment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_shipments,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(AVG(transit_time_days), 2) AS avg_transit_days
FROM china_africa_trade
GROUP BY transport_mode
ORDER BY shipment_count DESC;


-- 7. Country trade profile
-- Question: Which import countries have the largest average shipment sizes?
SELECT
    import_country,
    COUNT(*) AS shipment_count,
    ROUND(AVG(quantity), 2) AS avg_quantity,
    ROUND(AVG(declared_value_usd), 2) AS avg_declared_value_usd,
    ROUND(AVG(declared_value_usd / NULLIF(quantity, 0)), 2) AS avg_declared_value_per_unit
FROM china_africa_trade
GROUP BY import_country
ORDER BY avg_declared_value_usd DESC;


-- 8. Transit-time distribution
-- Question: What are the overall transit-time statistics?
SELECT
    COUNT(*) AS shipment_count,
    ROUND(MIN(transit_time_days), 2) AS min_days,
    ROUND(AVG(transit_time_days), 2) AS avg_days,
    ROUND(MAX(transit_time_days), 2) AS max_days
FROM china_africa_trade;


-- 9. Transit performance by transport mode
-- Question: Which transport modes are fastest and slowest on average?
SELECT
    transport_mode,
    COUNT(*) AS shipment_count,
    ROUND(AVG(transit_time_days), 2) AS avg_transit_days,
    ROUND(MIN(transit_time_days), 2) AS min_transit_days,
    ROUND(MAX(transit_time_days), 2) AS max_transit_days
FROM china_africa_trade
GROUP BY transport_mode
ORDER BY avg_transit_days;


-- 10. Delay rate
-- Question: How many shipments are delayed, and what percentage is delayed?
SELECT
    delay_status,
    COUNT(*) AS shipment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_shipments
FROM china_africa_trade
GROUP BY delay_status
ORDER BY shipment_count DESC;


-- 11. Delay rate by transport mode
-- Question: Which transport modes are most vulnerable to delays?
SELECT
    transport_mode,
    COUNT(*) AS shipment_count,
    SUM(CASE WHEN delay_status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_shipments,
    ROUND(
        100.0 * SUM(CASE WHEN delay_status = 'Delayed' THEN 1 ELSE 0 END) /
        COUNT(*),
        2
    ) AS delayed_pct,
    ROUND(AVG(CASE WHEN delay_status = 'Delayed' THEN transit_time_days END), 2)
        AS avg_delayed_transit_days
FROM china_africa_trade
GROUP BY transport_mode
ORDER BY delayed_pct DESC;


-- 12. Delay rate by import country
-- Question: Which destinations experience the highest shipment-delay rates?
SELECT
    import_country,
    COUNT(*) AS shipment_count,
    SUM(CASE WHEN delay_status = 'Delayed' THEN 1 ELSE 0 END) AS delayed_shipments,
    ROUND(
        100.0 * SUM(CASE WHEN delay_status = 'Delayed' THEN 1 ELSE 0 END) /
        COUNT(*),
        2
    ) AS delayed_pct
FROM china_africa_trade
GROUP BY import_country
HAVING COUNT(*) >= 100
ORDER BY delayed_pct DESC;


-- 13. Port traffic
-- Question: What are the busiest departure and arrival ports?
SELECT 'Departure' AS port_role, departure_port AS port,
       COUNT(*) AS shipment_count,
       ROUND(SUM(declared_value_usd), 2) AS trade_value_usd
FROM china_africa_trade
GROUP BY departure_port

UNION ALL

SELECT 'Arrival' AS port_role, arrival_port AS port,
       COUNT(*) AS shipment_count,
       ROUND(SUM(declared_value_usd), 2) AS trade_value_usd
FROM china_africa_trade
GROUP BY arrival_port

ORDER BY port_role, shipment_count DESC;


-- 14. Top trade routes
-- Question: Which departure-to-arrival routes carry the most shipment value?
SELECT
    departure_port,
    arrival_port,
    COUNT(*) AS shipment_count,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(AVG(transit_time_days), 2) AS avg_transit_days
FROM china_africa_trade
GROUP BY departure_port, arrival_port
ORDER BY total_declared_value_usd DESC
LIMIT 20;


-- 15. Payment-term profile
-- Question: Which payment terms are most common and which have the highest trade value?
SELECT
    payment_terms,
    COUNT(*) AS shipment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_shipments,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(AVG(declared_value_usd), 2) AS avg_shipment_value_usd
FROM china_africa_trade
GROUP BY payment_terms
ORDER BY total_declared_value_usd DESC;


-- 16. Contract versus declared value
-- Question: Do shipment contract values differ materially from declared values?
SELECT
    COUNT(*) AS shipment_count,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(SUM(contract_value_usd), 2) AS total_contract_value_usd,
    ROUND(AVG(contract_value_usd - declared_value_usd), 2) AS avg_absolute_difference_usd,
    ROUND(AVG((contract_value_usd - declared_value_usd) /
              NULLIF(declared_value_usd, 0)), 4) AS avg_relative_difference,
    ROUND(100.0 * SUM(CASE WHEN contract_value_usd > declared_value_usd THEN 1 ELSE 0 END)
        / COUNT(*), 2) AS contract_above_declared_pct
FROM china_africa_trade;


-- 17. Commodity-level contract variance
-- Question: Which commodities show the largest contract-versus-declared value differences?
SELECT
    commodity,
    COUNT(*) AS shipment_count,
    ROUND(AVG(contract_value_usd - declared_value_usd), 2) AS avg_value_difference_usd,
    ROUND(AVG(ABS(contract_value_usd - declared_value_usd)), 2) AS avg_absolute_difference_usd,
    ROUND(AVG(
        (contract_value_usd - declared_value_usd) /
        NULLIF(declared_value_usd, 0)
    ), 4) AS avg_relative_difference
FROM china_africa_trade
GROUP BY commodity
ORDER BY avg_absolute_difference_usd DESC;


-- 18. Declared value versus market-price benchmark
-- Question: How much does declared value per unit differ from the market price?
SELECT
    COUNT(*) AS shipment_count,
    ROUND(AVG(declared_value_usd / NULLIF(quantity, 0)), 2) AS avg_declared_price_per_unit,
    ROUND(AVG(market_price_per_unit), 2) AS avg_market_price_per_unit,
    ROUND(100.0 * AVG(
        (declared_value_usd / NULLIF(quantity, 0) - market_price_per_unit) /
        NULLIF(market_price_per_unit, 0)
    ), 2) AS avg_declared_vs_market_pct
FROM china_africa_trade;


-- 19. Commodities with the greatest market benchmark discrepancy
-- Question: Which commodity categories have the largest pricing discrepancy?
SELECT
    commodity,
    COUNT(*) AS shipment_count,
    ROUND(AVG(declared_value_usd / NULLIF(quantity, 0)), 2) AS avg_declared_price_per_unit,
    ROUND(AVG(market_price_per_unit), 2) AS avg_market_price_per_unit,
    ROUND(100.0 * AVG(
        (declared_value_usd / NULLIF(quantity, 0) - market_price_per_unit) /
        NULLIF(market_price_per_unit, 0)
    ), 2) AS avg_discrepancy_pct
FROM china_africa_trade
GROUP BY commodity
ORDER BY ABS(avg_discrepancy_pct) DESC;


-- 20. Volatility profile
-- Question: Which commodities have the highest average market-price volatility?
SELECT
    commodity,
    COUNT(*) AS shipment_count,
    ROUND(AVG(price_volatility_index), 4) AS avg_volatility,
    ROUND(MIN(price_volatility_index), 4) AS min_volatility,
    ROUND(MAX(price_volatility_index), 4) AS max_volatility
FROM china_africa_trade
GROUP BY commodity
ORDER BY avg_volatility DESC;


-- 21. Anomaly prevalence
-- Question: What percentage of shipments is flagged as anomalous?
SELECT
    anomaly_flag,
    COUNT(*) AS shipment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_shipments,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd
FROM china_africa_trade
GROUP BY anomaly_flag
ORDER BY anomaly_flag;


-- 22. Anomaly rate by commodity
-- Question: Which commodities have the highest anomaly rates?
SELECT
    commodity,
    COUNT(*) AS shipment_count,
    SUM(anomaly_flag) AS anomalous_shipments,
    ROUND(100.0 * SUM(anomaly_flag) / COUNT(*), 2) AS anomaly_pct,
    ROUND(AVG(transit_time_days), 2) AS avg_transit_days
FROM china_africa_trade
GROUP BY commodity
ORDER BY anomaly_pct DESC;


-- 23. Anomaly rate by delay status
-- Question: Are anomalous shipments more likely to be delayed?
SELECT
    delay_status,
    COUNT(*) AS shipment_count,
    SUM(anomaly_flag) AS anomalous_shipments,
    ROUND(100.0 * SUM(anomaly_flag) / COUNT(*), 2) AS anomaly_pct
FROM china_africa_trade
GROUP BY delay_status
ORDER BY anomaly_pct DESC;


-- 24. HS-code concentration
-- Question: Which HS codes account for the most trade value?
SELECT
    hs_code,
    COUNT(*) AS shipment_count,
    ROUND(SUM(declared_value_usd), 2) AS total_declared_value_usd,
    ROUND(100.0 * SUM(declared_value_usd) /
        SUM(SUM(declared_value_usd)) OVER (), 2) AS pct_of_total_value
FROM china_africa_trade
GROUP BY hs_code
ORDER BY total_declared_value_usd DESC;


-- 25. High-value outliers
-- Question: Which shipment records have unusually high declared values?
-- Values above the 95th percentile are shown.
WITH ranked AS (
    SELECT *,
           PERCENT_RANK() OVER (ORDER BY declared_value_usd) AS pct_rank
    FROM china_africa_trade
)
SELECT
    shipment_id,
    import_country,
    commodity,
    transport_mode,
    quantity,
    declared_value_usd,
    contract_value_usd,
    anomaly_flag,
    delay_status
FROM ranked
WHERE pct_rank >= 0.95
ORDER BY declared_value_usd DESC
LIMIT 50;


-- 26. Risk-focused shipment view
-- Question: How many shipments are both delayed and anomalous, and where are they?
SELECT
    import_country,
    commodity,
    COUNT(*) AS delayed_anomalous_shipments,
    ROUND(SUM(declared_value_usd), 2) AS associated_declared_value_usd
FROM china_africa_trade
WHERE delay_status = 'Delayed'
  AND anomaly_flag = 1
GROUP BY import_country, commodity
HAVING COUNT(*) > 0
ORDER BY delayed_anomalous_shipments DESC;


-- 27. Destination concentration (Pareto view)
-- Question: How concentrated is trade among the top African destinations?
WITH country_values AS (
    SELECT
        import_country,
        SUM(declared_value_usd) AS country_value
    FROM china_africa_trade
    GROUP BY import_country
),
cumulative AS (
    SELECT
        import_country,
        country_value,
        SUM(country_value) OVER (ORDER BY country_value DESC,
                                 import_country) AS cumulative_value,
        SUM(country_value) OVER () AS grand_total
    FROM country_values
)
SELECT
    import_country,
    ROUND(country_value, 2) AS country_value_usd,
    ROUND(100.0 * country_value / grand_total, 2) AS pct_of_total,
    ROUND(100.0 * cumulative_value / grand_total, 2) AS cumulative_pct
FROM cumulative
ORDER BY country_value DESC;
