// lib/models/user/profile.dart

/// Modelo de dominio para el perfil de usuario.
///
/// Este modelo representa la entidad de negocio (no depende de JSON).
/// Contiene lógica de dominio y métodos de conveniencia.
class Profile {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isActive;
  final String? activeRole;

  const Profile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.photoUrl,
    required this.createdAt,
    this.isActive = true,
    this.activeRole,
  });

  // ========================================================================
  // LÓGICA DE DOMINIO
  // ========================================================================

  /// Obtiene el nombre completo del usuario.
  ///
  /// Si no hay nombre ni apellido, retorna el username.
  String get fullName {
    if (firstName == null && lastName == null) return username;
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  /// Verifica si el usuario tiene foto de perfil.
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Verifica si el perfil está completo (tiene nombre y apellido).
  bool get isComplete =>
      firstName != null &&
      firstName!.isNotEmpty &&
      lastName != null &&
      lastName!.isNotEmpty;

  /// Verifica si el usuario tiene un teléfono registrado.
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  /// Obtiene las iniciales del usuario para avatares.
  ///
  /// Ejemplos:
  /// - Juan Pérez -> JP
  /// - user123 -> U
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      final first = firstName![0].toUpperCase();
      final last =
          lastName != null && lastName!.isNotEmpty ? lastName![0].toUpperCase() : '';
      return last.isEmpty ? first : '$first$last';
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  // ========================================================================
  // COPYWITH
  // ========================================================================

  Profile copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
    bool? isActive,
    String? activeRole,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      activeRole: activeRole ?? this.activeRole,
    );
  }

  // ========================================================================
  // EQUALITY Y HASH
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.username == username &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, username, email);

  @override
  String toString() {
    return 'Profile(id: $id, username: $username, email: $email, fullName: $fullName)';
  }
}
