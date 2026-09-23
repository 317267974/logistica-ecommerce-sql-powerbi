-- =====================================================================
-- Script 02: Carga de los archivos CSV a MySQL
-- ---------------------------------------------------------------------
-- ANTES DE EJECUTAR:
--   1. Copia la carpeta "datos" a C:/olist/datos/ (o cambia la ruta en
--      cada LOAD DATA; usa diagonales "/" aunque estés en Windows).
--   2. En MySQL Workbench, edita la conexión: pestaña "Advanced" y en
--      "Others" agrega la línea:  OPT_LOCAL_INFILE=1
--   3. Ejecuta una sola vez (como administrador/root):
--         SET GLOBAL local_infile = 1;
--   4. No abras los CSV con Excel antes de cargarlos: Excel puede
--      cambiar formatos de fecha y códigos postales.
-- =====================================================================

USE olist_logistica;

-- Clientes ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_customers_dataset.csv'
INTO TABLE clientes
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Vendedores ----------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_sellers_dataset.csv'
INTO TABLE vendedores
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Categorías (traducción al español) ----------------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/categorias_es.csv'
INTO TABLE categorias
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Productos (las celdas vacías se convierten en NULL) ------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_products_dataset.csv'
INTO TABLE productos
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @nom, @des, @fot, @pes, @lar, @alt, @anc)
SET product_category_name      = NULLIF(@cat, ''),
    product_name_lenght        = NULLIF(@nom, ''),
    product_description_lenght = NULLIF(@des, ''),
    product_photos_qty         = NULLIF(@fot, ''),
    product_weight_g           = NULLIF(@pes, ''),
    product_length_cm          = NULLIF(@lar, ''),
    product_height_cm          = NULLIF(@alt, ''),
    product_width_cm           = NULLIF(@anc, '');

-- Pedidos (fechas vacías → NULL) --------------------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_orders_dataset.csv'
INTO TABLE pedidos
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp,
 @aprobado, @paqueteria, @entregado, order_estimated_delivery_date)
SET order_approved_at             = NULLIF(@aprobado, ''),
    order_delivered_carrier_date  = NULLIF(@paqueteria, ''),
    order_delivered_customer_date = NULLIF(@entregado, '');

-- Artículos de cada pedido --------------------------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_order_items_dataset.csv'
INTO TABLE items_pedido
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Pagos ---------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_order_payments_dataset.csv'
INTO TABLE pagos
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Reseñas (los comentarios vacíos → NULL) -----------------------------
LOAD DATA LOCAL INFILE 'C:/olist/datos/olist_order_reviews_dataset.csv'
INTO TABLE resenas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score, @titulo, @mensaje,
 review_creation_date, review_answer_timestamp)
SET review_comment_title   = NULLIF(@titulo, ''),
    review_comment_message = NULLIF(@mensaje, '');

-- Verificación rápida: número de filas cargadas en cada tabla ----------
SELECT 'clientes' AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL SELECT 'vendedores',   COUNT(*) FROM vendedores
UNION ALL SELECT 'categorias',   COUNT(*) FROM categorias
UNION ALL SELECT 'productos',    COUNT(*) FROM productos
UNION ALL SELECT 'pedidos',      COUNT(*) FROM pedidos
UNION ALL SELECT 'items_pedido', COUNT(*) FROM items_pedido
UNION ALL SELECT 'pagos',        COUNT(*) FROM pagos
UNION ALL SELECT 'resenas',      COUNT(*) FROM resenas;
-- Resultado esperado: 99,441 | 3,095 | 73 | 32,951 | 99,441 | 112,650 | 103,886 | 99,224
