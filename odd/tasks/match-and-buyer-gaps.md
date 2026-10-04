# Match tipo Tinder y huecos restantes del comprador — Etapa 4

**Objetivo:** cerrar los huecos que quedan en la vista del comprador contra el brief: el match tipo Tinder (RF-11/RF-12) con chat post-match (RF-13) y calificaciones (RF-15), liquidaciones (RF-14), reportes (RF-16) y mapa (RF-09). Incluye el trabajo de server que falta para que dos de esos huecos sean usables de punta a punta.

**Problema:** verificado en código el 2026-10-04:

1. **El cliente no tiene nada del match.** `supply_request_repository.dart` solo cubre `fetchAll`/`create`/`update`/`cancel`; no toca `supply-offers/requests/{id}`, `matches/requests/{id}/prioritized`, `matches/like|pass` ni `transactions/*`. `conversation_models.dart` tiene `matchId` pero ninguna pantalla lo usa.
2. **El server no prioriza por cercanía.** `DefaultScoreFactors` (`server/aplication/use-cases/recommendation.go:120-127`) pondera `availability` 0.35, `reputation` 0.25, `price` 0.2 y `delivery_time` 0.2. No existe factor de distancia y `OfferScoreInput` no recibe coordenadas, aunque el brief la pide como primer criterio (RF-09, RF-12, B.11).
3. **`API.md:410` está desactualizado:** afirma que el único factor configurado es `availability` con peso 1, contra el código real.
4. **El comprador no puede actuar sobre una liquidación.** Las lecturas ya funcionan (`GET /liquidations/open` público con `AuthenticateOptional`, visibilidad por rol), pero no hay endpoint de interés ni de asignación: `CanReceiveInterest()` existe en el dominio sin handler y `000031`/`000032` están reservadas sin escribir en `docs/migrations-registry.md`. RF-14 pide FCFS o selección manual.
5. **Reportes:** el comprador solo puede crear (`POST /reports/`, `target_type` `offering`|`user`, motivo 10–500). La moderación (`GET /reports/`, `PATCH /reports/{id}/action`) es solo rol 5 (admin) y no entra en este cliente.
6. **Mapa:** no hay dependencia de mapas en el cliente. Las coordenadas ya existen en el server (`server/aplication/dto/offering.go:27-28`, con `omitempty`) y `CatalogItem` ya las lee desde `/search` (`lib/features/buyer/catalog_models.dart:60-92`), pero `offering_models.dart` no las mapea.

**Por qué:** es lo último del brief que le falta a la vista del comprador. Continuidad con `odd/tasks/wholesale-flow.md` (Etapa 3, S1 + C1–C4 cerrados) y `odd/tasks/buyer-account-and-home.md` (F1–F3 cerradas).

## Decisiones del usuario (2026-10-04)

| Punto | Decisión |
|---|---|
| Ranking por cercanía | **Agregar distancia en el server** (commit propio), redistribuyendo los cuatro factores actuales |
| Tamaño del commit de match | **Partirlo en 2:** match (ofertas + priorizada + like/pass) y después transacción + chat post-match + calificaciones |
| Liquidaciones | **Agregar el interés/asignación en el server** (segundo commit de server), y después la pantalla del cliente |
| Reportes | **Solo reportar** en el cliente comprador; la moderación no entra |
| Mapa | **Mapa interactivo con `flutter_map`** (tiles de OpenStreetMap, sin API key) |

## Alcance y presupuesto (derivado de esas decisiones)

- **Server — 2 commits:** (S1) factor de distancia en el ranking + `distance_km` en el DTO + corrección de `API.md`; (S2) interés y asignación de liquidaciones (RF-14).
- **Cliente — 5 commits:** (C5) match: ofertas recibidas, shortlist priorizada y like/pass; (C6) transacción + chat post-match + calificaciones; (C7) liquidaciones; (C8) reportar publicación y perfil; (C9) mapa.

> El plan original del usuario hablaba de 1 commit de server y 4 de cliente. Al partir el match en dos y agregar el interés de liquidaciones en el server, el plan queda en **2 + 5**.

**Fuera de alcance:** app del agricultor y panel admin/auditor; notificaciones push/email, favoritos y expiración automática (prioridad futura del brief, `brief.typ:296-302`); moderación de reports (rol 5).

## Restricciones

- Cero comentarios en el código nuevo (preferencia del usuario). Decisiones importantes → Engram.
- Contrato verificado empíricamente contra el server local, no contra la doc.
- Un 401 → logout limpio hacia login, sin refresh token, como en las etapas previas.
- Commits por work unit (Conventional Commits, en inglés como el resto del historial). Push/PR/merge: decisión del usuario.
- Testing proporcional: cliente `flutter analyze` limpio + `flutter test` verde; server `go build ./...` + `go vet ./...` + `go test ./...`.

## Tareas

- [x] **S1 — Factor de distancia en el ranking de ofertas (server, 1 commit).** `distanceScoreFactor` con peso propio, helper de Haversine en el dominio, coordenadas del comprador y del agricultor en `OfferScoreInput`, `distance_km` en `PrioritizedOfferDTO`, corrección de `API.md:410`, tests. Commit `950f3a0` (incluye las coordenadas de los usuarios de demo en la semilla).
- [x] **S2 — Interés y asignación de liquidación (server, 1 commit).** Visibilidad de liquidaciones en cuatro niveles (`public`, `wholesale`, `wholesale_retail`, `wholesale_corporate`; `private` se renombra a `wholesale` porque significaba exactamente "roles 3 y 4"), `AllocationFirstCome` además de manual, tabla `liquidation_interests` + `liquidations.assigned_buyer_id`, y las tres rutas `POST /liquidations/{id}/interest`, `GET /liquidations/{id}/interests`, `POST /liquidations/{id}/assign`. Migraciones `000031` y `000032` según el plan que ya estaba en `docs/migrations-registry.md`. Commit `7c62c1b`.
- [ ] **C5 — Match: ofertas recibidas y like/pass (cliente, 1 commit).** Capa de datos de ofertas y matches; pantalla de ofertas por solicitud con la shortlist priorizada (`score` + `contributions` + `distance_km`) y Aceptar/Descartar.
- [ ] **C6 — Transacción, chat post-match y calificaciones (cliente, 1 commit).** Detalle de transacción con doble confirmación y cancelación con motivo; entrada al chat post-match; calificación mutua de una transacción completada.
- [ ] **C7 — Liquidaciones del comprador (cliente, 1 commit).** Listar lotes abiertos y ver detalle con la visibilidad por rol; interesarse en un lote contra el endpoint de S2.
- [ ] **C8 — Reportar publicación y perfil (cliente, 1 commit).** Botón de reporte en el detalle del producto y en el perfil del agricultor contra `POST /reports/`.
- [ ] **C9 — Mapa del agricultor (cliente, 1 commit).** `flutter_map` sobre OpenStreetMap en el detalle de la oferta, con las coordenadas que el DTO ya expone.
- [ ] **X1 — Rehabilitar la verificación del server (no ordenado por el usuario; queda anotado como deuda).** `go test ./...` está rojo en `develop` por dos causas ajenas a S1: (a) `tests/integration/postgres_test.go:46-64` (`WithOrderedInitScripts`) corta en `000020_create_supplier_inventory.up.sql` y nunca aplica `000021_add_user_photo.up.sql`, así que todo fixture `user.Save` muere con `column "photo_url" of relation "users" does not exist` (el `photo_url` lo escribe `userRepo.go:170`); (b) `tests/unitary/dto` sigue con la deuda aceptada `TestSupplyRequestDTOEmitsTheExactExpectedKeySet`. Sin (a) ningún test de integración puede ejercitar código nuevo, y sin (b) la suite unitaria nunca queda verde. Salida: agregar `000021` a la lista ordenada y ajustar el test del DTO al contrato real (`omitempty`).

## Verificación

- Por tarea: `go build ./...` + `go vet ./...` + `go test ./...` (server); `flutter analyze` limpio + `flutter test` verde (cliente). Test-first donde hay runner determinista y un RED observable.
- Por etapa: cadena completa en el teléfono contra el server local (docker + `make seed`), con la cuenta mayorista de demo `mayorista.elroble@milpa.com`.
- S1: verificar que `GET /matches/requests/{id}/prioritized` devuelva `distance_km` y que el orden cambie frente a dos ofertas a distinta distancia.
- S2: verificar el ciclo completo de interés → asignación (FCFS y manual) por API.

## Progreso

- 2026-10-04: **S2 completada** — commit `7c62c1b` (rama `develop`). La visibilidad pasa de `public|private` a cuatro niveles y el `LiquidationViewer` lleva el rol en vez de un booleano, tanto en el filtro SQL como en el predicado Go. `000031` renombra los datos (`private` → `wholesale`), reemplaza el `CHECK` y ensancha el de `allocation_method` a `manual|first_come`; `000032` crea `liquidation_interests` (única por `(liquidation_id, buyer_id)`, indexada por `created_at`) y agrega `assigned_buyer_id`. El dominio suma `Assign` y `AssignedBuyerID`.
  - Evidencia: `go build` y `go vet` limpios; `go test -count=1 ./tests/unitary/...` verde salvo la deuda aceptada de `tests/unitary/dto`; además `go test -count=1 ./infrastructure/... ./aplication/... ./domain/...` verde, que cubre los tests de handler y router que el comando anterior no alcanzaba.
  - **Verificación en vivo (stack docker reconstruido):** las migraciones llegaron a `000032`; `\d liquidations` muestra `assigned_buyer_id` con su FK y los `CHECK` con los cuatro niveles y `manual|first_come`. Flujo por API: interés `201`, duplicado `409`, anónimo `401`, rol 1 `403`; el dueño lee el interés con `buyer_name` ("Óscar Ramírez") y un tercero recibe `403`; una liquidación `wholesale_corporate` da `404` a un comprador rol 3 y `200` a su dueño; el `assign` manual dejó `status=assigned`, `assigned_buyer_id` y `closed_at` escritos (confirmado en la API y en la fila de Postgres).
  - Decisión PII: `LiquidationInterestDTO` expone `buyer_name` porque los nombres son públicos en este sistema (`pii_boundary_test.go` los exige en `PublicUserDTO` y el search ya expone `farmer_name`); el correo, el teléfono y la dirección no se exponen.
  - Desvío del brief de delegación, reportado por el worker: `handleLiquidationError` no existía; el mapeo vivía en `httpx.StatusCode`, fuera de las superficies. Se agregó en `handler/liquidation.go` y **todos** los errores de liquidación pasan por ahí, para no tener dos caminos de mapeo. Los tests de router siguen verdes.

- 2026-10-04: feature abierta. Diagnóstico verificado en código y decisiones cerradas con el usuario. Plan: 2 commits de server + 5 de cliente.
- 2026-10-04: **S1 completada** — commit `950f3a0` (rama `develop`, repo Hackaton2026; el `f85b784` original se enmendó para plegar la semilla). `domain.Address.DistanceKM` con Haversine (devuelve `false` si a cualquiera de las dos direcciones le faltan coordenadas) + `distanceScoreFactor` con `1/(1 + km/50)` y neutral `0.5` cuando la distancia es desconocida; `OfferScoreInput` suma `DistanceKM`/`HasDistance`; `RankOffers` resuelve la dirección del comprador desde el request y la de cada agricultor vía `UserRepository.FindByID`, una vez por proveedor distinto; `PrioritizedOfferDTO` expone `distance_km` (`omitempty`) y `contributions` pasa a cinco entradas. Pesos nuevos: distance 0.3, availability 0.25, reputation 0.2, price 0.15, delivery_time 0.1 (suman 1.0). `API.md:410` deja de mentir.
  - Evidencia: `go build ./...` y `go vet ./...` limpios; `go test -count=1 ./tests/unitary/entities/... ./tests/unitary/usecases/...` verde. Tests nuevos: par Haversine conocido, monotonía y caso neutral del factor, **inversión real del orden** cuando solo cambia la distancia, y fila de agricultor ausente. Escritos antes que la implementación (RED observado: símbolos inexistentes).
  - **Verificación independiente (`gentle-ai-verify`)**: 10/10 claims PASS con evidencia `path:line`, y re-verificación del delta posterior. Hallazgos aplicados dentro de S1: (a) un `FindByID` con `ErrNotFound` ya no vacía la shortlist completa — se cachea el resultado negativo y ese oferente queda con distancia desconocida (neutral 0.5), mientras cualquier otro error sigue siendo fatal; (b) la doc prometía `null` donde la etiqueta `omitempty` omite la clave, corregido a "se omite".
  - **Hallazgos NO aplicados, quedan anotados:** (1) un `userRepo` nil haría panic en `RankOffers`, latente porque los 6 call sites pasan repo real o fake; (2) la distancia se calcula contra la dirección del usuario agricultor y no contra las coordenadas de la oferta propias — `SupplyOffer` no tiene link a `domain.Offering`, así que es la única fuente alcanzable, pero la dirección es mutable y la distancia no queda congelada al momento de la oferta; (3) el test del camino `ErrNotFound` no fija la acumulación de disponibilidad/precio (todas las inventario valen 100 en el fixture), así que un `continue` que la salteara no sería detectado por test; (4) nada asegura la serialización JSON real de `distance_km` (la coincidencia doc↔etiqueta se verificó por inspección).
  - **Preflight de revisión nativa (`inspect`):** `action: start`, `fresh_target_ready`, linaje ofrecido `review-d96532bee19774ef`… **pero el candidato que ofrece el proveedor es el repo entero**: `base-ref ef063bb` (merge del PR #37) con `committed-only`, o sea **148 commits, 362 archivos y 49.437 líneas** (`git diff --shortstat ef063bb..HEAD`). No es un work unit y no se arrancó ninguna revisión: la decisión de alcance queda para el usuario. Acotar el rango al commit de S1 con el `baseRef` documentado choca con que la autoridad ofrecida ya viene ligada a otro `target_identity`.
  - **Verificación en vivo por API (2026-10-04, stack docker reconstruido con el commit nuevo):** login `mayorista.elroble@milpa.com` → `GET /supply-requests/` (3 solicitudes: abierta, cancelada, completada) → `GET /matches/requests/fe3bc947…/prioritized`. **Primer resultado: `distance_km` ausente y contribución de distancia en 0.15 = 0.3 × 0.5 (neutral).** Causa investigada: la dirección del comprador del request **sí** tiene coordenadas (12.136, -86.251), pero en la base el agricultor `finca.elroble@milpa.com` está en `latitude = 0, longitude = 0` — la semilla nunca le puso coordenadas. Con `UPDATE` local de esa fila a (11.9744, -86.0942) el resultado fue: `distance_km = 24.771357385958158` (mi cálculo a mano daba 24.77 km), factor `1/(1 + 24.7714/50) = 0.668705…`, aporte ponderado `0.200611…` y score total `0.5506 = 0.20061 + 0 (availability) + 0.1 (reputation) + 0.15 (price) + 0.1 (delivery)`. Las **cinco** contribuciones salen con los pesos nuevos. El camino de distancia queda probado de punta a punta contra la API real; el hueco era de datos de demo, no de código, y quedó corregido **dentro de S1**: la semilla ahora manda coordenadas en el registro del agricultor (12.1167, -86.1667, Masate) y del mayorista (reutilizando `demoBuyerAddress()`). Los commits de server son **2** por orden del usuario, así que no hay commit aparte para esto. **Pendiente de prueba en base fresca:** la semilla saltea usuarios existentes, así que la corrección solo se puede observar recreando el volumen (se evitó para no borrar las cuentas del teléfono).
  - Nota del mismo muestreo: la oferta abierta de esa solicitud trae `available_quantity: 0` (el agricultor de demo no tiene fila de inventario para `Café pergamino` o está toda reservada), así que el factor `availability` aporta 0. Es dato de semilla preexistente, no de S1, pero el cliente C5 va a mostrar "disponible 0" en esa oferta.
  - **Bloqueante de proceso detectado por el verificador (tarea X1):** `tests/integration` está rojo en `develop` porque el arnés corta en la migración `000020` y `photo_url` (de `000021`, agregada en F3) falta; consecuencia: ningún test de integración puede ejercitar el camino nuevo de `FindByID`.
