# Diseño del dashboard (4 páginas)

**Estilo:** fondo gris muy claro (#F5F6F8), tarjetas blancas, un solo color principal (azul #1F3864) y el semáforo verde/amarillo/rojo solo para el cumplimiento. Título arriba a la izquierda y filtros (Año, Región) arriba a la derecha en todas las páginas.

---

## Página 1 — Resumen ejecutivo
**Pregunta:** ¿cómo está la operación logística en general?

```
┌──────────────────────────────────────────────────────────────┐
│ Desempeño logístico · E-commerce Brasil   [Año ▾] [Región ▾] │
├──────────┬──────────┬──────────┬──────────┬──────────────────┤
│ Pedidos  │ % a      │ Días de  │ Calif.   │ Flete % del      │
│ 96,018   │ tiempo   │ entrega  │ promedio │ valor            │
│          │ 93.2%    │ 12.5     │ 4.16     │ 16.7%            │
├──────────┴──────────┴──────────┼──────────┴──────────────────┤
│ Línea: % a tiempo por Año-Mes  │ Mapa: % a tiempo por estado │
│ + línea de meta 95%            │ (nombre_estado, color =     │
│                                │  semáforo)                  │
├────────────────────────────────┴─────────────────────────────┤
│ Columnas: Pedidos por Año-Mes                                │
└──────────────────────────────────────────────────────────────┘
```
| Visual | Campos |
|---|---|
| 5 tarjetas | Pedidos, % Entrega a tiempo, Días de entrega promedio, Calificación promedio, Flete % del valor |
| Gráfico de líneas | Eje X: `Calendario[Año-Mes]` · Y: `% Entrega a tiempo` y `Meta a tiempo` |
| Mapa coroplético (*Filled map*) | Ubicación: `dim_estados[nombre_estado]` · Color: `Color cumplimiento` · Info sobre herramientas: Pedidos, % a tiempo |
| Columnas | Eje X: `Calendario[Año-Mes]` · Y: Pedidos |

> Para el mapa: selecciona la columna `nombre_estado` → *Categoría de datos: Estado o provincia*. Si el mapa no ubica bien los estados, reemplázalo por un gráfico de barras.

## Página 2 — Retrasos y cuellos de botella
**Pregunta:** ¿dónde y por qué se retrasan los pedidos?

| Visual | Campos |
|---|---|
| Barras horizontales | Eje Y: `dim_estados[estado]` · X: `% Entrega a tiempo` · Color: `Color cumplimiento` · orden ascendente |
| Columnas agrupadas | Eje X: `vw_pedidos[etapa_vendedor]` · Y: `% Entrega a tiempo` |
| Barras apiladas | Eje Y: `dim_estados[region]` · X: `Días vendedor promedio` + `Días transporte promedio` |
| Tabla | `vw_articulos[seller_id]`, `vw_vendedores[estado_vendedor]`, Pedidos, `% Vendedor tarde a paquetería`, `% Entrega a tiempo` · filtro: Pedidos ≥ 100 · top 10 por % vendedor tarde |
| Tarjeta | `% Vendedor tarde a paquetería` |

## Página 3 — Satisfacción del cliente
**Pregunta:** ¿cuánto le cuesta un retraso a la experiencia del cliente?

| Visual | Campos |
|---|---|
| Columnas | Eje X: `vw_pedidos[rango_retraso]` · Y: `Calificación promedio` |
| Columnas | Eje X: `vw_pedidos[rango_retraso]` · Y: `% Calificaciones malas` |
| Dispersión | X: `% Entrega a tiempo` · Y: `Calificación promedio` · Detalles: `dim_estados[estado]` · Tamaño: Pedidos |
| Cuadro de texto | Hallazgo principal: "Un pedido a tiempo recibe 4.29 estrellas; con 4 a 7 días de retraso, 68% de los clientes califica con 1 o 2" |

## Página 4 — Costos de flete y promesa de entrega
**Pregunta:** ¿dónde es más caro enviar y qué tan realista es la fecha prometida?

| Visual | Campos |
|---|---|
| Barras horizontales | Eje Y: `vw_articulos[categoria]` · X: `Flete % del valor (categoría)` · filtro: top 10 |
| Columnas | Eje X: `dim_estados[region]` · Y: `Flete % del valor` |
| Columnas agrupadas | Eje X: `Calendario[Año-Mes]` · Y: `Días prometidos promedio` y `Días de entrega promedio` |
| Tarjeta | `Holgura de la promesa (días)` |

---

## Detalles que hacen la diferencia
- Todos los títulos de los gráficos deben responder una pregunta o dar un hallazgo (por ejemplo, "El Nordeste concentra los peores tiempos de entrega", no solo "% a tiempo por estado").
- Activa *Interacciones* para que al hacer clic en un estado se filtre toda la página.
- Agrega una página de *Información sobre herramientas* (tooltip) con la tendencia mensual del estado.
- Al terminar: *Archivo → Exportar → PDF* y toma capturas de cada página para el README.
