-- ============================================================
-- PROJECT: Operations Performance Metrics Dashboard
-- FILE:    03_kpi_metrics.sql
-- DESC:    Core KPI calculations for operational performance
-- ============================================================

USE ops_dashboard;

-- ============================================================
-- KPI 1: AVERAGE ORDER PROCESSING TIME (in minutes)
-- ============================================================
-- Only calculated for Delivered orders (delivery_time is populated)

SELECT
    ROUND(
        AVG(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)),
        2
    ) AS avg_processing_time_mins
FROM orders
WHERE order_status = 'Delivered';

/*
  WHAT IT DOES:
  Calculates the mean time (in minutes) between order placement
  and successful delivery across all completed orders.

  BUSINESS INSIGHT:
  A lower average processing time signals faster fulfilment and
  better courier efficiency. Tracking this over time reveals
  whether operational changes are improving speed.

  WHY IT MATTERS:
  Speed of delivery is a top driver of customer satisfaction.
  Operations teams use this to set and monitor SLA targets.
*/


-- ============================================================
-- KPI 2: ORDER FULFILLMENT RATE (%)
-- ============================================================

SELECT
    COUNT(*)                                        AS total_orders,
    SUM(CASE WHEN order_status = 'Delivered'
             THEN 1 ELSE 0 END)                     AS delivered_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'Delivered'
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    )                                               AS fulfillment_rate_pct
FROM orders;

/*
  WHAT IT DOES:
  Calculates what percentage of all placed orders were
  successfully delivered.

  BUSINESS INSIGHT:
  A high fulfillment rate (e.g., > 85%) indicates a healthy
  and reliable delivery operation. Drops in this metric trigger
  root-cause investigations.

  WHY IT MATTERS:
  This is the single most important headline KPI for any
  logistics or operations team — it directly reflects the
  customer experience.
*/


-- ============================================================
-- KPI 3: CANCELLATION RATE (%)
-- ============================================================

SELECT
    COUNT(*)                                         AS total_orders,
    SUM(CASE WHEN order_status = 'Cancelled'
             THEN 1 ELSE 0 END)                      AS cancelled_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'Cancelled'
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    )                                                AS cancellation_rate_pct
FROM orders;

/*
  WHAT IT DOES:
  Measures what proportion of orders are cancelled before
  delivery is attempted.

  BUSINESS INSIGHT:
  High cancellation rates may indicate pricing issues,
  long wait times, or poor UX. Segmenting by location or
  time-of-day can expose the root cause.

  WHY IT MATTERS:
  Each cancelled order is lost revenue and a wasted
  courier allocation. Reducing cancellations improves
  both revenue and operational efficiency.
*/


-- ============================================================
-- KPI 4: DELIVERY SLA COMPLIANCE (SLA = 60 minutes)
-- ============================================================

SELECT
    SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                                                     AS total_delivered,
    SUM(
        CASE
            WHEN order_status = 'Delivered'
             AND TIMESTAMPDIFF(MINUTE, order_time, delivery_time) <= 60
            THEN 1 ELSE 0
        END
    )                                                AS within_sla,
    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Delivered'
                 AND TIMESTAMPDIFF(MINUTE, order_time, delivery_time) <= 60
                THEN 1 ELSE 0
            END
        ) * 100.0
        / NULLIF(SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END), 0),
        2
    )                                                AS sla_compliance_pct
FROM orders;

/*
  WHAT IT DOES:
  Calculates what percentage of delivered orders met the
  60-minute SLA target. Adjust the threshold as needed.

  BUSINESS INSIGHT:
  SLA compliance is a contractual and customer-experience
  metric. Falling below the target (e.g., < 90%) is a
  red flag that requires immediate operational attention.

  WHY IT MATTERS:
  Operations teams are often held to SLA agreements with
  clients or internal stakeholders. This KPI is used in
  performance reviews and vendor contracts.
*/


-- ============================================================
-- KPI 5: AVERAGE ORDER VALUE (AOV)
-- ============================================================

SELECT
    ROUND(AVG(order_value), 2)   AS avg_order_value,
    ROUND(MIN(order_value), 2)   AS min_order_value,
    ROUND(MAX(order_value), 2)   AS max_order_value,
    ROUND(SUM(order_value), 2)   AS total_revenue
FROM orders
WHERE order_status = 'Delivered';

/*
  WHAT IT DOES:
  Computes the average, minimum, maximum, and total revenue
  from all successfully delivered orders.

  BUSINESS INSIGHT:
  AOV helps assess whether promotions, pricing changes, or
  new product categories are impacting order value. Rising
  AOV with stable volume = healthy revenue growth.

  WHY IT MATTERS:
  Finance and operations teams use AOV to forecast revenue
  and measure the impact of commercial strategies.
*/


-- ============================================================
-- KPI 6: ORDERS PER LOCATION
-- ============================================================

SELECT
    location,
    COUNT(*)                                          AS total_orders,
    SUM(CASE WHEN order_status = 'Delivered'
             THEN 1 ELSE 0 END)                       AS delivered,
    SUM(CASE WHEN order_status = 'Cancelled'
             THEN 1 ELSE 0 END)                       AS cancelled,
    SUM(CASE WHEN order_status = 'Failed'
             THEN 1 ELSE 0 END)                       AS failed,
    ROUND(SUM(order_value), 2)                        AS total_order_value,
    ROUND(AVG(order_value), 2)                        AS avg_order_value
FROM orders
GROUP BY location
ORDER BY total_orders DESC;

/*
  WHAT IT DOES:
  Breaks down order volume, outcomes, and value by city/location.

  BUSINESS INSIGHT:
  Identifies which markets are the highest volume, highest
  revenue, and which have problematic cancellation/failure
  rates requiring localised action.

  WHY IT MATTERS:
  Enables regional ops teams to focus resources where demand
  is highest and where service failures are most acute.
*/


-- ============================================================
-- KPI 7: ORDERS PER COURIER
-- ============================================================

SELECT
    courier_id,
    COUNT(*)                                          AS total_orders,
    SUM(CASE WHEN order_status = 'Delivered'
             THEN 1 ELSE 0 END)                       AS delivered,
    SUM(CASE WHEN order_status = 'Cancelled'
             THEN 1 ELSE 0 END)                       AS cancelled,
    SUM(CASE WHEN order_status = 'Failed'
             THEN 1 ELSE 0 END)                       AS failed,
    ROUND(
        SUM(CASE WHEN order_status = 'Delivered'
                 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                                 AS delivery_success_rate_pct,
    ROUND(
        AVG(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)), 2
    )                                                 AS avg_delivery_time_mins
FROM orders
GROUP BY courier_id
ORDER BY delivery_success_rate_pct DESC;

/*
  WHAT IT DOES:
  Summarises each courier's workload, success rate, and
  average delivery time.

  BUSINESS INSIGHT:
  Quickly surfaces top and bottom performers. Couriers with
  high failure rates or slow delivery times may need
  retraining, route reassignment, or further investigation.

  WHY IT MATTERS:
  Courier performance directly drives customer experience
  and SLA compliance. This is a key input for HR and
  operations reviews.
*/
