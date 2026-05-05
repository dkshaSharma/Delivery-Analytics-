-- ============================================================
-- PROJECT: Operations Performance Metrics Dashboard
-- FILE:    04_advanced_analysis.sql
-- DESC:    Advanced SQL techniques: Window Functions,
--          Rolling Averages, CTEs, CASE logic, Trend Analysis
-- ============================================================

USE ops_dashboard;

-- ============================================================
-- ANALYSIS 1: COURIER PERFORMANCE RANKING (WINDOW FUNCTION)
-- Uses: RANK(), PARTITION BY, AVG, COUNT, GROUP BY
-- ============================================================

SELECT
    courier_id,
    total_orders,
    delivered_orders,
    ROUND(delivery_rate_pct, 2)                              AS delivery_rate_pct,
    ROUND(avg_delivery_mins, 2)                              AS avg_delivery_mins,
    RANK() OVER (ORDER BY delivery_rate_pct DESC)            AS delivery_rate_rank,
    RANK() OVER (ORDER BY avg_delivery_mins ASC)             AS speed_rank
FROM (
    SELECT
        courier_id,
        COUNT(*)                                             AS total_orders,
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                                                             AS delivered_orders,
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)                               AS delivery_rate_pct,
        AVG(CASE WHEN order_status = 'Delivered'
                 THEN TIMESTAMPDIFF(MINUTE, order_time, delivery_time)
                 END)                                        AS avg_delivery_mins
    FROM orders
    GROUP BY courier_id
) AS courier_summary
ORDER BY delivery_rate_rank;

/*
  WHAT IT DOES:
  Ranks all couriers by delivery success rate and delivery speed
  using SQL RANK() window functions applied to aggregated data.

  BUSINESS INSIGHT:
  A courier ranked #1 in rate but #5 in speed may be reliable
  but slow. This dual-ranking surfaces nuanced performance
  profiles that a single metric would miss.

  WHY IT MATTERS:
  Operations managers use rankings like these in courier
  performance reviews, bonus allocations, and route planning.
*/


-- ============================================================
-- ANALYSIS 2: DAILY ORDER SUMMARY WITH RUNNING TOTAL
-- Uses: DATE(), SUM(), COUNT(), SUM() OVER (ORDER BY)
-- ============================================================

SELECT
    order_date,
    daily_orders,
    daily_revenue,
    ROUND(
        SUM(daily_revenue)
            OVER (ORDER BY order_date
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        2
    )                                                        AS cumulative_revenue,
    SUM(daily_orders)
        OVER (ORDER BY order_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                             AS cumulative_orders
FROM (
    SELECT
        DATE(order_time)           AS order_date,
        COUNT(*)                   AS daily_orders,
        ROUND(SUM(order_value), 2) AS daily_revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY DATE(order_time)
) AS daily_summary
ORDER BY order_date;

/*
  WHAT IT DOES:
  Shows daily order counts and revenue alongside a running
  cumulative total using a window frame clause.

  BUSINESS INSIGHT:
  Cumulative revenue tracking helps teams see whether they are
  on pace to hit monthly targets by comparing current vs
  expected trajectory at any point in the month.

  WHY IT MATTERS:
  Finance and ops teams use cumulative charts for real-time
  progress tracking in dashboards and weekly reports.
*/


-- ============================================================
-- ANALYSIS 3: 3-DAY ROLLING AVERAGE DELIVERY TIME
-- Uses: AVG() OVER with ROWS BETWEEN, window frames
-- ============================================================

SELECT
    order_date,
    ROUND(avg_delivery_mins, 2)                              AS daily_avg_mins,
    ROUND(
        AVG(avg_delivery_mins)
            OVER (ORDER BY order_date
                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
        2
    )                                                        AS rolling_3day_avg_mins
FROM (
    SELECT
        DATE(order_time)                                     AS order_date,
        AVG(TIMESTAMPDIFF(MINUTE, order_time, delivery_time))
                                                             AS avg_delivery_mins
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY DATE(order_time)
) AS daily_avg
ORDER BY order_date;

/*
  WHAT IT DOES:
  Calculates a 3-day rolling average of delivery time, smoothing
  out daily noise to expose the underlying performance trend.

  BUSINESS INSIGHT:
  A rising rolling average indicates a worsening delivery
  performance trend even when individual days look acceptable.
  This is far more reliable than day-to-day comparisons.

  WHY IT MATTERS:
  Rolling averages are a standard technique in operations
  analytics to distinguish signal from noise in time-series
  performance data.
*/


-- ============================================================
-- ANALYSIS 4: ORDER STATUS DISTRIBUTION WITH % SHARE
-- Uses: COUNT, CASE, SUM OVER (window), ROUND
-- ============================================================

SELECT
    order_status,
    status_count,
    ROUND(
        status_count * 100.0
        / SUM(status_count) OVER (),
        2
    )                                                        AS status_share_pct
FROM (
    SELECT
        order_status,
        COUNT(*) AS status_count
    FROM orders
    GROUP BY order_status
) AS status_summary
ORDER BY status_count DESC;

/*
  WHAT IT DOES:
  Shows each order status alongside its percentage share of
  all orders using a window function for the total denominator.

  BUSINESS INSIGHT:
  Gives an instant read of the health of the operation.
  If 'Failed' or 'Cancelled' together exceed 20%, it signals
  a systemic operational problem.

  WHY IT MATTERS:
  This is typically displayed as a pie/donut chart on exec
  dashboards — the underlying SQL produces the data efficiently
  in one query.
*/


-- ============================================================
-- ANALYSIS 5: LOCATION-LEVEL PERFORMANCE SCORECARD
-- Uses: CASE for tiering, AVG, COUNT, GROUP BY
-- ============================================================

SELECT
    location,
    total_orders,
    ROUND(fulfillment_rate, 2)                               AS fulfillment_rate_pct,
    ROUND(avg_order_value, 2)                                AS avg_order_value,
    ROUND(avg_delivery_mins, 2)                              AS avg_delivery_mins,
    CASE
        WHEN fulfillment_rate >= 85 AND avg_delivery_mins <= 55
             THEN 'GREEN – On Track'
        WHEN fulfillment_rate >= 70 OR avg_delivery_mins <= 65
             THEN 'AMBER – Needs Monitoring'
        ELSE 'RED – Action Required'
    END                                                      AS performance_tier
FROM (
    SELECT
        location,
        COUNT(*)                                             AS total_orders,
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)                               AS fulfillment_rate,
        AVG(order_value)                                     AS avg_order_value,
        AVG(CASE WHEN order_status = 'Delivered'
                 THEN TIMESTAMPDIFF(MINUTE, order_time, delivery_time)
                 END)                                        AS avg_delivery_mins
    FROM orders
    GROUP BY location
) AS location_summary
ORDER BY
    CASE performance_tier
        WHEN 'RED – Action Required'    THEN 1
        WHEN 'AMBER – Needs Monitoring' THEN 2
        ELSE 3
    END;

/*
  WHAT IT DOES:
  Produces a traffic-light scorecard for each location by
  combining fulfillment rate and delivery time into a
  tiered CASE classification.

  BUSINESS INSIGHT:
  Regional managers immediately see which cities need
  intervention. RED locations become the focus of
  daily ops stand-ups.

  WHY IT MATTERS:
  CASE-based tiering is a powerful technique for turning
  raw metrics into actionable, executive-ready scorecards.
*/


-- ============================================================
-- ANALYSIS 6: WEEK-OVER-WEEK TREND ANALYSIS
-- Uses: WEEK(), LAG() window function, % change calc
-- ============================================================

SELECT
    week_number,
    weekly_orders,
    weekly_revenue,
    LAG(weekly_orders)  OVER (ORDER BY week_number)          AS prev_week_orders,
    LAG(weekly_revenue) OVER (ORDER BY week_number)          AS prev_week_revenue,
    ROUND(
        (weekly_orders - LAG(weekly_orders) OVER (ORDER BY week_number))
        * 100.0
        / NULLIF(LAG(weekly_orders) OVER (ORDER BY week_number), 0),
        2
    )                                                        AS orders_wow_change_pct,
    ROUND(
        (weekly_revenue - LAG(weekly_revenue) OVER (ORDER BY week_number))
        * 100.0
        / NULLIF(LAG(weekly_revenue) OVER (ORDER BY week_number), 0),
        2
    )                                                        AS revenue_wow_change_pct
FROM (
    SELECT
        WEEK(order_time, 1)        AS week_number,
        COUNT(*)                   AS weekly_orders,
        ROUND(SUM(order_value), 2) AS weekly_revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY WEEK(order_time, 1)
) AS weekly_summary
ORDER BY week_number;

/*
  WHAT IT DOES:
  Uses LAG() to compare each week's orders and revenue against
  the prior week, computing week-over-week (WoW) % change.

  BUSINESS INSIGHT:
  WoW trends immediately show whether the business is growing,
  declining, or plateauing. A consistent negative WoW trend
  is an early warning signal for the leadership team.

  WHY IT MATTERS:
  LAG() is one of the most commonly tested window functions
  in data analyst interviews. It's also used in virtually
  every business review cadence.
*/
