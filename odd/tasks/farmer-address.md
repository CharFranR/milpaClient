# Dirección del farmer — desbloquear publicación desde el Flutter

**Objetivo:** cerrar el gap detectado en el E2E en vivo (2026-10-08): el server exige dirección completa del user para publicar (`invalid input: a complete address (department, municipality and address line) is required to publish an offering`) y el cliente Flutter del farmer no ofrece ninguna UI para cargarla o corregirla.

**Estado verificado:**

1. `FarmerAccountPage` muestra la dirección en `_InfoCard` solo lectura (account.dart:97-106); sin acciones de edición.
2. `EditProfilePage` (features/buyer/edit_profile.dart, 383 líneas) ya edita nombre, teléfono, email y dirección completa vía `SessionScope.updateProfile` → `PATCH /users/{id}`; solo se usa desde `BuyerProfile` (buyer/profile.dart:194).
3. El E2E de hoy confirmó que `PATCH /users/{id}` con department/municipality/address resuelve el requisito y que sin eso el POST /offerings devuelve el 400 (evidencia: Engram `testing/e2e-company-live`).

**Alcance:**

- Farmer: acceso visible a `EditProfilePage` desde Mi cuenta (reutilizarla con import cross-feature, sin moverla ni modificarla).
- Farmer: al publicar, si el error de publicación es un 400 de dirección, SnackBar accionable con "Completar dirección" → `EditProfilePage`.

**Fuera de alcance:** cambios en el server o el web; mover/refactorizar `EditProfilePage`; cambios en el flujo de registro.

**Restricciones:** cero comentarios en código nuevo; UI en español; sin baterías de tests de widgets; `flutter analyze` + suite completa como verificación; commits work-unit; no tocar `.atl/`.

**Tareas (ruta: delegada — 2 archivos no triviales):**

- [x] **A1 — Acceso a edición + recuperación por dirección (1 commit).** Commit `0510cc5` (2 archivos, +84/−3): card "Editar perfil" en Mi cuenta (debajo de "Mi negocio") + SnackBar accionable "Completar dirección" en `product_form.dart`.

**Verificación:** `flutter analyze` limpio + `flutter test` (suite verde, baseline 257 en la base company). Prueba en vivo en teléfono: usuario.

**Progreso:**

- 2026-10-08: feature abierta tras el E2E de Company; gap verificado con explorer + grep.
- 2026-10-08: A1 implementado. La rama se había creado por error desde `main` (entre sesiones, `feat/offering-expiry` se mergeó como PR #5 y la rama activa quedó en `main`), sin la feature Company. Se rebasó sobre `feat/company-inquiry`: conflicto único en `account.dart` resuelto dejando ambas entradas (Mi negocio + Editar perfil). Commit final `0510cc5`, apilado sobre `25b2497`.
