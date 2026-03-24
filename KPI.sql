USE ops_dashboard;

SELECT
    ROUND(
        AVG(TIMESTAMPDIFF(MINUTE, order_time, delivery_time)),
        2
    ) AS avg_processing_time_mins
FROM orders
WHERE order_status = 'Delivered';