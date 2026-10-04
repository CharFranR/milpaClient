# Cuenta del comprador e inicio real — Fases 1–3

**Objetivo:** completar los datos reales del comprador (dirección, ubicación reportada, foto) y reemplazar el mock de la pantalla de inicio por datos del server.

**Problema:** cuatro huecos detectados por el usuario en la prueba con el teléfono:

1. La foto de perfil está hardcodeada (`profile.dart:230`, `Image.asset('assets/oscar.png')`).
2. El registro no pide la dirección del usuario, aunque el server la acepta (`RegisterUserRequest.Address`).
3. Las coordenadas exactas no llegan al server desde el cliente.
4. `home.dart` es el único archivo que importa `mock_data.dart`: saludo, productos y categorías inventados.

**Por qué:** es información de identidad del comprador que hoy se pierde, y el inicio es la primera pantalla que ve el usuario. Continuidad con `odd/tasks/wholesale-flow.md` (Etapa 3, cerrada) y `odd/tasks/server-integration.md` (Etapas 1 y 2).

## Hallazgos que enmarcan el trabajo

- **El server ya acepta dirección y coordenadas** en registro y en `PATCH /users/{id}` (`dto/user.go`, `aplication/use-cases/user.go:69-76` y `:143-158`), y las persiste (`userRepo.go:157,238`) en `addresses` (`address_line NOT NULL`, `latitude`/`longitude` nullable, `000001_create_addresses`).
- **El server no devuelve latitud ni longitud** en el DTO privado (`use-cases/user.go:193-205`). Decisión del usuario: **no hace falta devolverlas**; el cliente sólo tiene que reportarlas para que queden disponibles para recomendaciones futuras.
- **`/recommendations` hoy no usa ubicación** (`use-cases/recommendation.go` no lee `Latitude`/`Longitude`/`Department`/`Municipality`). No se toca: la información se guarda ahora, el consumo es trabajo posterior.
- **`ValidateCoordinates`** (`domain/entities/address.go:51`) sólo valida rangos (±90 / ±180); no exige el par completo ni prohíbe ceros. `HasCoordinates()` trata `0,0` como ausente.
- **`GET /categories` es público** (`router.go:60`) y **`GET /search` soporta `sort=proximity` con `lat`/`lng`** (`search.go:189`); la respuesta ya trae `farmer_name`, `farmer_verified`, `latitude`, `longitude`, `image_url` (`dto/search.go`). El inicio real no necesita cambios de server.

## Alcance y presupuesto (fijado por el usuario)

- **Fase 1 — Identidad y ubicación (cliente, 1 commit):** campo de dirección en el registro y reporte de coordenadas con consentimiento explícito del usuario (GPS del dispositivo). Cierra la Fase 1 el envío real al server.
- **Fase 2 — Inicio real (cliente, 1 commit):** saludo con el usuario de sesión, destacados y categorías reales, "productores cercanos" con `sort=proximity`, y borrar `mock_data.dart`.
- **Fase 3 — Foto de perfil (1 commit cliente + 1 commit server):** columna de foto y endpoint de subida reutilizando `LocalImageStore`, más el avatar real con flujo de cambio.

**Fuera de alcance:** devolver coordenadas al cliente, cambiar `/recommendations`, hacer obligatoria la dirección (queda opcional, igual que departamento y municipio) y almacenamiento de imágenes externo.

**Deuda técnica aceptada (no se toca):** `omitempty` en `unit_of_measure` hace que la clave se omita cuando vale `0` (kg) y la UI muestre `8 —`; los rótulos del formulario de solicitudes ("Cantidad de unidades de presentación", "Producto por presentación") son elección deliberada del usuario; la migración `000016` editada en el lugar no es un problema.

## Restricciones

- Cero comentarios en el código nuevo (preferencia del usuario).
- Testing proporcional: `flutter analyze` limpio, los tests existentes verdes, y pruebas nuevas sólo donde son baratas (payload y consentimiento). La verificación de GPS es en el teléfono, no en tests.
- La información de ubicación se envía **sólo con consentimiento explícito** del usuario; sin consentimiento no se manda nada.
- Commits por fase (Conventional Commits). Push/PR/merge: decisión del usuario.

## Tareas

- [x] **F1 — Dirección y ubicación (cliente, 1 commit).** `LocationReporter` inyectable (implementación con `geolocator`, fake en tests); campo "Dirección" en el registro; interruptor "Compartir mi ubicación" (opcional, arranca apagado) que pide permiso y captura las coordenadas; reporte de `address`, `latitude` y `longitude` en el registro y en la edición de perfil; permisos de Android e iOS.
- [x] **F2 — Inicio real (cliente, 1 commit).**
- [ ] **F3 — Foto de perfil (server + cliente).**

## Verificación

- Por tarea: `flutter analyze` limpio + `flutter test` verde (cliente); `go build ./...` + `go vet ./...` (server).
- Por fase: prueba manual en el teléfono contra el server local (docker + `make seed`).
- Fase 1: cuenta nueva con ubicación compartida → verificar por API que `latitude`/`longitude` quedaron guardadas en `addresses`; cuenta nueva sin compartir → verificar que no se envió nada.

## Progreso

- 2026-10-04: feature abierta. Diagnóstico verificado en código (cliente y server) y plan de 3 fases aprobado por el usuario, con la decisión de capturar la ubicación por GPS del dispositivo (opción A) y reportarla sin mostrarla en la UI.
- 2026-10-04: **F1 completada** — commit `42ab87d`, rama `feat/buyer-identity`. `lib/core/location_reporter.dart` (nuevo): `LocationReporter.capture()` con la implementación `DeviceLocationReporter` sobre `geolocator` (chequeo de servicio y permiso, posición con límite de 20 s, `null` ante cualquier fallo). El registro suma el campo "Dirección" y el interruptor "Compartir mi ubicación" (arranca apagado: si el usuario no lo enciende, el reportero no se llama y no se manda nada); la edición de perfil suma el mismo interruptor para que una cuenta existente pueda reportar su ubicación. `address`, `latitude` y `longitude` viajan en `POST /auth/register` y en `PATCH /users/{id}`; las coordenadas no se muestran en ningún lado de la UI. Permisos en `AndroidManifest.xml` e `Info.plist`. Evidencia: `flutter analyze` limpio, 169 tests verdes (3 nuevos: la dirección escrita llega al payload, sin consentimiento no se envía nada, con consentimiento se envían las coordenadas capturadas). **Verificada en el teléfono** (2026-10-04): alta nueva con la dirección escrita y el interruptor de ubicación encendido, permiso aceptado por el usuario, resultado OK.
- 2026-10-04: **F2 completada** — rama `feat/buyer-home-real`. `home.dart` deja de usar `mock_data.dart` (eliminado): el saludo usa el nombre del usuario de sesión, las categorías vienen de `GET /categories`, los destacados de `GET /search` (4 resultados, con imagen, precio y badge de verificado) y la tarjeta de productores cercanos muestra el total real de una búsqueda con `sort=proximity` sólo cuando el permiso de ubicación **ya está concedido** (`LocationReporter.captureGranted()`, que no vuelve a pedir permiso); si no lo está, el texto invita a compartirla desde el perfil, así el consentimiento queda donde el usuario lo dio. Se retiró el contador falso de la campana y la categoría sin datos ya no se inventa (emoji por nombre conocido, `🌿` por defecto). `CatalogSort` suma `proximity` y `CatalogRepository.search` acepta `lat`/`lng`; `BuyerLayout` pasa a construir sus páginas para que "Ver todo", las categorías y "Explorar →" cambien a la pestaña Explorar. Evidencia: `flutter analyze` limpio, 173 tests verdes (4 nuevos en `test/features/buyer/home_test.dart`: saludo + categorías + destacados reales, sin ubicación no se piden coordenadas ni se ordena por cercanía, con ubicación se ordena por proximidad y se muestra el conteo, y estado de error con reintento). **Gotcha:** pre-arrancar las tres llamadas concurrentes deja el `Future` que falla sin escucha y Dart lo reporta como excepción no manejada (fue un test que falló de verdad, no ruido); quedaron secuenciales a propósito. **Pendiente: prueba en el teléfono.**
- **Revisión nativa de F1 (candidato `42ab87d`): diferida por decisión del usuario.** Primero la prueba en el teléfono; si el e2e revela algo, el candidato cambia igual y se revisa después. El preflight (`inspect`) ofreció `review.start` sobre el único cambio sin commitear, que era esta misma línea de progreso: se salteó por la excepción de edición trivial sólo-documentación. RDD sigue encendido y no se creó ni quemó ninguna autoridad.
- **Nota para F2:** el "inicio real" necesita las coordenadas del comprador para `sort=proximity`, y por decisión del usuario el cliente **no** las lee del server; el camino natural es reutilizar `LocationReporter`. Por eso F2 se apila sobre la rama de F1.
