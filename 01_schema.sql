-- ============================================================
-- PROJECT: Operations Performance Metrics Dashboard
-- FILE:    01_schema.sql
-- AUTHOR:  [Your Name]
-- DATE:    2024
-- DESC:    Creates the database and core table schema
-- ============================================================

-- Create and select database
CREATE DATABASE IF NOT EXISTS ops_dashboard;
USE ops_dashboard;

-- Drop table if it exists (safe re-run)
DROP TABLE IF EXISTS orders;

-- ============================================================
-- TABLE: orders
-- Stores all order records including delivery outcome,
-- courier assignment, location, and financial data.
-- ============================================================
CREATE TABLE orders (
    order_id        INT             NOT NULL AUTO_INCREMENT,
    order_time      DATETIME        NOT NULL,
    delivery_time   DATETIME        NULL,               -- NULL if not yet delivered or failed
    order_value     DECIMAL(10, 2)  NOT NULL,
    location        VARCHAR(100)    NOT NULL,
    courier_id      VARCHAR(20)     NOT NULL,
    order_status    ENUM(
                        'Delivered',
                        'Cancelled',
                        'Failed'
                    )               NOT NULL,

    -- Constraints
    PRIMARY KEY (order_id),

    -- Ensure delivery_time is after order_time when present
    CONSTRAINT chk_delivery_after_order
        CHECK (delivery_time IS NULL OR delivery_time > order_time),

    -- Ensure order_value is positive
    CONSTRAINT chk_positive_order_value
        CHECK (order_value > 0)
);

-- ============================================================
-- INDEXES
-- Added for query performance on commonly filtered columns
-- ============================================================
CREATE INDEX idx_order_status   ON orders (order_status);
CREATE INDEX idx_location       ON orders (location);
CREATE INDEX idx_courier_id     ON orders (courier_id);
CREATE INDEX idx_order_time     ON orders (order_time);
