# 🚚 Desempeño logístico de un e-commerce: ¿dónde y por qué se retrasan las entregas?
### SQL (MySQL) + Power BI · 96,018 pedidos · Brasil 2017–2018

**Resultado principal:** el 93.2% de los pedidos llega a tiempo, pero un retraso le cuesta caro a la empresa: la calificación del cliente cae de **4.29 a 2.27 estrellas**, y con 4 a 7 días de retraso **el 68% de los clientes califica con 1 o 2 estrellas**. Cuando el vendedor entrega tarde a la paquetería, el riesgo de retraso se multiplica por **3.9**.

![Resumen ejecutivo](imagenes/01_resumen_ejecutivo.png)

---

## 🎯 Problema de negocio
Olist, un marketplace brasileño, conecta a miles de vendedores con clientes en todo el país. El área de operaciones necesita responder:
1. ¿Qué tan bien cumplimos la fecha de entrega prometida y cómo evoluciona?
2. ¿En qué estados y en qué etapa (vendedor o transporte) se generan los retrasos?
3. ¿Cuánto afecta un retraso a la satisfacción del cliente?
4. ¿Dónde es más caro el flete y qué tan realista es la fecha que prometemos?

## 📁 Datos
- **Fuente:** [Brazilian E-Commerce Public Dataset by Olist](https://github.com/olist/work-at-olist-data) (licencia MIT): 99,441 pedidos reales anonimizados, de sep-2016 a oct-2018.
- **8 tablas relacionadas:** pedidos, artículos, clientes, vendedores, productos, pagos, reseñas y categorías (traducidas al español para este proyecto).

## 🧹 Limpieza y validación (SQL)
| Paso | Regla | Pedidos eliminados | Pedidos restantes |
|---|---|---|---|
| 0 | Datos originales | — | 99,441 |
| 1 | Solo pedidos entregados y con fechas de entrega completas | 2,972 | 96,469 |
| 2 | Solo meses completos (ene-2017 a ago-2018); 2016 y sep–oct 2018 tienen muy pocos pedidos | 267 | 96,202 |
| 3 | Sin fechas en orden imposible (p. ej. entrega a paquetería antes de la compra) | 184 | 96,018 |

Además: 547 pedidos con varias reseñas → calificación promediada por pedido; 610 productos sin categoría → etiquetados como "Sin categoría".

**Resultado:** 96,018 pedidos válidos para el análisis (96.6% del total).

## 🛠️ Proceso
```
CSV (8 tablas) → MySQL: modelo relacional con llaves primarias e índices
               → Validación de calidad de datos y tabla limpia (CTEs)
               → 9 preguntas de negocio con SQL (JOINs, CTEs, LAG, RANK)
               → Vistas en esquema estrella → Power BI (DAX) → Dashboard de 4 páginas
```

| Archivo | Qué hace |
|---|---|
| [`sql/01_crear_tablas.sql`](sql/01_crear_tablas.sql) | Crea la base de datos y 8 tablas con llaves e índices |
| [`sql/02_cargar_datos.sql`](sql/02_cargar_datos.sql) | Carga los CSV con `LOAD DATA`, convierte vacíos en `NULL` |
| [`sql/03_limpieza_validacion.sql`](sql/03_limpieza_validacion.sql) | Diagnóstico de calidad y tabla limpia con métricas por pedido |
| [`sql/04_analisis_kpis.sql`](sql/04_analisis_kpis.sql) | 9 preguntas de negocio respondidas con SQL |
| [`sql/05_vistas_powerbi.sql`](sql/05_vistas_powerbi.sql) | Vistas y dimensión de estados para Power BI |
| [`powerbi/medidas_dax.md`](powerbi/medidas_dax.md) | Modelo, relaciones y 18 medidas DAX |
| [`powerbi/diseno_dashboard.md`](powerbi/diseno_dashboard.md) | Diseño de las 4 páginas del dashboard |

## 📈 Hallazgos
### 1. Un retraso destruye la satisfacción del cliente
| Retraso vs. fecha prometida | Pedidos | Calificación promedio | % con 1–2 estrellas |
|---|---|---|---|
| A tiempo | 89,001 | 4.29 | 9.2% |
| 1 a 3 días | 1,850 | 3.29 | 32.2% |
| 4 a 7 días | 1,746 | 2.10 | 67.6% |
| 8 a 14 días | 1,446 | 1.67 | 80.1% |
| Más de 14 días | 1,333 | 1.73 | 78.2% |

### 2. El vendedor es un cuello de botella controlable
- El **8.9%** de los pedidos se entrega tarde a la paquetería. En esos pedidos, el cumplimiento cae de **94.6% a 78.9%**: el riesgo de retraso se multiplica por 3.9.
- Unos pocos vendedores con volumen alto envían tarde a la paquetería **entre 32% y 51%** de sus pedidos.

### 3. El Nordeste concentra los peores resultados
| Región | Pedidos | % a tiempo | Días de entrega | Flete % del valor |
|---|---|---|---|---|
| Nordeste | 9,002 | **87.2%** | 20.0 | 21.8% |
| Norte | 1,789 | 91.4% | 22.6 | 22.7% |
| Centro-Oeste | 5,596 | 93.4% | 15.0 | 17.7% |
| Sudeste | 65,904 | 93.9% | 10.7 | 15.2% |
| Sur | 13,727 | 94.1% | 14.0 | 17.7% |

Alagoas (78.5%) y Maranhão (82.4%) tienen el peor cumplimiento. **Rio de Janeiro**, el segundo mercado (12,291 pedidos), solo cumple el **87.8%** frente al 95.5% de São Paulo.

### 4. Los picos de demanda rompen el cumplimiento
El cumplimiento cayó a **87.6% en noviembre de 2017** (Black Friday) y a **81.0% en marzo de 2018**, frente a un nivel habitual de 95–97%.

### 5. La fecha prometida es demasiado conservadora
Se prometen **24.3 días** en promedio, pero la entrega real toma **12.5**. El **64%** de los pedidos llega 10 o más días antes de lo prometido.

### 6. Enviar a otro estado duplica el tiempo
Los envíos a otro estado (64% de los pedidos) tardan **15.1 días** contra 7.9 de los locales, y su flete representa el **18.3%** del valor contra 13.0%.

## 💡 Recomendaciones
1. **Monitorear a los vendedores** con un KPI de "entrega a paquetería a tiempo" y alertas para quienes superen el 20% de envíos tardíos.
2. **Reforzar la capacidad logística** del Nordeste y de Rio de Janeiro (centros de distribución regionales o acuerdos con paqueterías locales).
3. **Planear capacidad para temporadas pico** (Black Friday) con 4 a 6 semanas de anticipación.
4. **Ajustar la fecha prometida** por región: una promesa más corta, pero realista, puede mejorar la conversión sin afectar el cumplimiento.
5. **Contactar de forma proactiva** a los clientes con pedidos retrasados, porque desde el cuarto día de retraso la mayoría deja una mala calificación.

## ▶️ Cómo reproducirlo
1. Instala MySQL 8.0 y Power BI Desktop (ambos gratuitos).
2. Copia la carpeta `datos/` a `C:/olist/datos/`.
3. Ejecuta los scripts de `sql/` en orden (01 → 05) en MySQL Workbench.
4. En Power BI: *Obtener datos → Base de datos MySQL* → servidor `localhost`, base `olist_logistica` → importa `vw_pedidos`, `vw_articulos`, `vw_vendedores` y `dim_estados`.
5. Crea el calendario, las relaciones y las medidas de [`powerbi/medidas_dax.md`](powerbi/medidas_dax.md).

---
**Autor:** Miguel Ángel Guillén Hernández · Analista de Datos y BI · [LinkedIn](https://linkedin.com/in/miguel-angel-guillen-hernandez) · [GitHub](https://github.com/317267974)
