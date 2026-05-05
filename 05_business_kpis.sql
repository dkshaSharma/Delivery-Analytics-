-- ============================================================
-- PROJECT: Operations Performance Metrics Dashboard
-- FILE:    05_business_kpis.sql
-- DESC:    Executive-level business KPI queries designed to
--          produce insights ready for dashboards and reports
-- ============================================================

USE ops_dashboard;

-- ============================================================
-- BUSINESS KPI 1: DAILY DELIVERY SUCCESS RATE
-- ============================================================

SELECT
    DATE(order_time)               AS order_date,
    COUNT(*)                       AS total_orders,
    SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                                   AS delivered,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
                                   AS cancelled,
    SUM(CASE WHEN order_status = 'Failed'    THEN 1 ELSE 0 END)
                                   AS failed,
    ROUND(
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                              AS success_rate_pct,
    CASE
        WHEN SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
             * 100.0 / COUNT(*) >= 85  THEN '✅ Target Met'
        WHEN SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
             * 100.0 / COUNT(*) >= 70  THEN '⚠️  Below Target'
        ELSE                                '🔴 Critical'
    END                            AS daily_target_status
FROM orders
GROUP BY DATE(order_time)
ORDER BY order_date;

/*
  WHAT IT DOES:
  Shows delivery success rate for each operational day,
  with a traffic-light status indicator vs. the 85% target.

  BUSINESS INSIGHT:
  Operations managers use this view in daily stand-ups to
  review the previous day's performance and identify dates
  that need post-mortem analysis.

  WHY IT MATTERS:
  Daily visibility into success rates prevents small issues
  from becoming chronic operational problems.
*/


-- ============================================================
-- BUSINESS KPI 2: WEEKLY DELIVERY TIME TREND
-- ============================================================

SELECT
    WEEK(order_time, 1)                                      AS week_number,
    MIN(DATE(order_time))                                    AS week_start,
    COUNT(*)                                                 AS delivered_orders,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)), 2)
                                                             AS avg_delivery_mins,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)), 2)
                                                             AS fastest_delivery_mins,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)), 2)
                                                             AS slowest_delivery_mins,
    SUM(CASE
            WHEN TIMESTAMPDIFF(MINUTE, order_time, delivery_time) <= 60
            THEN 1 ELSE 0
        END)                                                 AS within_sla_count,
    ROUND(
        SUM(CASE
                WHEN TIMESTAMPDIFF(MINUTE, order_time, delivery_time) <= 60
                THEN 1 ELSE 0
            END) * 100.0 / COUNT(*),
        2
    )                                                        AS sla_compliance_pct
FROM orders
WHERE order_status = 'Delivered'
GROUP BY WEEK(order_time, 1)
ORDER BY week_number;

/*
  WHAT IT DOES:
  Aggregates delivery performance by week — including average,
  fastest, and slowest delivery times, plus SLA compliance.

  BUSINESS INSIGHT:
  A rising avg_delivery_mins trend week-over-week signals
  growing operational strain — perhaps due to higher volumes,
  courier shortages, or routing problems.

  WHY IT MATTERS:
  Weekly granularity smooths out daily noise and is the
  standard reporting cadence for most ops teams.
*/


-- ============================================================
-- BUSINESS KPI 3: TOP PERFORMING LOCATIONS
-- ============================================================

SELECT
    location,
    COUNT(*)                                                 AS total_orders,
    ROUND(SUM(order_value), 2)                               AS total_revenue,
    ROUND(AVG(order_value), 2)                               AS avg_order_value,
    ROUND(
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                        AS fulfillment_rate_pct,
    DENSE_RANK() OVER (ORDER BY SUM(order_value) DESC)       AS revenue_rank,
    DENSE_RANK() OVER (
        ORDER BY SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                 * 100.0 / COUNT(*) DESC
    )                                                        AS fulfillment_rank
FROM orders
GROUP BY location
ORDER BY revenue_rank;

/*
  WHAT IT DOES:
  Ranks all locations by both revenue generated and fulfillment
  rate using DENSE_RANK() window functions.

  BUSINESS INSIGHT:
  A location ranked #1 in revenue but #4 in fulfillment has a
  service quality problem in its highest-value market —
  this demands immediate attention.

  WHY IT MATTERS:
  Dual-ranking surfaces locations that appear to be performing
  well in one dimension while hiding problems in another.
*/


-- ============================================================
-- BUSINESS KPI 4: FAILED ORDER ANALYSIS
-- ============================================================

SELECT
    location,
    courier_id,
    COUNT(*)                                                 AS total_orders,
    SUM(CASE WHEN order_status = 'Failed' THEN 1 ELSE 0 END)
                                                             AS failed_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'Failed' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                        AS failure_rate_pct,
    ROUND(
        AVG(CASE WHEN order_status = 'Failed' THEN order_value END), 2
    )                                                        AS avg_failed_order_value,
    ROUND(
        SUM(CASE WHEN order_status = 'Failed' THEN order_value ELSE 0 END), 2
    )                                                        AS total_lost_revenue
FROM orders
GROUP BY location, courier_id
HAVING failed_orders > 0
ORDER BY failure_rate_pct DESC;

/*
  WHAT IT DOES:
  Identifies which location + courier combinations have
  the highest failure rates and quantifies the revenue lost.

  BUSINESS INSIGHT:
  A specific courier failing repeatedly in one location may
  indicate a routing issue, local access problem, or
  individual performance problem requiring HR follow-up.

  WHY IT MATTERS:
  Failed orders represent both direct revenue loss and
  indirect costs (refunds, re-delivery, customer churn).
  Pinpointing failure hotspots enables targeted fixes.
*/


-- ============================================================
-- BUSINESS KPI 5: COURIER PERFORMANCE RANKING (FULL REPORT)
-- ============================================================

SELECT
    courier_id,
    total_assigned,
    delivered,
    cancelled,
    failed,
    ROUND(delivery_rate_pct, 2)                              AS delivery_rate_pct,
    ROUND(cancellation_rate_pct, 2)                          AS cancellation_rate_pct,
    ROUND(failure_rate_pct, 2)                               AS failure_rate_pct,
    ROUND(avg_delivery_mins, 2)                              AS avg_delivery_mins,
    ROUND(total_revenue_delivered, 2)                        AS total_revenue_delivered,
    RANK() OVER (ORDER BY delivery_rate_pct DESC,
                          avg_delivery_mins   ASC)           AS overall_rank,
    CASE
        WHEN delivery_rate_pct >= 85 AND avg_delivery_mins <= 55
             THEN 'Top Performer'
        WHEN delivery_rate_pct >= 70
             THEN 'Meets Expectations'
        ELSE 'Needs Improvement'
    END                                                      AS performance_category
FROM (
    SELECT
        courier_id,
        COUNT(*)                                             AS total_assigned,
        SUM(CASE WHEN order_status = 'Delivered'  THEN 1 ELSE 0 END) AS delivered,
        SUM(CASE WHEN order_status = 'Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
        SUM(CASE WHEN order_status = 'Failed'     THEN 1 ELSE 0 END) AS failed,
        SUM(CASE WHEN order_status = 'Delivered'  THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)                               AS delivery_rate_pct,
        SUM(CASE WHEN order_status = 'Cancelled'  THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)                               AS cancellation_rate_pct,
        SUM(CASE WHEN order_status = 'Failed'     THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*)                               AS failure_rate_pct,
        AVG(CASE WHEN order_status = 'Delivered'
                 THEN TIMESTAMPDIFF(MINUTE, order_time, delivery_time)
                 END)                                        AS avg_delivery_mins,
        SUM(CASE WHEN order_status = 'Delivered'
                 THEN order_value ELSE 0 END)                AS total_revenue_delivered
    FROM orders
    GROUP BY courier_id
) AS courier_metrics
ORDER BY overall_rank;

/*
  WHAT IT DOES:
  Produces a comprehensive courier performance report combining
  workload, all outcome rates, speed, and revenue delivered —
  ranked using a composite RANK() window function.

  BUSINESS INSIGHT:
  This query produces the raw data for the courier performance
  leaderboard. 'Top Performer' couriers can be used as
  benchmarks or mentors for lower-ranked couriers.

  WHY IT MATTERS:
  This is the definitive courier scorecard for management
  reviews, incentive programmes, and workforce planning.
*/


-- ============================================================
-- BUSINESS KPI 6: PEAK HOUR ANALYSIS
-- ============================================================

SELECT
    HOUR(order_time)               AS order_hour,
    COUNT(*)                       AS total_orders,
    ROUND(AVG(order_value), 2)     AS avg_order_value,
    SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                                   AS delivered,
    ROUND(
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                              AS success_rate_pct,
    CONCAT(
        LPAD(HOUR(order_time), 2, '0'), ':00 – ',
        LPAD(HOUR(order_time) + 1, 2, '0'), ':00'
    )                              AS time_window
FROM orders
GROUP BY HOUR(order_time)
ORDER BY total_orders DESC;

/*
  WHAT IT DOES:
  Aggregates order volume and success rates by hour of day to
  identify peak demand windows and off-peak troughs.

  BUSINESS INSIGHT:
  If success rates are lower during peak hours, operations
  teams may need to pre-position more couriers or adjust
  staffing schedules to handle demand spikes.

  WHY IT MATTERS:
  Workforce scheduling, courier dispatch, and SLA management
  all depend on understanding intra-day demand patterns.
*/
