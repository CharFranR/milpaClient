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

- [ ] **T1** — Dependencia `http` + capa `lib/core/`: `ApiConfig`, `ApiException`/`NetworkException`, `ApiClient` con mapeo de errores; tests con `MockClient`.
- [ ] **T2** — `TokenStore` (`flutter_secure_storage`) + modelos `UserDTO`/`LoginResponse` + `AuthRepository` real.
- [ ] **T3** — Login real + sesión persistente + auth gate en `main.dart`.
- [ ] **T4** — Register real + corrección de roles (1 agricultor, 2 comprador minorista, 3 mayorista detallista, 4 mayorista corporativo).
- [ ] **T5** — Perfil real: `GET /users/{id}` + `PATCH /users/{id}` + "Editar perfil".
- [ ] **T6** — Verificación end-to-end contra el server + evidencia en este documento.

## Etapa 2 — Catálogo + Chat (roadmap)

- Catálogo por `GET /search` (no existe list-all de ofertas) con filtros, orden y paginación; chips por `GET /categories`.
- Detalle de oferta (pantalla nueva): `GET /offerings/{id}` + vendedor + `GET /reviews/average` + "Chatear" (`POST /conversations`).
- Imágenes de red (`/images/{filename}`) con fallback al emoji.
- Conversaciones: `GET /conversations`; chat con `GET/POST /messages` + WebSocket `/ws/{id}` (`web_socket_channel`; subprotocolo `milpa.chat.v1` + `bearer.<JWT>`; aviso de sponsor sin `sender_id`).

## Etapa 3 — Mayorista + Transacciones (roadmap)

- `supply-requests` (crear/listar/editar/cancelar; FAB central como "Nueva solicitud"), ofertas (`/supply-offers/requests/{id}`), priorización, like/pass, transacciones (`confirm-start`/`confirm-delivery`/cancel), reseñas (`POST /reviews`), liquidaciones (`GET /liquidations/open`), reportes (`POST /reports`).
- Quirks del server a manejar: `address` con claves capitalizadas; `SupplyOffer` usa `measurement`; guards de reseñas devuelven 500; `PATCH /offerings/{id}` borra.

## Verificación

- Por tarea: `flutter analyze` limpio + `flutter test` verde + evidencia registrada acá.
- Por etapa: prueba manual contra el server (local o Render).

## Progreso

- 2026-10-03: baseline de mocks commiteado en `main` (`9ce20f1`). Rama `feat/api-integration` creada. T1 en curso.
