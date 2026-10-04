# App del agricultor (agro productor) — Etapa 5

**Objetivo:** construir la superficie del agricultor en la app móvil: publicar su catálogo, ofertar a las solicitudes de abastecimiento, cerrar la venta, publicar liquidaciones, calificar y reportar. Es el rol que hoy no existe en el cliente.

**Problema:** verificado en código el 2026-10-04: el cliente tiene un solo layout (`lib/layout/buyer.dart`) y todo `lib/features/` es del comprador. Un agricultor que entra con su cuenta cae en la vista de comprador: no puede publicar un producto, ni ver pedidos, ni ofertar. El server ya soporta todo lo que necesita (catálogo con foto, inventario, ofertas, liquidaciones, transacciones, chat, calificaciones), así que el trabajo es de cliente.

**Por qué:** es el otro rol del marketplace; sin agricultores no hay catálogo ni ofertas que el comprador pueda elegir.

## Decisiones del usuario (2026-10-04)

| Punto | Decisión |
|---|---|
| Plataforma | **App móvil (Flutter)**, no la web React |
| Alcance | **Todo el ciclo del agricultor**: catálogo, ofertar, vender, liquidaciones, calificaciones y reportes |

## Principios de simplicidad (restricción dura, no adorno)

El usuario lo pidió explícitamente: sus usuarios son **personas de cierta edad y con poco acceso a la tecnología**. Toda pantalla nueva debe cumplir:

1. **Una acción principal por pantalla**, con el botón más grande que cualquier otro elemento.
2. **Ícono + palabra** siempre juntos; nunca un ícono solo ni un menú de tres puntitos como única vía.
3. **Cero jerga técnica**: nada de "score", "match", "priorizado", "liquidación" en boca del usuario. Un match es *"se cerró el trato"*; una liquidación es *"lote completo con descuento"*; una solicitud de abastecimiento es *"pedido de un comprador"*.
4. **La foto primero**: publicar un producto empieza sacando la foto, no llenando un formulario.
5. **Preguntas en lenguaje llano y respuestas de sí/no**: "¿Ya entregaste el pedido?", no "Confirmar delivery".
6. **Errores que digan qué hacer**, no qué falló.
7. **Pocas pantallas y poca profundidad**: máximo dos toques desde el inicio hasta cualquier acción frecuente.
8. **Textos y áreas táctiles grandes** (nada de letra chica; tocar tiene que ser fácil con manos de trabajo).
9. **Confirmaciones que no asusten**: nada de diálogos rojos salvo para algo destructivo de verdad.

## Alcance por slices (1 commit cada uno)

- **A1 — Entrada por rol y armazón del agricultor.** El login enruta por rol: 1 → `FarmerLayout`, 2–4 → el layout de comprador de siempre. `FarmerLayout` con cuatro pestañas grandes (Inicio, Mis productos, Pedidos, Mensajes) y "Mi cuenta" accesible desde el encabezado. Cada pestaña arranca con su estado vacío honesto.
- **A2 — Mi catálogo (RF-05).** Lista de productos (activos e inactivos) con foto, nombre, precio y cantidad; publicar un producto (foto → nombre → precio → cantidad → fecha), editar, desactivar/reactivar y renovar la fecha de expiración.
- **A3 — Pedidos para ofertar (RF-11).** Lista de pedidos de compradores abiertos, detalle del pedido y "Ofertar" (cantidad, precio por unidad, tiempo de entrega, comentario); "Mis ofertas" con su estado y la opción de retirar o editar la oferta.
- **A4 — Mis ventas (RF-12).** Los tratos cerrados, con su estado en palabras ("Acordado", "En camino", "Entregado", "Cancelado"), confirmar el inicio y la entrega con un sí/no, cancelar con motivo y entrar al chat con el comprador.
- **A5 — Lotes (RF-14).** Publicar un lote completo (producto, cantidad, precio total y por unidad, para quién es visible), ver la lista de compradores interesados y asignarlo (al primero que llegó o eligiendo uno).
- **A6 — Calificaciones y reportes (RF-15, RF-16).** Calificar al comprador de un trato entregado (1 a 5 estrellas con un toque) y reportar un pedido o un comprador.
- **A7 — Mensajes (RF-08, RF-13).** Bandeja de conversaciones del agricultor y chat, reutilizando la pantalla de chat que ya existe; hay que resolver quién es la contraparte cuando el que mira es el agricultor (hoy el chat asume comprador).

**Fuera de alcance:** la web React de `Hackaton2026/frontend` (decisión del usuario) y el panel de administración.

## Restricciones

- Testing: **decisión del usuario**, no se escriben baterías de tests nuevas. Verificación: `flutter analyze` limpio + que la suite existente siga verde + prueba en el teléfono.
- Cero comentarios en el código nuevo. Copy en español rioplatense.
- Commits por slice (Conventional Commits, en inglés). Push/PR/merge: decisión del usuario.
- Sin dependencias nuevas salvo que un slice las justifique (la cámara reutiliza `image_picker`, que ya está).
- Cuenta de demo del agricultor para probar en el teléfono: `finca.elroble@milpa.com` / `Password123!` (rol 1).

## Verificación

- Por slice: `flutter analyze` limpio + `flutter test` verde (misma cantidad de tests que antes del slice).
- Por etapa: prueba en el teléfono con la cuenta del agricultor contra el server local (docker + `make seed`), y confirmación del lado del server (log del api) de que los pedidos llegan donde tienen que llegar.

## Progreso

- 2026-10-04: feature abierta. Diagnóstico verificado (el cliente no tiene nada del agricultor; el server sí lo soporta) y decisiones cerradas con el usuario: app móvil y ciclo completo. Siete slices planificados, con los principios de simplicidad como restricción dura.
