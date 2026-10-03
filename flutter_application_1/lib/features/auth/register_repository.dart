import 'package:flutter_application_1/features/auth/register_models.dart';

/// Contrato de la operación de registro.
///
/// Existe como interfaz para que la vista no dependa del transporte: cuando
/// llegue el cliente HTTP real se implementa esta misma clase y la vista no
/// cambia.
abstract class RegisterRepository {
  /// Registra al usuario. Lanza si el backend responde 409 (correo ya
  /// registrado), 400 o cualquier otro error de red.
  Future<void> register(RegisterUserRequest request);
}

/// Implementación temporal: espera y resuelve. No toca la red.
///
/// [shouldFail] existe para poder ejercitar el camino de error sin backend.
class FakeRegisterRepository implements RegisterRepository {
  const FakeRegisterRepository({
    this.latency = const Duration(seconds: 2),
    this.shouldFail = false,
  });

  /// Espera antes de "responder". Mismo tiempo que el fake de login.
  final Duration latency;

  /// Cuando es `true`, [register] lanza en vez de resolver.
  final bool shouldFail;

  @override
  Future<void> register(RegisterUserRequest request) async {
    await Future<void>.delayed(latency);
    if (shouldFail) {
      throw StateError('FakeRegisterRepository: fallo simulado');
    }
  }
}
