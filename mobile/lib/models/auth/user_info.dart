// lib/models/user_info.dart

/// Información del usuario autenticado
class UserInfo {
  final String email;
  final List<String> roles;
  final int? userId;

  UserInfo({
    required this.email,
    required this.roles,
    this.userId,
  });

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  bool tieneRol(String rol) =>
      roles.any((r) => r.toUpperCase() == rol.toUpperCase());

  bool get esProveedor => tieneRol('PROVEEDOR');
  bool get esRepartidor => tieneRol('REPARTIDOR');
  bool get esAdmin => tieneRol('ADMINISTRADOR');
  bool get esUsuario => tieneRol('USUARIO');
  bool get esAnonimo => email.toLowerCase().contains('anonymous');

  @override
  String toString() =>
      'UserInfo(email: $email, roles: $roles, userId: $userId)';
}
