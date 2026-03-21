CREATE DATABASE IF NOT EXISTS ops_dashboard;
USE ops_dashboard;
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id        INT             NOT NULL AUTO_INCREMENT,
    order_time      DATETIME        NOT NULL,
    delivery_time   DATETIME        NULL,               
    order_value     DECIMAL(10, 2)  NOT NULL,
    location        VARCHAR(100)    NOT NULL,
    courier_id      VARCHAR(20)     NOT NULL,
    order_status    ENUM(
                        'Delivered',
                        'Cancelled',
                        'Failed'
                    )               NOT NULL,

  
    PRIMARY KEY (order_id),


    CONSTRAINT chk_delivery_after_order
        CHECK (delivery_time IS NULL OR delivery_time > order_time),

    CONSTRAINT chk_positive_order_value
        CHECK (order_value > 0)
);

CREATE INDEX idx_order_status   ON orders (order_status);
CREATE INDEX idx_location       ON orders (location);
CREATE INDEX idx_courier_id     ON orders (courier_id);
CREATE INDEX idx_order_time     ON orders (order_time);

