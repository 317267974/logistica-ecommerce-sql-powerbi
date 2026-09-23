-- =====================================================================
-- Script 05: Modelo para Power BI (esquema estrella)
--   Hechos:      vw_pedidos (1 fila por pedido)
--                vw_articulos (1 fila por artículo vendido)
--   Dimensiones: dim_estados, vw_vendedores
--   (La tabla calendario se crea en Power BI con DAX.)
-- Nota: ejecuta los scripts con una conexión en UTF-8 (utf8mb4); MySQL
--       Workbench la usa por defecto, así se conservan los acentos.
-- =====================================================================
USE olist_logistica;

-- ---------------------------------------------------------------------
-- Dimensión de estados de Brasil con nombre completo y región
-- (el nombre completo permite que Power BI ubique los estados en el mapa)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS dim_estados;
CREATE TABLE dim_estados (
    estado        CHAR(2)     NOT NULL PRIMARY KEY,
    nombre_estado VARCHAR(40) NOT NULL,
    region        VARCHAR(15) NOT NULL
);

INSERT INTO dim_estados (estado, nombre_estado, region) VALUES
('AC','Acre','Norte'),               ('AL','Alagoas','Nordeste'),
('AM','Amazonas','Norte'),           ('AP','Amapá','Norte'),
('BA','Bahia','Nordeste'),           ('CE','Ceará','Nordeste'),
('DF','Distrito Federal','Centro-Oeste'), ('ES','Espírito Santo','Sudeste'),
('GO','Goiás','Centro-Oeste'),       ('MA','Maranhão','Nordeste'),
('MG','Minas Gerais','Sudeste'),     ('MS','Mato Grosso do Sul','Centro-Oeste'),
('MT','Mato Grosso','Centro-Oeste'), ('PA','Pará','Norte'),
('PB','Paraíba','Nordeste'),         ('PE','Pernambuco','Nordeste'),
('PI','Piauí','Nordeste'),           ('PR','Paraná','Sur'),
('RJ','Rio de Janeiro','Sudeste'),   ('RN','Rio Grande do Norte','Nordeste'),
('RO','Rondônia','Norte'),           ('RR','Roraima','Norte'),
('RS','Rio Grande do Sul','Sur'),    ('SC','Santa Catarina','Sur'),
('SE','Sergipe','Nordeste'),         ('SP','São Paulo','Sudeste'),
('TO','Tocantins','Norte');

-- ---------------------------------------------------------------------
-- Hechos: pedidos (con etiquetas listas para usar en los gráficos)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_pedidos AS
SELECT pa.order_id,
       pa.estado_cliente                   AS estado,
       pa.fecha_compra,
       pa.fecha_prometida,
       pa.fecha_entrega,
       pa.articulos,
       pa.valor_productos,
       pa.costo_flete,
       pa.dias_entrega_total,
       pa.dias_procesamiento_vendedor,
       pa.dias_transporte,
       pa.dias_prometidos,
       pa.dias_vs_promesa,
       pa.a_tiempo,
       pa.vendedor_tarde,
       pa.calificacion,
       CASE
           WHEN pa.dias_vs_promesa <= 0  THEN '1. A tiempo'
           WHEN pa.dias_vs_promesa <= 3  THEN '2. 1-3 días tarde'
           WHEN pa.dias_vs_promesa <= 7  THEN '3. 4-7 días tarde'
           WHEN pa.dias_vs_promesa <= 14 THEN '4. 8-14 días tarde'
           ELSE                               '5. Más de 14 días tarde'
       END                                 AS rango_retraso,
       CASE WHEN pa.vendedor_tarde = 1
            THEN 'Vendedor tarde a paquetería'
            ELSE 'Vendedor a tiempo' END   AS etapa_vendedor
FROM pedidos_analisis pa;

-- ---------------------------------------------------------------------
-- Hechos: artículos (para análisis por categoría y vendedor)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_articulos AS
SELECT i.order_id,
       i.order_item_id,
       i.seller_id,
       COALESCE(cat.categoria_es, 'Sin categoría') AS categoria,
       i.price                                     AS precio,
       i.freight_value                             AS flete,
       p.product_weight_g / 1000                   AS peso_kg
FROM items_pedido i
JOIN pedidos_analisis pa ON pa.order_id = i.order_id   -- solo pedidos del análisis
JOIN productos p         ON p.product_id = i.product_id
LEFT JOIN categorias cat ON cat.categoria_pt = p.product_category_name;

-- ---------------------------------------------------------------------
-- Dimensión: vendedores
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_vendedores AS
SELECT seller_id,
       seller_city  AS ciudad_vendedor,
       seller_state AS estado_vendedor
FROM vendedores;

-- Verificación
SELECT 'vw_pedidos' AS objeto, COUNT(*) AS filas FROM vw_pedidos
UNION ALL SELECT 'vw_articulos',  COUNT(*) FROM vw_articulos
UNION ALL SELECT 'vw_vendedores', COUNT(*) FROM vw_vendedores
UNION ALL SELECT 'dim_estados',   COUNT(*) FROM dim_estados;
