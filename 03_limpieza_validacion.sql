-- =====================================================================
-- Script 03: Validación de calidad de datos y tabla limpia de análisis
-- =====================================================================
USE olist_logistica;

-- ---------------------------------------------------------------------
-- PARTE A. DIAGNÓSTICO DE CALIDAD DE DATOS
-- ---------------------------------------------------------------------

-- A1. Pedidos por estatus y cuántos no tienen fecha de entrega
SELECT order_status,
       COUNT(*)                                   AS pedidos,
       SUM(order_delivered_customer_date IS NULL) AS sin_fecha_entrega
FROM pedidos
GROUP BY order_status
ORDER BY pedidos DESC;
-- Hallazgo: 96,478 pedidos "delivered"; 8 de ellos no tienen fecha de entrega.

-- A2. Fechas en orden imposible
SELECT SUM(order_delivered_carrier_date  < order_purchase_timestamp)     AS paqueteria_antes_de_compra,
       SUM(order_delivered_customer_date < order_delivered_carrier_date) AS cliente_antes_de_paqueteria
FROM pedidos;
-- Hallazgo: 166 y 23 registros inconsistentes → se excluyen del análisis.

-- A3. Meses incompletos al inicio y al final del periodo
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS mes, COUNT(*) AS pedidos
FROM pedidos
GROUP BY mes
ORDER BY mes;
-- Hallazgo: 2016 y sep-oct 2018 tienen muy pocos pedidos → se analiza ene-2017 a ago-2018.

-- A4. Pedidos sin artículos y pedidos con más de una reseña
SELECT (SELECT COUNT(*) FROM pedidos p
        WHERE NOT EXISTS (SELECT 1 FROM items_pedido i WHERE i.order_id = p.order_id)) AS pedidos_sin_articulos,
       (SELECT COUNT(*) FROM (SELECT order_id FROM resenas
                              GROUP BY order_id HAVING COUNT(*) > 1) x)              AS pedidos_con_varias_resenas;
-- Hallazgo: 775 pedidos sin artículos (cancelados/no disponibles) y 547 con varias
-- reseñas → la calificación se promedia por pedido.

-- A5. Productos sin categoría
SELECT COUNT(*) AS productos_sin_categoria FROM productos WHERE product_category_name IS NULL;
-- Hallazgo: 610 productos → se etiquetan como "Sin categoría".


-- ---------------------------------------------------------------------
-- PARTE B. TABLA LIMPIA: una fila por pedido entregado, con sus métricas
-- ---------------------------------------------------------------------
-- Reglas de limpieza:
--   1. Solo pedidos con estatus 'delivered' y con fecha de entrega.
--   2. Compras entre el 1-ene-2017 y el 31-ago-2018 (meses completos).
--   3. Se excluyen pedidos con fechas en orden imposible.
--   4. Se excluyen pedidos sin artículos.
-- Definiciones de negocio:
--   - A tiempo: el cliente recibió el pedido en o antes de la fecha prometida.
--   - Procesamiento del vendedor: días de la compra a la entrega a paquetería.
--   - Transporte: días de la paquetería a la entrega al cliente.
--   - Vendedor tarde: entregó a paquetería después de su fecha límite.

DROP TABLE IF EXISTS pedidos_analisis;

CREATE TABLE pedidos_analisis AS
WITH items AS (
    SELECT order_id,
           COUNT(*)                 AS articulos,
           SUM(price)               AS valor_productos,
           SUM(freight_value)       AS costo_flete,
           MAX(shipping_limit_date) AS fecha_limite_vendedor
    FROM items_pedido
    GROUP BY order_id
),
resenas_pedido AS (
    SELECT order_id, AVG(review_score) AS calificacion
    FROM resenas
    GROUP BY order_id
)
SELECT p.order_id,
       p.customer_id,
       c.customer_state                                   AS estado_cliente,
       DATE(p.order_purchase_timestamp)                   AS fecha_compra,
       DATE(p.order_estimated_delivery_date)              AS fecha_prometida,
       DATE(p.order_delivered_customer_date)              AS fecha_entrega,
       i.articulos,
       i.valor_productos,
       i.costo_flete,
       ROUND(TIMESTAMPDIFF(HOUR, p.order_purchase_timestamp,
             p.order_delivered_customer_date) / 24, 1)    AS dias_entrega_total,
       ROUND(TIMESTAMPDIFF(HOUR, p.order_purchase_timestamp,
             p.order_delivered_carrier_date) / 24, 1)     AS dias_procesamiento_vendedor,
       ROUND(TIMESTAMPDIFF(HOUR, p.order_delivered_carrier_date,
             p.order_delivered_customer_date) / 24, 1)    AS dias_transporte,
       DATEDIFF(p.order_estimated_delivery_date,
                p.order_purchase_timestamp)               AS dias_prometidos,
       DATEDIFF(p.order_delivered_customer_date,
                p.order_estimated_delivery_date)          AS dias_vs_promesa,   -- negativo = llegó antes
       CASE WHEN DATE(p.order_delivered_customer_date)
                 <= DATE(p.order_estimated_delivery_date)
            THEN 1 ELSE 0 END                             AS a_tiempo,
       CASE WHEN p.order_delivered_carrier_date > i.fecha_limite_vendedor
            THEN 1 ELSE 0 END                             AS vendedor_tarde,
       r.calificacion
FROM pedidos p
JOIN clientes c         ON c.customer_id = p.customer_id
JOIN items i            ON i.order_id    = p.order_id
LEFT JOIN resenas_pedido r ON r.order_id = p.order_id
WHERE p.order_status = 'delivered'
  AND p.order_delivered_customer_date IS NOT NULL
  AND p.order_delivered_carrier_date  IS NOT NULL
  AND p.order_purchase_timestamp >= '2017-01-01'
  AND p.order_purchase_timestamp <  '2018-09-01'
  AND p.order_delivered_carrier_date  >= p.order_purchase_timestamp
  AND p.order_delivered_customer_date >= p.order_delivered_carrier_date;

ALTER TABLE pedidos_analisis ADD PRIMARY KEY (order_id);

-- Resumen de la limpieza
SELECT (SELECT COUNT(*) FROM pedidos)          AS pedidos_originales,
       (SELECT COUNT(*) FROM pedidos_analisis) AS pedidos_para_analisis;
