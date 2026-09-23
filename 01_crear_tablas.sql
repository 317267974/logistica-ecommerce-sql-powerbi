-- =====================================================================
-- PROYECTO: Desempeño logístico de un e-commerce (Olist, Brasil 2016-2018)
-- Script 01: Creación de la base de datos y del modelo relacional
-- Motor: MySQL 8.0
-- Autor: Miguel Ángel Guillén Hernández
-- =====================================================================

DROP DATABASE IF EXISTS olist_logistica;
CREATE DATABASE olist_logistica CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE olist_logistica;

-- ---------------------------------------------------------------------
-- Tablas de dimensiones (catálogos)
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    customer_id              CHAR(32)     NOT NULL,
    customer_unique_id       CHAR(32)     NOT NULL,   -- identifica a la persona (un cliente puede tener varios customer_id)
    customer_zip_code_prefix CHAR(5)      NOT NULL,
    customer_city            VARCHAR(50)  NOT NULL,
    customer_state           CHAR(2)      NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE vendedores (
    seller_id              CHAR(32)    NOT NULL,
    seller_zip_code_prefix CHAR(5)     NOT NULL,
    seller_city            VARCHAR(50) NOT NULL,
    seller_state           CHAR(2)     NOT NULL,
    PRIMARY KEY (seller_id)
);

CREATE TABLE categorias (
    categoria_pt VARCHAR(60) NOT NULL,   -- nombre original en portugués
    categoria_es VARCHAR(60) NOT NULL,   -- traducción al español
    PRIMARY KEY (categoria_pt)
);

CREATE TABLE productos (
    product_id                 CHAR(32)    NOT NULL,
    product_category_name      VARCHAR(60) NULL,
    product_name_lenght        INT         NULL,   -- (sic) así viene en la fuente original
    product_description_lenght INT         NULL,
    product_photos_qty         INT         NULL,
    product_weight_g           INT         NULL,
    product_length_cm          INT         NULL,
    product_height_cm          INT         NULL,
    product_width_cm           INT         NULL,
    PRIMARY KEY (product_id)
);

-- ---------------------------------------------------------------------
-- Tablas de hechos (transacciones)
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
    order_id                      CHAR(32)    NOT NULL,
    customer_id                   CHAR(32)    NOT NULL,
    order_status                  VARCHAR(15) NOT NULL,
    order_purchase_timestamp      DATETIME    NOT NULL,  -- compra
    order_approved_at             DATETIME    NULL,      -- aprobación del pago
    order_delivered_carrier_date  DATETIME    NULL,      -- entrega del vendedor a la paquetería
    order_delivered_customer_date DATETIME    NULL,      -- entrega al cliente
    order_estimated_delivery_date DATETIME    NOT NULL,  -- fecha prometida al cliente
    PRIMARY KEY (order_id),
    INDEX idx_pedidos_cliente (customer_id)
);

CREATE TABLE items_pedido (
    order_id            CHAR(32)      NOT NULL,
    order_item_id       INT           NOT NULL,   -- número de artículo dentro del pedido (1, 2, 3...)
    product_id          CHAR(32)      NOT NULL,
    seller_id           CHAR(32)      NOT NULL,
    shipping_limit_date DATETIME      NOT NULL,   -- fecha límite para que el vendedor entregue a la paquetería
    price               DECIMAL(10,2) NOT NULL,
    freight_value       DECIMAL(10,2) NOT NULL,   -- costo de flete
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_producto (product_id),
    INDEX idx_items_vendedor (seller_id)
);

CREATE TABLE pagos (
    order_id             CHAR(32)      NOT NULL,
    payment_sequential   INT           NOT NULL,
    payment_type         VARCHAR(20)   NOT NULL,
    payment_installments INT           NOT NULL,
    payment_value        DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE resenas (
    review_id               CHAR(32)      NOT NULL,
    order_id                CHAR(32)      NOT NULL,
    review_score            TINYINT       NOT NULL,   -- calificación de 1 a 5
    review_comment_title    VARCHAR(100)  NULL,
    review_comment_message  VARCHAR(1000) NULL,
    review_creation_date    DATETIME      NOT NULL,
    review_answer_timestamp DATETIME      NOT NULL,
    PRIMARY KEY (review_id, order_id),     -- en la fuente, un mismo review_id puede aparecer en varios pedidos
    INDEX idx_resenas_pedido (order_id)
);
