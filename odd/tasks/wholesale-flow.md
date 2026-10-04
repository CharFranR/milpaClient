# Flujo mayorista — Etapa 3 (solicitudes de abastecimiento)

**Objetivo:** abrir la Etapa 3 del cliente comprador por el primer escalón del brief: el mayorista publica solicitudes de abastecimiento (RF-10) contra el server real, y el server queda con datos de demo para poder probar la etapa en el teléfono.

**Problema:** el cliente no tiene ninguna pantalla ni capa de datos para solicitudes de abastecimiento; el FAB central del `BuyerLayout` está vacío (`onPressed: () {}`). El seed del server solo crea un agricultor con ofertas e inventario: no hay cuenta mayorista ni cadena mayorista que demostrar.

**Por qué:** es el primer ítem del roadmap de Etapa 3 y es el único vertical de la etapa que el server ya soporta completo y verificado (a diferencia de liquidaciones, que tiene un gap real de RF-14 del lado server). Continuidad con `odd/tasks/server-integration.md` (Etapas 1 y 2 cerradas).

## Alcance

- **Server (1 commit):** extender `cmd/seed` con el flujo mayorista de demo: cuenta mayorista, solicitudes de abastecimiento (multi y único proveedor), ofertas del agricultor de demo, un trato completado (match → transacción → doble confirmación) y una liquidación pública. Idempotente, mismo estilo que T11.
- **Cliente (2 commits):** capa de datos de solicitudes de abastecimiento (modelos + repositorio + tests) y pantalla "Mis solicitudes" (listar, crear, editar, cancelar) con entrada gateada a roles mayorista 3/4.

**Fuera de alcance:** ofertas recibidas, priorización, like/pass, transacciones, reseñas, liquidaciones y reportes del cliente (siguientes slices de la Etapa 3). App del agricultor y panel admin: fuera del proyecto (cliente comprador).

**Fuera de alcance en el server (por decisión, no por olvido):** el gap de RF-14 (niveles de visibilidad de liquidación —hoy solo `public|private`— y flujo de interés/asignación manual). No es necesario para este slice y no entra en el commit del server. Ver "Hallazgos" abajo.

## Restricciones

- Cero comentarios en el código (preferencia del usuario). Decisiones importantes → Engram.
- Contrato verificado empíricamente contra el server local (no contra la doc): ver "Hallazgos".
- Base URL por `--dart-define API_BASE_URL` (default `http://10.0.2.2:8080/api/v1`).
- Un 401 → logout limpio hacia login (sin refresh token), igual que en las etapas previas.
- Commits por work unit (Conventional Commits). Push/PR/merge: decisión del usuario.
- Presupuesto fijado por el usuario: **1 commit en el server**, **máximo 2 en el cliente**.

## Tareas

- [x] **S1 — Seed del flujo mayorista (server).** `cmd/seed`: cuenta mayorista `mayorista.elroble@milpa.com` (role 3, dirección completa), solicitudes de abastecimiento (una multi-proveedor con dos ofertas y una de proveedor único), ofertas del agricultor de demo por encima de `min_amount_per_provider`, un trato completado hasta `status: 2` (para que transacciones y reseñas tengan datos) y una liquidación pública. Idempotente: reutiliza lo existente y no duplica en el re-run. Evidencia: `make seed` + re-run + verificación por API.
- [x] **C1 — Capa de datos de solicitudes (cliente).** `SupplyRequest` (status como enum, unidad de medida como enum, `Address` con las claves reales del server), `SupplyRequestRepository` (`GET /supply-requests/`, `POST /supply-requests/`, `PATCH /supply-requests/{id}`, `POST /supply-requests/{id}/cancel`) y tests con `MockClient`. Test-first.
- [x] **C2 — Pantalla "Mis solicitudes" (cliente).** Listado con estados (cargando/error/vacío/datos), detalle de cada solicitud, formulario de creación, edición y cancelación; entrada desde el FAB central del `BuyerLayout` y desde una fila del perfil, ambas gateadas a roles 3/4. Widget tests.

## Decisiones de C2

- ~~**Un solo selector de unidad.**~~ **SUPERSEDIDA (ver C3).** El tipo de enum es el mismo, pero el significado no: `amount_unit` es la unidad de la cantidad total y `unit_of_measure` la unidad de cada unidad de entrega. Colapsarlos en un selector mandaba la misma unidad a los dos campos, y la lista además mostraba el total con `unit_of_measure`.
- **El formulario no depende de `SessionScope`.** No precarga departamento/municipio/dirección desde el perfil: se mantiene testeable con solo el repositorio inyectado, como `BuyerExplore` y `OfferingDetailPage`. Precargar queda como mejora.
- **El `BuyerLayout` pide el usuario una vez.** `SessionController.restore()` no carga el usuario: después de un arranque en frío `user` es null hasta que alguien lo pide (hoy lo hace solo el perfil al abrirse). Sin ese `loadUser()` el FAB no aparecería para un mayorista que nunca entra a Perfil. El pedido va guardado con bandera en `didChangeDependencies`, igual que en `profile.dart`.
- **Fechas siempre presentes.** Al crear, los dos plazos arrancan en hoy+30 y hoy+60 días y se pueden cambiar con el selector de fecha; nunca se manda `null`, para no depender del manejo de fecha cero del server.
- **El FAB abre la lista, no el formulario.** El roadmap decía "FAB central como 'Nueva solicitud'"; abrir la lista (con la acción "Nueva solicitud" arriba y editar/cancelar por fila) deja el ciclo completo a un toque y evita una pantalla huérfana. Desvío consciente del texto del roadmap.

## Corrección de semántica (C3)

**Origen:** hallazgo del usuario en la prueba e2e del teléfono. En el request **no hay dinero en ningún campo**: `total_amount`, `actual_amount`, `amount_per_unit` y `min_amount_per_provider` son cantidades (migración `000016`, `DOUBLE PRECISION`; `validateOfferAgainstRequest` compara `min_amount_per_provider` contra el `total_amount` de la oferta, que también es cantidad). El dinero vive en la oferta (`price_per_unit`): el comprador pide cantidad y el agricultor cotiza.

**Semántica confirmada por el usuario:** `total_amount` + `amount_unit` = cantidad total pedida (500 lb de maíz); `number_of_units` = en cuántas unidades se espera la entrega (100 costales); `amount_per_unit` + `unit_of_measure` = cuánto trae cada unidad (50 lb por costal).

**Decisiones del usuario:** dos selectores de unidad, fieles al DTO; **sin** campo de dinero en el request; **sin** validar la relación `total = unidades × cantidad por unidad` (el server tampoco la exige).

**Defectos introducidos en C2 a corregir:**

1. `amount_per_unit` y `min_amount_per_provider` rotulados como dinero ('Precio por unidad', 'Monto mínimo por proveedor') y renderizados con `formatPrice`.
2. Un solo selector de unidad para los dos campos, y la lista mostrando el total con `unitOfMeasure` en vez de `amountUnit`.
3. `Restante` y `comprometido` invertidos: `actual_amount` es lo **disponible** y `total − actual` lo **comprometido** (verificado: tras un match, `actual_amount` bajó de 500 a 300 con match de 200). Ninguna prueba lo cubría.
4. `requestedAmount` es un nombre engañoso para lo comprometido → `committedAmount`.

- [x] **C3 — Semántica de cantidades y dos unidades (cliente).** Formulario con dos selectores ('Unidad de la cantidad total' → `amountUnit`; 'Unidad de cada unidad de entrega' → `unitOfMeasure`) y rótulos de cantidades sin lenguaje de dinero; lista sin `formatPrice`, con la unidad correcta por línea y `Disponible`/`Comprometido` bien asignados; rename del getter a `committedAmount`; tests actualizados y cobertura nueva para los dos selectores y para la línea disponible/comprometido.

**Nota de proceso:** la decisión de C2 de colapsar los dos campos de unidad fue un error de diseño por asumir que dos campos del DTO con el mismo tipo comparten significado. Los nombres del DTO no alcanzan para inferir semántica.

**Hueco de cobertura conocido:** el test de edición no afirma que los dos selectores muestren su valor sembrado independiente (la siembra por campo está verificada por inspección en `supply_request_form.dart:62-67`). Es la primera aserción a agregar si se retoca este formulario.

## Hallazgos

### El bloque server del roadmap estaba desactualizado

De los 5 puntos anotados en `odd/tasks/server-integration.md` para la Etapa 3, **3 ya estaban en `develop`** y se verificaron contra el código:

- Rol mayorista en supply-requests: `use-cases/supply_request.go:38` (`isMayorista`) → `403` para roles 2 y 1.
- Auth opcional en las lecturas de liquidaciones: router con `AuthenticateOptional` (commit `dd3b4c8`).
- Reseñas recibidas por target: `GET /reviews?target_type=&target_id=` (commit `a1a53dd`).

Queda un gap real de RF-14, **no incluido en este slice**: los niveles de visibilidad (`CONSTRAINT valid_visibility CHECK (visibility IN ('public','private'))` en `000009_create_liquidations.up.sql`; el brief pide 4 niveles) y el flujo de interés/asignación manual (`CanReceiveInterest()` existe en el dominio pero no hay endpoint; migraciones `000031`/`000032` reservadas en `docs/migrations-registry.md` y sin escribir).

### Contrato real verificado por API (server local, docker)

Cadena mayorista completa, 4 de octubre: `login` → `POST /supply-requests/` `201` → `GET /supply-requests/available` → `POST /supply-offers/` `201` → `GET /supply-offers/requests/{id}` → `GET /matches/requests/{id}/prioritized` → `POST /matches/like/{offerID}` `201` con `{match, transaction}` → `confirm-start` ×2 → `status: 1` → `confirm-delivery` ×2 → `status: 2` → `POST /reviews/` `201` → `cancel` libera transacción, match, `actual_amount` y oferta. Casos negativos confirmados: `403` para rol 2 y rol 1 al crear solicitud, `409` con match activo al editar/cancelar, `409` en like sobre oferta ya matcheada, rechazo de competidoras en solicitud de proveedor único, `404` de liquidación privada sin token.

Quirks del contrato que la capa de datos tiene que respetar (no son bugs, son el contrato):

- `address` no tiene tags JSON: viaja con las claves del struct Go — `Department`, `Municipality`, `AddressLine`, `Latitude`, `Longitude` (capitalizadas). En la respuesta se agrega `ID`.
- `amount_unit` y `unit_of_measure` son el mismo enum entero `MeasurementOptions`: `0` = Kg, `1` = Lb, `2` = Tn. No son strings ni UUID del catálogo `units_of_measure`.
- `PATCH /supply-requests/{id}` sobrescribe todos los campos: el body tiene que mandar el estado completo o el server pone ceros.
- El envelope de toda respuesta exitosa es `{"data": ...}`.
- En `POST /supply-offers/` la clave de la unidad es `measurement` (no `unit_of_measure`) y la fecha es `delivery_day`.

## Verificación

- Por tarea: `flutter analyze` limpio + `flutter test` verde; en el server, `go build ./...` + `go vet ./...` + re-run del seed idempotente.
- Por etapa: prueba manual contra el server local (docker + `make seed`).

## Progreso

**S1 — alcance final:** en vez del par "una multi-proveedor y una de proveedor único" se sembraron **tres** solicitudes, cubriendo los tres estados que el cliente va a renderizar: abierta con oferta pendiente de like, completada (trato cerrado de punta a punta) y cancelada. Un commit (`618d6d4`, rama `develop`).

- 2026-10-04: arranca la Etapa 3. Server levantado (db/redis/elasticsearch/api) y cadena mayorista verificada por API: todo verde, sin bugs funcionales en el camino del cliente. `odd/tasks/server-integration.md` queda como registro de las Etapas 1 y 2.
- 2026-10-04: **S1 completada** — `cmd/seed/wholesale.go` (nuevo) + wiring en `cmd/seed/main.go`. Evidencia: `go build ./...` y `go vet ./...` limpios; `go test ./...` verde (incluye `tests/integration`, 46.8 s); el primer run reporta `buyer=mayorista.elroble@milpa.com (created) requests_created=3 offers_created=3 deals_completed=1 liquidations_created=1` y el re-run `requests_skipped=3` con el resto en cero. Verificación por API: las 3 solicitudes con `status` 0/1/2, la transacción del trato cerrado en `status: 2`, la liquidación pública visible para el mayorista y la priorización de la oferta abierta (`score` 0.65). Commit `618d6d4`.

**Nota sobre la base local:** la verificación por API dejó filas de prueba (cuentas `mayorista.demo@`, `minorista.demo@` y `agricultor2.*`, más una liquidación y un reporte). No contaminan esta etapa: el listado de solicitudes filtra por comprador y las liquidaciones todavía no tienen pantalla. Se limpian cuando haga falta.
- 2026-10-04: **C1 completada** — rama `feat/supply-requests`. `supply_request_models.dart` y `supply_request_repository.dart` + 16 tests con `MockClient`, escritos antes de la implementación (RED observado: nombres inexistentes). Evidencia: `flutter analyze` limpio, 16 tests focalizados verdes, 141 en la suite, cero comentarios, sin dependencias nuevas (`pubspec.yaml` intacto respecto de `main`). Verificación independiente: el revisor marcó como débiles los caminos 401 de `update`/`cancel` y se agregaron esos dos tests antes del commit. Commit `ae9c63e`.
- 2026-10-04: **C2 completada** — `supply_requests.dart` (lista + `canPublishSupplyRequests`), `supply_request_form.dart` (alta/edición), FAB gateado en `layout/buyer.dart`, sección "COMPRAS MAYORISTAS" en `profile.dart` y 18 widget tests. Evidencia: `flutter analyze` limpio, 18 tests focalizados verdes, 159 en la suite. Verificación independiente en dos pasadas: la primera pasó pero marcó tres huecos de cobertura (fallo de edición, rechazo de fecha límite posterior a la entrega, conteo de `cancelCalls`), cerrados con tres tests más y re-verificados (incluida la interacción real con el date picker).

**Riesgo de revisión:** C2 es un commit grande (dos pantallas nuevas, dos archivos existentes y ~600 líneas con tests). Si se abre PR, conviene partirlo o revisarlo por archivo.
- 2026-10-04: **C3 completada** — corrección de semántica pedida por el usuario tras la prueba e2e. Dos selectores de unidad independientes (`Unidad de la cantidad total` → `amountUnit`; `Unidad de cada unidad de entrega` → `unitOfMeasure`), cero lenguaje de dinero en las dos pantallas (`formatPrice` y el import de `catalog_models.dart` eliminados), unidad correcta por línea en la tarjeta, `Disponible`/`Comprometido` con la aritmética real (`actualAmount` vs `total − actual`) y rename `requestedAmount` → `committedAmount`. El usuario confirmó la semántica: `total_amount` es todo lo que quiere comprar y `actual_amount` lo que le falta acordar. Evidencia: `flutter analyze` limpio, 37 tests focalizados verdes, 162 en la suite, cero comentarios agregados. Verificación independiente: las 9 claims PASS, y el diff contra `e3a9493` confirma que ninguna aserción se borró sin reemplazo equivalente (solo cambios de copy, de número y de nombre del getter).
