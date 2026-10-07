# Expiración de publicaciones — worker de ocultamiento + visibilidad y renovación del agricultor

**Objetivo:** cerrar el hueco del brief por el cual una publicación vencida debe ocultarse del marketplace, permitir que el agricultor vea sus publicaciones ocultas (vencidas o desactivadas) y pueda renovarlas. El vencimiento predefinido por categoría (D) queda para una segunda pasada, por decisión del usuario (2026-10-06).

**Problema:** verificado en código el 2026-10-06:

1. **No existe ocultamiento automático.** No hay worker, cron ni ticker de negocio en el server (`cmd/api/main.go` solo arranca `go hub.Run()` del WS). La expiración es un filtro lazy en SQL (`cataloguePredicate`, `server/infrastructure/adapters/secondary/repository/offering_repo.go:19`) usado solo por `FindByUserID`; nadie cambia `is_active` ni borra filas al vencer.
2. **El listado del dueño también las oculta a él.** `GET /offerings/?user_id=` aplica `cataloguePredicate`, así que el agricultor no ve sus vencidas ni sus desactivadas: el botón de renovar (que ya existe end-to-end) es inalcanzable desde la UI tras refrescar.
3. **La búsqueda del comprador no filtra vencimiento.** El índice ES (`mappings/offerings.json`) no tiene `expires_at` ni `is_active` y `buildQuery` (`search/search.go:99-139`) no filtra por ninguno; Home y Explorar pueden mostrar publicaciones vencidas y desactivadas.
4. **No hay contexto cancelable** en `main.go` (el ctx de arranque es un timeout de 10s) y el shutdown no drena goroutines.
5. **Renovar ya existe end-to-end** (endpoint `PATCH /offerings/{id}/renew`, caso de uso, entidad, botón Flutter y web); falta que sea alcanzable y que re-indexe en ES.

## Decisiones del usuario (2026-10-06)

| Punto | Decisión |
|---|---|
| Alcance de esta pasada | A+B: worker de ocultamiento + visibilidad/renovación del agricultor. D (default por categoría) segunda pasada |
| Consistencia con Elasticsearch | Variante A2: el worker borra el documento del índice y renovar re-indexa. Sin cambio de mapping ni reindex masivo |
| Quién ve las ocultas | Solo el dueño autenticado. Terceros y anónimos siguen viendo solo visibles; pedir `include_hidden` sin ser dueño devuelve 403 |

## Alcance y presupuesto

- **Server — 2 commits:** (E1) worker de expiración + consistencia ES (borrar del índice al ocultar, re-indexar al renovar); (E2) listado del dueño con ocultas.
- **Cliente — 1 commit:** (E3) sección de ocultas, rótulo "Vencido"/"Inactivo" y renovación alcanzable.
- **Previsión:** ~550-750 líneas autoradas. Estrategia de entrega `ask-on-risk`; push/PR/merge son decisión del usuario (sin PRs en alcance, no se pregunta chain strategy hasta que se abran).
- **Fuera de alcance:** D (vencimiento por categoría; requiere migración y arbitraje de numeración), reactivación de desactivados (toggle), auto-expiración de solicitudes de suministro (el brief la marca "futuro"), job externo/pg_cron y reindex de ES.

## Restricciones

- Cero comentarios en el código nuevo (preferencia del usuario). Decisiones importantes → Engram.
- Sin baterías de tests nuevas (decisión del usuario, prioritaria sobre el harness): server `go build ./...` + `go vet ./...` (vet compila los tests, así que los fakes se actualizan para no romper compilación); cliente `flutter analyze` limpio + suite existente verde.
- Conventional Commits en inglés, sin atribución de IA. Push/PR/merge: decisión del usuario.
- No tocar `.atl/` ni `frontend/package-lock.json` (modificaciones preexistentes sin commitear).

## Tareas (ruta: delegada — writer trigger: 2+ archivos no triviales por repo)

- [x] **E1 — Worker de expiración y consistencia ES (server, 1 commit).** Commit `9ae9113` (8 archivos, +132). Verificación: `go build ./...` y `go vet ./...` limpios; unitarios de usecases/entities verdes; suite completa verde en local. `DeactivateExpired(ctx, now)` en el puerto/repo (`UPDATE offerings SET is_active=false, updated_at=$2 WHERE is_active AND expires_at <= $1 RETURNING ...`); worker con ticker de 5 minutos + barrido inicial (`server/aplication/use-cases/expiry_worker.go` nuevo) que por cada oferta ocultada borra el doc de ES y purga `offerings:byuser:<uid>` y el cache de búsqueda; wiring con contexto cancelable en `cmd/api/main.go` enganchado al shutdown; `RenewOffering` re-indexa en ES; `DeactivateOffering` manual también borra el doc de ES (misma semántica de "oculto").
- [x] **E2 — Listado de ocultas para el dueño (server, 1 commit).** Commit `fd8e626` (15 archivos, +53/−24). `GetByUserID`/`FindByUserID` con `includeHidden bool`; query param `include_hidden` en `GET /offerings/?user_id=`; solo el dueño autenticado puede pedirlo (403 en cualquier otro caso); ruta con `AuthenticateOptional`; el cache wrapper no cachea la variante privada; fakes y call sites existentes actualizados para que `go vet` pase.
- [x] **E3 — Flutter: ocultas visibles y renovación (cliente, 1 commit).** Commit `8b6495d` (3 archivos, +43/−9). `flutter analyze` limpio y `flutter test` 244/244. `fetchMine` manda token y `include_hidden=true`; `FarmerProduct` parsea `expires_at`; `products.dart` separa/señala "Vencido" vs "Inactivo" y deja el botón de renovar alcanzable para las ocultas.
- [ ] **D — Vencimiento predefinido por categoría (segunda pasada, sin abrir).** Campo en categoría + migración (arbitraje de número por bloques reservados 000033-000037) + precedencia agricultor > categoría > sin vencimiento + web admin + form Flutter.

## Verificación

- E1: `go build ./...` + `go vet ./...` limpios; `go test -count=1 ./tests/unitary/usecases/... ./tests/unitary/entities/...` verde (baseline conocido; `go test ./...` sigue rojo por deudas X1: integración `postgres_test.go` y `tests/unitary/dto`).
- E2: idem + prueba manual contra el server local con dos cuentas (dueño ve ocultas; tercero recibe 403).
- E3: `flutter analyze` limpio + `flutter test` con la suite existente verde; prueba manual en el teléfono queda del usuario.
- Sin reindex de ES: la consistencia es "doc borrado al ocultar / re-indexado al renovar".

## Progreso

- 2026-10-06: feature abierta. Diagnóstico y mapa de enganche verificados con explorer; decisiones A2 y visibilidad-solo-dueño cerradas con el usuario. Plan: 2 commits de server + 1 de cliente.
- 2026-10-06: **E1 y E2 completadas (server, rama `develop`, commits `9ae9113` y `fd8e626`).** El worker barre al arrancar y cada 5 minutos, pasa `expires_at <= now` a `is_active=false` con `RETURNING`, borra el doc de ES por oferta ocultada y purga `offerings:byuser:*` + cache de búsqueda; `RenewOffering` re-indexa en ES y `DeactivateOffering` borra del índice. El listado del dueño acepta `include_hidden=true` con token y solo para el propio `user_id` (403 en cualquier otro caso), con bypass de cache. Evidencia: `go build ./...` y `go vet ./...` limpios; `go test -count=1 ./tests/unitary/usecases/... ./tests/unitary/entities/...` verde; la suite completa también quedó verde en esta máquina (la integración usa testcontainers, no la base local). Desvíos: se arreglaron dos fakes que ya rompían `go vet` en HEAD (`List` faltante en `ownershipUserRepo`/`stubUserRepo`) y se actualizó `cmd/seed/main.go` como call site de la firma; `include_hidden` acepta vacío/`true`/`1` y devuelve 400 con cualquier otro valor.
- 2026-10-06: **E3 completada (cliente, rama `feat/offering-expiry`, commit `8b6495d`).** `fetchMine` manda token + `include_hidden=true`; `FarmerProduct` parsea `expires_at` y expone `isExpired`/`isHidden`; la lista separa "Ocultos" con badge "Vencido"/"Inactivo" y deja solo "Renovar" en esas tarjetas. Evidencia: `flutter analyze` limpio y `flutter test` 244/244. Sin tests nuevos (política del usuario).
- **Follow-ups anotados:** (a) la web del productor (React) sigue llamando el endpoint público sin `include_hidden`, así que no ve ocultas todavía; (b) ofertas desactivadas manualmente antes de E1 siguen en el índice ES (el worker solo captura transiciones activo→inactivo) — limpieza puntual pendiente; (c) `include_hidden=false` devuelve 400 (solo vacío/`true`/`1`); (d) el worker no se ejercitó en runtime (sin docker) y la prueba en el teléfono queda del usuario; (e) push/PR de ambas ramas: decisión del usuario.
