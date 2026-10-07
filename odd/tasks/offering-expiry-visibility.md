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
| Número de migración (D) | `000034_category_default_expiry`, acordado con el usuario el 2026-10-06; se corren las reservas sin escribir: users_registration_invariants→035, companies_agricultural→036, conversations_match_link→037 y el bloque RBAC→038+. Divergencia anotada: el 000033 es `conversation_read_state` en la rama auth-admin, aunque el registry lo reservaba a `report_target_types` |

## Alcance y presupuesto

- **Server — 2 commits (cerrados):** (E1) worker de expiración + consistencia ES (borrar del índice al ocultar, re-indexar al renovar); (E2) listado del dueño con ocultas.
- **Cliente — 1 commit (cerrado):** (E3) sección de ocultas, rótulo "Vencido"/"Inactivo" y renovación alcanzable.
- **Segunda pasada D — en curso:** (D1) `categories.default_expiry_days` + migración `000034` + fallback en el alta (server); (D2) campo en la web admin; (D3) prefill de fecha en el form Flutter.
- **Previsión:** ~550-750 líneas para A+B (real ~260 de código) + ~150-250 para D. Estrategia de entrega `ask-on-risk`; push/PR/merge son decisión del usuario (sin PRs en alcance, no se pregunta chain strategy hasta que se abran).
- **Fuera de alcance:** reactivación de desactivados (toggle), auto-expiración de solicitudes de suministro (el brief la marca "futuro"), job externo/pg_cron, reindex de ES y prefill en el form web del productor.

## Restricciones

- Cero comentarios en el código nuevo (preferencia del usuario). Decisiones importantes → Engram.
- Sin baterías de tests nuevas (decisión del usuario, prioritaria sobre el harness): server `go build ./...` + `go vet ./...` (vet compila los tests, así que los fakes se actualizan para no romper compilación); cliente `flutter analyze` limpio + suite existente verde.
- Conventional Commits en inglés, sin atribución de IA. Push/PR/merge: decisión del usuario.
- No tocar `.atl/` ni `frontend/package-lock.json` (modificaciones preexistentes sin commitear).

## Tareas (ruta: delegada — writer trigger: 2+ archivos no triviales por repo)

- [x] **E1 — Worker de expiración y consistencia ES (server, 1 commit).** Commit `9ae9113` (8 archivos, +132). Verificación: `go build ./...` y `go vet ./...` limpios; unitarios de usecases/entities verdes; suite completa verde en local. `DeactivateExpired(ctx, now)` en el puerto/repo (`UPDATE offerings SET is_active=false, updated_at=$2 WHERE is_active AND expires_at <= $1 RETURNING ...`); worker con ticker de 5 minutos + barrido inicial (`server/aplication/use-cases/expiry_worker.go` nuevo) que por cada oferta ocultada borra el doc de ES y purga `offerings:byuser:<uid>` y el cache de búsqueda; wiring con contexto cancelable en `cmd/api/main.go` enganchado al shutdown; `RenewOffering` re-indexa en ES; `DeactivateOffering` manual también borra el doc de ES (misma semántica de "oculto").
- [x] **E2 — Listado de ocultas para el dueño (server, 1 commit).** Commit `fd8e626` (15 archivos, +53/−24). `GetByUserID`/`FindByUserID` con `includeHidden bool`; query param `include_hidden` en `GET /offerings/?user_id=`; solo el dueño autenticado puede pedirlo (403 en cualquier otro caso); ruta con `AuthenticateOptional`; el cache wrapper no cachea la variante privada; fakes y call sites existentes actualizados para que `go vet` pase.
- [x] **E3 — Flutter: ocultas visibles y renovación (cliente, 1 commit).** Commit `8b6495d` (3 archivos, +43/−9). `flutter analyze` limpio y `flutter test` 244/244. `fetchMine` manda token y `include_hidden=true`; `FarmerProduct` parsea `expires_at`; `products.dart` separa/señala "Vencido" vs "Inactivo" y deja el botón de renovar alcanzable para las ocultas.
- [x] **D1 — Default por categoría en el server (1 commit).** Commit `cef6bdf` (20 archivos, +106/−36). Verificación: build/vet/unitarios verdes; integración verde tras agregar `000034` al listado hardcodeado de `postgres_test.go`; `API.md` actualizado; sin default en la semilla (no crea categorías). Migración `000034_category_default_expiry` (up/down) + `categories.default_expiry_days` (nullable, CHECK > 0); `Category.DefaultExpiryDays *int` + DTO mapeado en el admin; `CreateOffering` aplica `now + días` solo si el agricultor no mandó `expires_at` (precedencia: fecha explícita > default de categoría > sin vencimiento); `categoryRepo` inyectado en `NewOfferingUseCase` (main.go + seed + call sites); `docs/migrations-registry.md` actualizado con la corrida de reservas y `API.md` si documenta el campo.
- [x] **D2 — Web admin (mismo repo, 1 commit).** Commit `0f62cb5` (2 archivos). `npm run lint`, `npm run build` y `npm test` 101/101 verdes. Campo numérico opcional "Días de vencimiento predeterminados" en el modal de categorías (`AdminConfig.jsx`) + payload en `services/admin.js`.
- [x] **D3 — Flutter (cliente, 1 commit).** Commit `fc5d702` (2 archivos). `flutter analyze` limpio y `flutter test` 244/244. `FarmerCategory.defaultExpiryDays` desde `/categories`; al elegir una categoría con default, el form de producto precarga la fecha (hoy + N) en vez del +30 fijo.

## Verificación

- E1: `go build ./...` + `go vet ./...` limpios; `go test -count=1 ./tests/unitary/usecases/... ./tests/unitary/entities/...` verde. En la corrida de esta máquina la suite completa (`go test ./...`) también quedó verde: la integración usa testcontainers y las deudas X1 no se reprodujeron.
- E2: idem + prueba manual contra el server local con dos cuentas (dueño ve ocultas; tercero recibe 403).
- E3: `flutter analyze` limpio + `flutter test` con la suite existente verde; prueba manual en el teléfono queda del usuario.
- Sin reindex de ES: la consistencia es "doc borrado al ocultar / re-indexado al renovar".
- D1: build/vet/unitarios + integración verdes; D2: lint + build + 101 tests; D3: analyze + 244 tests.
- Prueba en vivo pendiente (usuario): crear una categoría con default desde la web admin, publicar un producto sin fecha y verificar que vence según el default (y que el worker lo oculta al vencer).

## Progreso

- 2026-10-06: feature abierta. Diagnóstico y mapa de enganche verificados con explorer; decisiones A2 y visibilidad-solo-dueño cerradas con el usuario. Plan: 2 commits de server + 1 de cliente.
- 2026-10-06: **E1 y E2 completadas (server, rama `develop`, commits `9ae9113` y `fd8e626`).** El worker barre al arrancar y cada 5 minutos, pasa `expires_at <= now` a `is_active=false` con `RETURNING`, borra el doc de ES por oferta ocultada y purga `offerings:byuser:*` + cache de búsqueda; `RenewOffering` re-indexa en ES y `DeactivateOffering` borra del índice. El listado del dueño acepta `include_hidden=true` con token y solo para el propio `user_id` (403 en cualquier otro caso), con bypass de cache. Evidencia: `go build ./...` y `go vet ./...` limpios; `go test -count=1 ./tests/unitary/usecases/... ./tests/unitary/entities/...` verde; la suite completa también quedó verde en esta máquina (la integración usa testcontainers, no la base local). Desvíos: se arreglaron dos fakes que ya rompían `go vet` en HEAD (`List` faltante en `ownershipUserRepo`/`stubUserRepo`) y se actualizó `cmd/seed/main.go` como call site de la firma; `include_hidden` acepta vacío/`true`/`1` y devuelve 400 con cualquier otro valor.
- 2026-10-06: **E3 completada (cliente, rama `feat/offering-expiry`, commit `8b6495d`).** `fetchMine` manda token + `include_hidden=true`; `FarmerProduct` parsea `expires_at` y expone `isExpired`/`isHidden`; la lista separa "Ocultos" con badge "Vencido"/"Inactivo" y deja solo "Renovar" en esas tarjetas. Evidencia: `flutter analyze` limpio y `flutter test` 244/244. Sin tests nuevos (política del usuario).
- **Follow-ups anotados:** (a) la web del productor (React) sigue llamando el endpoint público sin `include_hidden`, así que no ve ocultas todavía; (b) ofertas desactivadas manualmente antes de E1 siguen en el índice ES (el worker solo captura transiciones activo→inactivo) — limpieza puntual pendiente; (c) `include_hidden=false` devuelve 400 (solo vacío/`true`/`1`); (d) el worker no se ejercitó en runtime (sin docker) y la prueba en el teléfono queda del usuario; (e) push/PR de ambas ramas: decisión del usuario.
- 2026-10-06: **D abierta.** Número de migración acordado con el usuario: `000034` (ver Decisiones). Alcance: server (D1) + web admin (D2) + Flutter (D3).
- 2026-10-06: **D1, D2 y D3 completadas.** Server `cef6bdf` (migración `000034` + `default_expiry_days` + fallback al crear + registry actualizado y reservas corridas); web admin `0f62cb5` (campo numérico + normalizador de payload); Flutter `fc5d702` (prefill hoy+N al elegir categoría). RDD: server 397 líneas y cliente 122, ambos `medium`/`under_budget`. Pendiente: prueba en vivo (categoría con default → publicar sin fecha → verificar vencimiento), push/PR del usuario.
