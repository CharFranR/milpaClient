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

## Deudas y hallazgos del server (para retomar)

Todos verificados en vivo el 2026-10-04 mientras se construía esta etapa. Son correcciones chicas (una a cinco líneas cada una) y hoy limitan lo que la app puede hacer:

1. **`PATCH /offerings/{id}` borra el producto en vez de actualizarlo.** `router.go` registra `Update` y después `DeleteOffering` sobre el mismo método y ruta, y gana el segundo: probado con una oferta de descarte, el `PATCH` devuelve `200` y el `GET` siguiente da `404`. **Consecuencia:** el agricultor no puede editar ni el precio ni la cantidad de un producto publicado (RF-05 pide "crear, editar, activar y desactivar"). Arreglo: sacar la segunda línea del router.
2. **`PATCH /offerings/{id}/status` sólo desactiva, no alterna.** Verificado: llamarlo dos veces deja el producto inactivo las dos veces. **Consecuencia:** un producto desactivado no se puede volver a activar. Arreglo: que el endpoint alterno o que respete un `is_active` en el cuerpo.
3. **`POST /offerings/create2/` no puede publicar (queda como está, ya no hace falta).** El handler multipart arma el `CreateOfferingRequest` sólo con `user_id`, `type`, `name`, `description`, `price` e `image_url`, pero el caso de uso exige variedad, unidad, cantidad y categoría: probado con `curl`, responde `400 {"error":"variety is required"}`. **Resuelto por otra vía, a pedido del usuario:** se agregó `POST /images/` (commit `3597b95` del server), una subida genérica que guarda el archivo y **devuelve la ruta**, que es la que viaja en `image_url` al crear el producto. La foto del producto ya funciona sin tocar `create2`. Queda como deuda menor: ese endpoint sigue roto y la web lo usa.
4. **No hay endpoint del catálogo de unidades de medida.** La tabla `units_of_measure` existe y las categorías traen `default_unit_of_measure_id`, pero ningún endpoint devuelve su código (`kg`, `lb`, `tn`). **Consecuencia:** ni el comprador ni el agricultor pueden ver la unidad de un producto del catálogo; el agricultor publica igual (la unidad sale de la categoría) pero la lista muestra la cantidad sin unidad, y el formulario no puede dejar elegirla. Arreglo: `GET /units-of-measure` público y el código de la unidad en el DTO de la oferta.
5. **`GET /supply-offers/` no devuelve el nombre del producto** de la solicitud ofertada. **Consecuencia:** "Mis ofertas" del agricultor no sabía de qué producto se trataba; se resolvió en el cliente pidiendo `GET /supply-requests/{id}` por oferta (aceptable a esta escala, pero es una llamada extra por fila).

## Progreso

- 2026-10-04: **Foto del producto (pedido del usuario, después del cierre de la etapa).** 1 commit de server + 1 de cliente.
  - **Server `3597b95`** (empujado a `origin/develop`): `POST /images/` — Bearer, multipart con el archivo en el campo `image`, hasta 10 MB, extensión de lista blanca (`.jpg`, `.jpeg`, `.png`, `.webp`; cualquier otra se guarda como `.jpg`), nombre único con uuid, y **devuelve la ruta guardada** (`{"path":"uploads/img-<uuid>.png"}`). Se descartó arreglar `create2` a favor de esto, que es lo que propuso el usuario: subir y publicar quedan en dos pasos y cualquier cliente puede adjuntar una imagen a cualquier cosa. Verificado en vivo: subida `201` con la ruta, producto publicado con esa ruta `201` y `image_url` presente, `GET /images/<archivo>` `200 image/png`, y el producto de prueba borrado.
  - **Cliente `6c91cf9`** (empujado a `origin/feat/farmer-app`): el formulario de publicar arranca con la foto ("Mostrá cómo se ve lo que vendés. Con foto te compran más."), muestra lo elegido y lo deja cambiar; al publicar sube primero la foto y manda la ruta en `image_url`. La foto es **opcional**: sin foto el producto se publica igual y el catálogo muestra el marcador. El botón dice "Subiendo la foto…" mientras sube, y si la subida falla el agricultor queda en el formulario con un mensaje claro (no se publica sin su foto por sorpresa). Reutiliza el `PhotoPicker` de la foto de perfil (galería) y la lista ya renderizaba la imagen cuando `image_url` no viene vacío. `flutter analyze` limpio y 244 tests verdes.
  - **Pendiente:** probar en el teléfono. La cámara (sacar la foto en el momento) es un cambio chico sobre el mismo `PhotoPicker` y no se hizo para no meter un permiso nuevo antes de tu prueba.

- 2026-10-04: **Etapa 5 completa (A1 a A7) en 3 commits**, con la rama **apilada sobre la del comprador** (`feat/farmer-app` → `feat/buyer-match`), para que el APK que se prueba tenga las dos superficies juntas y para poder reutilizar los modelos del comprador en vez de duplicarlos. Verificación de toda la etapa: `flutter analyze` limpio y **244 tests verdes**; más una prueba contra la API real de los seis endpoints que usa la app del agricultor (8 productos, 2 pedidos disponibles, 4 ofertas con una aceptada, 1 lote, 2 conversaciones con una post-trato, 0 calificaciones).
  - **Commit 1 — entrada por rol y armazón.** `auth_gate.dart` enruta al agricultor por rol y resuelve el usuario en arranque en frío antes de decidir (antes cualquier sesión caía en la vista de comprador). `layout/farmer.dart` con cuatro pestañas (Inicio, Mis productos, Pedidos, Mensajes) y Mi cuenta en el encabezado.
  - **Commit 2 — catálogo y pedidos.** Publicar, listar, desactivar y renovar productos (la unidad sale de la categoría; la variedad va con `General` si no la sabe; la fecha de vencimiento y la descripción detrás de "Más datos"), y la lista de pedidos de compradores con `Ofertar` más "Mis ofertas" con el estado en palabras.
  - **Commit 3 — el resto del ciclo.** "Mis ventas" con el trato, las dos confirmaciones en palabras ("¿Ya empezó el trato?", "¿Ya entregaste el pedido?", "Cancelar el trato" con motivo obligatorio) y el chat con el comprador; "Mis lotes" con el alta del lote completo (el total se calcula solo: cantidad × precio por unidad), los interesados y la asignación (a quien elija o al primero que preguntó); calificación del comprador tras un trato entregado, reporte del comprador, la calificación propia en Mi cuenta, y la bandeja de mensajes real.
  - **Decisiones de simplicidad aplicadas:** una acción principal por pantalla (siempre el botón más grande), ícono + palabra en todas las acciones, cero jerga ("lote", "trato", "pedido"), preguntas de sí/no y textos grandes. El agricultor nunca ve las palabras "liquidación", "match", "score" ni "FIFO".
  - **Pendiente: probar en el teléfono** con `finca.elroble@milpa.com` / `Password123!` (rol 1).

