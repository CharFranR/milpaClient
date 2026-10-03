# Integración server — cliente comprador

**Objetivo:** conectar el cliente Flutter al server real de Milpa por etapas verificables, sin romper la fase visual ya entregada con mocks.

**Problema:** las pantallas del comprador funcionan con datos simulados (`mock_data.dart`); no existe capa HTTP, ni sesión real, ni datos del server.

**Por qué:** el server se despliega pronto (Render) y el contrato está cerrado en `Hackaton2026/API.md`.

## Alcance

- **Etapa 1:** capa core de red + autenticación real + perfil.
- **Etapa 2:** catálogo real (search) + detalle de oferta + conversaciones + chat en vivo.
- **Etapa 3:** flujo mayorista (solicitudes, ofertas, matches) + transacciones + reseñas + liquidaciones + reportes.

**Fuera de alcance:** app del agricultor y panel admin/auditor (este cliente es el comprador).

## Restricciones

- Cero comentarios en el código (preferencia del usuario). Decisiones importantes → Engram.
- Contrato: `Hackaton2026/API.md`. Base URL por `--dart-define API_BASE_URL` (default `http://10.0.2.2:8080/api/v1`).
- Rama `feat/api-integration`, commits por work unit (Conventional Commits). Push/PR/merge: decisión del usuario.
- Sin refresh token: un 401 → logout limpio hacia login.

## Etapa 1 — Core + Auth + Perfil

- [x] **T1** — Dependencia `http` + capa `lib/core/`: `ApiConfig`, `ApiException`/`NetworkException`, `ApiClient` con mapeo de errores; tests con `MockClient`.
- [x] **T2** — `TokenStore` (`flutter_secure_storage`) + modelos `UserDTO`/`LoginResponse` + `AuthRepository` real.
- [x] **T3** — Login real + sesión persistente + auth gate en `main.dart`.
- [ ] **T4** — Register real + corrección de roles (1 agricultor, 2 comprador minorista, 3 mayorista detallista, 4 mayorista corporativo).
- [ ] **T5** — Perfil real: `GET /users/{id}` + `PATCH /users/{id}` + "Editar perfil".
- [ ] **T6** — Verificación end-to-end contra el server + evidencia en este documento.

**Server (mínimo, no bloquea):**

- `ErrPhoneNumberRequired` a la lista de `IsValidationError` (1 línea) → register sin teléfono responde 400 en vez de 500.

## Etapa 2 — Catálogo + Chat (roadmap)

**Cliente:**

- Catálogo por `GET /search` (no existe list-all de ofertas) con filtros (incluye `category_id`, existe en código pero no está documentado), orden y paginación; chips desde `GET /categories` (reales: Frutales, Cítricos, Otros — reemplazan los del mock).
- Detalle de oferta (pantalla nueva): `GET /offerings/{id}` + vendedor + `GET /reviews/average` + "Chatear" (`POST /conversations`).
- Imágenes de red (`/images/{filename}`) con fallback al emoji.
- Conversaciones: `GET /conversations`; chat con `GET/POST /messages` + WebSocket `/ws/{id}` (`web_socket_channel`; subprotocolo `milpa.chat.v1` + `bearer.<JWT>`; aviso de sponsor sin `sender_id`).

**Server (para que la etapa sea demostrable):**

- Seed de datos: agricultor(es) de prueba + ofertas + inventario, indexados a Elasticsearch. Sin esto el catálogo se ve vacío (la única migración con datos hoy es la de categorías).
- Actualizar `API.md`: documentar `category_id` en search; corregir `UserDTO` (`address_line`/`department`/`municipality`) y la obligatoriedad real de `phone_number`.

## Etapa 3 — Mayorista + Transacciones + Liquidaciones (roadmap)

**Cliente:**

- `supply-requests` (crear/listar/editar/cancelar; FAB central como "Nueva solicitud"; UI gateada a roles mayorista 3/4), ofertas (`/supply-offers/requests/{id}`), priorización, like/pass, transacciones (`confirm-start`/`confirm-delivery`/cancel), reseñas (`POST /reviews`), liquidaciones (listar públicas + detalle), reportes (`POST /reports`).
- Quirks del server a manejar: `address` con claves capitalizadas; `SupplyOffer` usa `measurement`; guards de reseñas devuelven 500; `PATCH /offerings/{id}` borra.

**Server (para completar el brief):**

- Rol mayorista en supply-requests: exigir roles 3/4 en create (hoy cualquier autenticado publica — router solo con Authenticate/Suspension).
- Liquidaciones: auth opcional en las lecturas (`/open`, `/`, `/{id}`) para que la visibilidad restringida funcione; ampliar visibilidad a los niveles del brief (hoy solo `public|private`); flujo de interés/asignación manual (endpoint de interés del comprador + listado de interesados para el agricultor).
- Reseñas: listar las recibidas por un usuario (hoy solo "escritas por" o por empresa). Menor.

**Decisión del equipo:** FCFS descartado conscientemente por el programador del server — la asignación de liquidaciones es solo manual.

## Verificación

- Por tarea: `flutter analyze` limpio + `flutter test` verde + evidencia registrada acá.
- Por etapa: prueba manual contra el server (local o Render).

## Progreso

- 2026-10-03: baseline de mocks commiteado en `main` (`9ce20f1`). Rama `feat/api-integration` creada. Doc ODD (`05e7d00`).
- 2026-10-03: T1 completada — `lib/core/` (ApiConfig, ApiException/NetworkException, ApiClient) + 11 tests con MockClient; analyze limpio, 23 tests verdes, cero comentarios. Commit `db59796`.
- 2026-10-03: T2 completada — `TokenStore` (flutter_secure_storage 11.2.0), `auth_models.dart` (User tolera `address_line ?? address`), `AuthRepository` (login/register/restoreSession/logout) y fix del envelope `{"data":...}` en ApiClient; 33 tests verdes, analyze limpio, APK debug OK. Commits `0b3cd0b` y `16622ba`. Siguiente: T3 (login real + sesión persistente + auth gate).
- Hallazgos del server local (docker): todas las respuestas exitosas van envueltas en `{"data":...}`; el register EXIGE `phone_number` (500 si falta; la doc lo marca opcional — revisar del lado server); el UserDTO real trae `address_line`/`department`/`municipality` (la doc dice `address`). Usuario de prueba: `flutter.test@milpa.com` / `Password123!` (role 2).
- 2026-10-03: Plan actualizado — cada etapa integra su bloque server (Etapa 1: fix teléfono; Etapa 2: seed de datos + doc drift; Etapa 3: rol mayorista, liquidaciones, reseñas). FCFS descartado por decisión consciente del programador del server (solo asignación manual).
- 2026-10-03: T3 completada — `SessionController`/`SessionScope` (InheritedNotifier, sin paquetes extra), `AuthGate` (splash → LoginPage o BuyerLayout), login real con errores mapeados (401/404 → "Correo o contraseña incorrectos"); 37 tests verdes, analyze limpio, cero comentarios. Commit `f6c1ebb`. Nota: el overflow de `_SignUpRow` aparece en widget tests (fuente de prueba ancha) — workaround solo en el test; el fix real sigue como ejercicio pendiente. Siguiente: T4 (register real + roles 1–4).
