-- =====================================================================
-- Script 04: Análisis de negocio — preguntas y respuestas con SQL
-- Técnicas: JOINs, CTEs, funciones de ventana (LAG, RANK), CASE,
--           agregaciones condicionales y subconsultas.
-- =====================================================================
USE olist_logistica;

-- ---------------------------------------------------------------------
-- P1. ¿Cómo está el desempeño logístico general?
-- ---------------------------------------------------------------------
SELECT COUNT(*)                                                  AS pedidos,
       ROUND(AVG(a_tiempo) * 100, 1)                             AS pct_a_tiempo,
       ROUND(AVG(dias_entrega_total), 1)                         AS dias_entrega_prom,
       ROUND(AVG(dias_procesamiento_vendedor), 1)                AS dias_vendedor_prom,
       ROUND(AVG(dias_transporte), 1)                            AS dias_transporte_prom,
       ROUND(AVG(dias_prometidos), 1)                            AS dias_prometidos_prom,
       ROUND(SUM(costo_flete) / SUM(valor_productos) * 100, 1)   AS flete_pct_del_valor,
       ROUND(AVG(calificacion), 2)                               AS calificacion_prom
FROM pedidos_analisis;

-- ---------------------------------------------------------------------
-- P2. ¿Cómo evoluciona el cumplimiento mes a mes? (función de ventana LAG)
-- ---------------------------------------------------------------------
WITH mensual AS (
    SELECT DATE_FORMAT(fecha_compra, '%Y-%m') AS mes,
           COUNT(*)                          AS pedidos,
           ROUND(AVG(a_tiempo) * 100, 1)     AS pct_a_tiempo,
           ROUND(AVG(dias_entrega_total), 1) AS dias_entrega
    FROM pedidos_analisis
    GROUP BY mes
)
SELECT mes,
       pedidos,
       pct_a_tiempo,
       ROUND(pct_a_tiempo - LAG(pct_a_tiempo) OVER (ORDER BY mes), 1) AS cambio_vs_mes_anterior,
       dias_entrega
FROM mensual
ORDER BY mes;

-- ---------------------------------------------------------------------
-- P3. ¿Qué estados tienen peor cumplimiento? (RANK, mínimo 300 pedidos)
-- ---------------------------------------------------------------------
SELECT estado_cliente,
       COUNT(*)                                                 AS pedidos,
       ROUND(AVG(a_tiempo) * 100, 1)                            AS pct_a_tiempo,
       ROUND(AVG(dias_entrega_total), 1)                        AS dias_entrega,
       ROUND(SUM(costo_flete) / SUM(valor_productos) * 100, 1)  AS flete_pct,
       ROUND(AVG(calificacion), 2)                              AS calificacion,
       RANK() OVER (ORDER BY AVG(a_tiempo))                     AS ranking_peor_cumplimiento
FROM pedidos_analisis
GROUP BY estado_cliente
HAVING COUNT(*) >= 300
ORDER BY ranking_peor_cumplimiento;

-- ---------------------------------------------------------------------
-- P4. ¿Cuánto afecta un retraso a la satisfacción del cliente?
-- ---------------------------------------------------------------------
SELECT CASE
           WHEN dias_vs_promesa <= 0  THEN '1. A tiempo'
           WHEN dias_vs_promesa <= 3  THEN '2. 1 a 3 días tarde'
           WHEN dias_vs_promesa <= 7  THEN '3. 4 a 7 días tarde'
           WHEN dias_vs_promesa <= 14 THEN '4. 8 a 14 días tarde'
           ELSE                            '5. Más de 14 días tarde'
       END                                              AS rango_retraso,
       COUNT(*)                                         AS pedidos,
       ROUND(AVG(calificacion), 2)                      AS calificacion_prom,
       ROUND(AVG(calificacion <= 2) * 100, 1)           AS pct_calificacion_mala   -- 1 o 2 estrellas
FROM pedidos_analisis
WHERE calificacion IS NOT NULL
GROUP BY rango_retraso
ORDER BY rango_retraso;

-- ---------------------------------------------------------------------
-- P5. ¿Dónde está el cuello de botella: en el vendedor o en el transporte?
-- ---------------------------------------------------------------------
SELECT CASE WHEN vendedor_tarde = 1
            THEN 'Vendedor entregó tarde a paquetería'
            ELSE 'Vendedor entregó a tiempo' END   AS etapa_vendedor,
       COUNT(*)                                     AS pedidos,
       ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1) AS pct_de_pedidos,
       ROUND(AVG(a_tiempo) * 100, 1)                AS pct_entrega_a_tiempo,
       ROUND(AVG(dias_transporte), 1)               AS dias_transporte_prom
FROM pedidos_analisis
GROUP BY etapa_vendedor;

-- ---------------------------------------------------------------------
-- P6. ¿Qué vendedores generan más retrasos? (mínimo 100 pedidos)
-- ---------------------------------------------------------------------
WITH pedidos_vendedor AS (
    SELECT DISTINCT i.seller_id, pa.order_id, pa.a_tiempo, pa.vendedor_tarde
    FROM items_pedido i
    JOIN pedidos_analisis pa ON pa.order_id = i.order_id
)
SELECT pv.seller_id,
       v.seller_state                          AS estado_vendedor,
       COUNT(*)                                AS pedidos,
       ROUND(AVG(pv.vendedor_tarde) * 100, 1)  AS pct_envio_tarde_a_paqueteria,
       ROUND(AVG(pv.a_tiempo) * 100, 1)        AS pct_entrega_a_tiempo
FROM pedidos_vendedor pv
JOIN vendedores v ON v.seller_id = pv.seller_id
GROUP BY pv.seller_id, v.seller_state
HAVING COUNT(*) >= 100
ORDER BY pct_envio_tarde_a_paqueteria DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- P7. ¿Qué categorías tienen el flete más caro en proporción a su valor?
-- ---------------------------------------------------------------------
SELECT COALESCE(cat.categoria_es, 'Sin categoría')               AS categoria,
       COUNT(DISTINCT i.order_id)                                AS pedidos,
       ROUND(SUM(i.freight_value) / SUM(i.price) * 100, 1)       AS flete_pct_del_valor,
       ROUND(AVG(p.product_weight_g) / 1000, 1)                  AS peso_prom_kg
FROM items_pedido i
JOIN pedidos_analisis pa ON pa.order_id = i.order_id
JOIN productos p         ON p.product_id = i.product_id
LEFT JOIN categorias cat ON cat.categoria_pt = p.product_category_name
GROUP BY categoria
HAVING pedidos >= 500
ORDER BY flete_pct_del_valor DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- P8. ¿La fecha prometida es realista? (holgura entre promesa y entrega real)
-- ---------------------------------------------------------------------
SELECT ROUND(AVG(dias_prometidos), 1)                        AS dias_prometidos_prom,
       ROUND(AVG(dias_entrega_total), 1)                     AS dias_reales_prom,
       ROUND(AVG(dias_prometidos - dias_entrega_total), 1)   AS holgura_prom_dias,
       ROUND(AVG(dias_vs_promesa <= -10) * 100, 1)           AS pct_llega_10_o_mas_dias_antes
FROM pedidos_analisis;

-- ---------------------------------------------------------------------
-- P9. ¿Los envíos a otro estado se retrasan más que los locales?
-- ---------------------------------------------------------------------
WITH ruta AS (
    SELECT pa.order_id, pa.a_tiempo, pa.dias_entrega_total, pa.costo_flete, pa.valor_productos,
           MAX(CASE WHEN v.seller_state <> pa.estado_cliente THEN 1 ELSE 0 END) AS foraneo
    FROM pedidos_analisis pa
    JOIN items_pedido i ON i.order_id = pa.order_id
    JOIN vendedores v   ON v.seller_id = i.seller_id
    GROUP BY pa.order_id, pa.a_tiempo, pa.dias_entrega_total, pa.costo_flete, pa.valor_productos
)
SELECT CASE WHEN foraneo = 1 THEN 'Envío a otro estado' ELSE 'Envío dentro del mismo estado' END AS tipo_envio,
       COUNT(*)                                                 AS pedidos,
       ROUND(AVG(a_tiempo) * 100, 1)                            AS pct_a_tiempo,
       ROUND(AVG(dias_entrega_total), 1)                        AS dias_entrega,
       ROUND(SUM(costo_flete) / SUM(valor_productos) * 100, 1)  AS flete_pct
FROM ruta
GROUP BY tipo_envio;
