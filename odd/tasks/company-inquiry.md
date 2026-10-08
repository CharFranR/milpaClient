# Company en el cliente Flutter — Mi negocio e incentivo (Inquiry deprecado)

**Objetivo:** implementar en el cliente Flutter el flujo de Company del cliente web (crear/editar empresa, empresa visible en el detalle de oferta), con dos diferencias decididas por el usuario: publicar productos NO requiere empresa (la empresa es un incentivo, nunca un bloqueo) e **Inquiry queda deprecado y fuera de alcance**.

**Deprecación de Inquiry (decisión del usuario, 2026-10-08):** durante T1 el usuario detuvo el trabajo y decidió deprecar Inquiry. Se removieron del commit los modelos/repositorios de inquiry recién creados (commit T1 reescrito a solo Company). El cliente Flutter no implementará consultas. Los endpoints `/inquiries` del server quedan intactos (el web React los usa a medias — status string vs int; bug latente fuera de alcance). El review RDD del slice quedó **pausado**: nunca llegó a iniciarse (sin autoridad quemada) y el candidato fue reescrito; se retomará cuando el alcance esté cerrado.

**Problema / estado verificado (2026-10-08):**

1. El Flutter no tenía nada de company: 0 matches en `lib/` (explorer).
2. El server ya soporta Company: pertenece al agricultor (brief RF-04, migración `000004`, owner = user autenticado). Endpoints: `GET /companies?owner_id=`, `GET /companies/{id}`, `POST /companies`, `PATCH /companies/{id}`.
3. El web persiste `company_id` en localStorage; en Flutter se resuelve por `GET /companies?owner_id=` (sin localStorage).
4. Form del web: `name, category_id, description, phone_number, email, website` — la dirección NO se persiste en company (va al perfil del user); el payload omite vacíos.
5. El web bloquea publicar sin empresa (`ProducerProducts.jsx:238`); en Flutter eso NO se replica → banner de incentivo no bloqueante.

**Decisiones del usuario (2026-10-08):**

| Punto | Decisión |
|---|---|
| Alcance | Company en Flutter (convivencia con el flujo actual). **Inquiry deprecado: fuera del cliente** |
| Publicar sin empresa | Permitido. Incentivo: banner no bloqueante + ligar productos a la empresa cuando exista |
| Entrega | Commits work-unit en rama `feat/company-inquiry`; push/PR/merge: decisión del usuario |

**Alcance:**

- Company: `CompanyRepository` (fetchByOwner, fetchById, create, update) — hecho en T1; form "Mi negocio" accesible desde Mi cuenta del farmer (T2); tarjeta de empresa en el detalle de oferta del buyer (T4); banner de incentivo + `company_id` en el payload del producto cuando exista (T3).

**Fuera de alcance:** Inquiry/consultas en el Flutter (deprecado); gate de publicación del web; localStorage de company; cambios en server o web React; reviews con target company.

**Restricciones:**

- Cero comentarios en código nuevo (preferencia registrada del usuario); UI en español; identificadores en inglés; Conventional Commits en inglés sin atribución de IA.
- No tocar `.atl/` (modificaciones preexistentes sin commitear).
- `git add` por archivo; nunca `-A`.
- Patrón de la casa: repo con `{ApiClient apiClient, TokenStore tokenStore}`, inyección opcional para tests, páginas que se auto-construyen el repo.
- Tests: RED→GREEN en repos nuevos (MockClient); sin baterías de tests de widgets nuevas — verificación principal `flutter analyze` + `flutter test`.

**Tareas (ruta: delegada — writer trigger: 2+ archivos no triviales por task):**

- [x] **T1 — Modelos y repositorio de Company (1 commit).** `lib/features/company/company_models.dart`, `company_repository.dart` + test MockClient. Commit `3957e90` (3 archivos, 551 insertions). RED→GREEN 27 tests; `flutter analyze` limpio; suite completa verde. (La parte de Inquiry fue removida del commit por la deprecación.)
- [x] **T2 — Farmer: Mi negocio (1 commit).** Commit `a5d361e` (`business.dart` 495 líneas + `account.dart` +64/−1). Form crear/editar con estados loading/empty/error/form, categorías desde `fetchCategories`, prefill de teléfono/email del usuario, textos del web, guard anti doble submit. `flutter analyze` limpio y suite 257 verde.
- [x] **T3 — Farmer: incentivo + empresa en productos (1 commit).** Commit `6d3a108` (3 archivos, +123/−1). Banner no bloqueante "Sumá tu empresa" con CTA a Mi negocio; `company_id` en el draft de publicación solo cuando existe empresa; sin gate (publicar funciona igual). Suite verde.
- [x] **T4 — Buyer: empresa en el detalle (1 commit).** Commit `25b2497` (2 archivos, +156/−44). `OfferingDetail.companyId` (uuid cero/empty → null); tarjeta de empresa con badge "Proveedor Verificado" y ubicación; fallback exacto al bloque seller. Suite verde.

**Verificación por task:** `flutter analyze` limpio + `flutter test` (suite completa). Repos: test RED→GREEN. RDD: pausado por cambio de alcance; se retomará con `gentle-ai review assess` sobre el slice cerrado (el transporte de review desde este repo tiene un mismatch conocido con OpenCode; si el flujo nativo no puede relayarse, se reporta sin inventar PASS).

**Presupuesto:** ~900-1.100 líneas autoradas estimadas (restando inquiry). Estrategia `ask-on-risk`; sin PRs en alcance.

**Progreso:**

- 2026-10-08: feature abierta (Company + Inquiry). Exploración React + Flutter completada; hallazgos clave: status int, modal huérfano, dirección en user, gate del web no replicado. Rama `feat/company-inquiry` creada desde `feat/offering-expiry`. T1 implementado (6 archivos, 1018 ins).
- 2026-10-08: **usuario detuvo el trabajo y deprecó Inquiry.** T1 reescrito a solo Company (`3957e90`); refs a inquiry eliminadas del código; `flutter analyze` limpio y suite verde tras la remoción. Review RDD pausado en preflight (sin START, sin autoridad quemada). Pendiente: confirmar si la deprecación incluye marcar endpoints del server (fuera del repo del cliente).

**Follow-ups anotados (no en alcance):**

- **Máquina de estados de conversaciones (pending → read → replied → closed):** a implementar "para después" (decisión del usuario, 2026-10-08). Análisis de factibilidad hecho: el flujo WS ya tiene read-state (`last_read_at`, migración `000033`) y `unread_count`; `replied` es derivable de los mensajes; `closed` requiere definición (match o acción explícita). Detalle en Engram, topic `architecture/conversation-state-machine`.

**Cierre de implementación (2026-10-08):** T1–T4 completos en `feat/company-inquiry` (`3957e90`, `a5d361e`, `6d3a108`, `25b2497`). Spot check final: `flutter analyze` limpio + suite 257/257. Review RDD del slice (base `7bc1c0b`, riesgo medium, 10 paths, 1435 líneas): consent otorgado por el usuario y START creado (linaje `review-358fce83bfd3648a`, lente `review-reliability`, estado `reviewing`; nada quemado). El relay del reviewer falló con `opencode_review_transport_binding_invalid` (mismatch de sesión: OpenCode abierto en Hackaton2026 revisando milpaClient; espejo del caso ya documentado del server). El slot sigue ofrecido; para completar el review se necesita una sesión de OpenCode abierta en milpaClient con los tokens del linaje (guardados en Engram, scope personal). Prueba E2E en vivo contra el stack local: **hecha** (2026-10-08; flujo completo verificado — crear/editar empresa, boundary público/privado, oferta con company_id, detalle con company_id; evidencia en Engram `testing/e2e-company-live`). Prueba en teléfono y push/PR: decisión del usuario.
