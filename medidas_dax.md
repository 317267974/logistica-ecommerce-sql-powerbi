# Modelo de datos y medidas DAX

## 1. Tablas que se importan desde MySQL
| Tabla / vista | Tipo | Filas | Contenido |
|---|---|---|---|
| `vw_pedidos` | Hechos | 96,018 | Un pedido entregado por fila, con tiempos, costos, calificación y etiquetas |
| `vw_articulos` | Hechos | 109,640 | Un artículo vendido por fila, con categoría en español y flete |
| `dim_estados` | Dimensión | 27 | Estado, nombre completo y región de Brasil |
| `vw_vendedores` | Dimensión | 3,095 | Ciudad y estado de cada vendedor |
| `Calendario` | Dimensión | 608 | Se crea en Power BI con DAX (abajo) |

## 2. Tabla calendario
*Modelado → Nueva tabla*, y pega:

```dax
Calendario =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2017, 1, 1 ), DATE ( 2018, 8, 31 ) ),
    "Año", YEAR ( [Date] ),
    "Mes num", MONTH ( [Date] ),
    "Mes", FORMAT ( [Date], "mmm" ),
    "Año-Mes", FORMAT ( [Date], "yyyy-mm" ),
    "Trimestre", "T" & QUARTER ( [Date] )
)
```
Después: selecciona la tabla → *Marcar como tabla de fechas* → columna `Date`. Ordena la columna `Mes` por `Mes num`.

## 3. Relaciones (vista de Modelo)
| Desde (lado 1) | Hacia (lado muchos) | Dirección del filtro |
|---|---|---|
| `Calendario[Date]` | `vw_pedidos[fecha_compra]` | Única |
| `dim_estados[estado]` | `vw_pedidos[estado]` | Única |
| `vw_pedidos[order_id]` | `vw_articulos[order_id]` | Única |
| `vw_vendedores[seller_id]` | `vw_articulos[seller_id]` | Única |

## 4. Medidas
Crea una tabla vacía para agruparlas: *Inicio → Especificar datos*, nómbrala `_Medidas` y ahí crea cada medida con *Nueva medida*.

### Volumen
```dax
Pedidos = COUNTROWS ( vw_pedidos )

Pedidos con retraso =
CALCULATE ( [Pedidos], vw_pedidos[a_tiempo] = 0 )

Valor de productos = SUM ( vw_pedidos[valor_productos] )
```

### Cumplimiento de entrega
```dax
% Entrega a tiempo =
DIVIDE ( SUM ( vw_pedidos[a_tiempo] ), [Pedidos] )

Meta a tiempo = 0.95

% A tiempo mes anterior =
CALCULATE ( [% Entrega a tiempo], DATEADD ( Calendario[Date], -1, MONTH ) )

Variación vs mes anterior (pp) =
IF (
    NOT ISBLANK ( [% A tiempo mes anterior] ),
    ( [% Entrega a tiempo] - [% A tiempo mes anterior] ) * 100
)

% Vendedor tarde a paquetería =
DIVIDE ( SUM ( vw_pedidos[vendedor_tarde] ), [Pedidos] )
```

### Tiempos
```dax
Días de entrega promedio = AVERAGE ( vw_pedidos[dias_entrega_total] )

Días vendedor promedio = AVERAGE ( vw_pedidos[dias_procesamiento_vendedor] )

Días transporte promedio = AVERAGE ( vw_pedidos[dias_transporte] )

Días prometidos promedio = AVERAGE ( vw_pedidos[dias_prometidos] )

Holgura de la promesa (días) =
[Días prometidos promedio] - [Días de entrega promedio]
```

### Satisfacción del cliente
```dax
Calificación promedio = AVERAGE ( vw_pedidos[calificacion] )

% Calificaciones malas =
DIVIDE (
    CALCULATE ( [Pedidos], vw_pedidos[calificacion] <= 2 ),
    CALCULATE ( [Pedidos], NOT ISBLANK ( vw_pedidos[calificacion] ) )
)
```

### Costos de flete
```dax
Flete % del valor =
DIVIDE ( SUM ( vw_pedidos[costo_flete] ), SUM ( vw_pedidos[valor_productos] ) )

Flete % del valor (categoría) =
DIVIDE ( SUM ( vw_articulos[flete] ), SUM ( vw_articulos[precio] ) )
```

### Formato condicional (semáforo)
```dax
Color cumplimiento =
SWITCH (
    TRUE (),
    [% Entrega a tiempo] >= 0.95, "#2E7D32",   -- verde: cumple la meta
    [% Entrega a tiempo] >= 0.90, "#F9A825",   -- amarillo: en riesgo
    "#C62828"                                   -- rojo: no cumple
)
```
Úsala en *Formato → Columnas/Barras → Color → fx → Valor del campo → Color cumplimiento*.

## 5. Formatos
- Medidas con `%` → *Porcentaje*, 1 decimal.
- Días y calificación → *Número decimal*, 1 decimal (calificación con 2).
- `Pedidos` → *Número entero* con separador de miles.
