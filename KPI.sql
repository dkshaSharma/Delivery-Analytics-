USE ops_dashboard;

SELECT
    ROUND(
        AVG(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)),
        2
    ) AS avg_processing_time_mins
FROM orders
WHERE order_status = 'Delivered';

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
