// lib/models/user/address.dart

/// Modelo de dominio para direcciones de usuario.
///
/// Representa una dirección con lógica de negocio.
class Address {
  final String id;
  final String type;
  final String typeDisplay;
  final String label;
  final String street;
  final String? reference;
  final String? floorApartment;
  final String? secondaryStreet;
  final double latitude;
  final double longitude;
  final String? city;
  final String? contactPhone;
  final String? instructions;
  final bool isDefault;
  final bool active;
  final int timesUsed;
  final DateTime? lastUsed;
  final String? fullAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.type,
    required this.typeDisplay,
    required this.label,
    required this.street,
    this.reference,
    this.floorApartment,
    this.secondaryStreet,
    required this.latitude,
    required this.longitude,
    this.city,
    this.contactPhone,
    this.instructions,
    this.isDefault = false,
    this.active = true,
    this.timesUsed = 0,
    this.lastUsed,
    this.fullAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  // ========================================================================
  // LÓGICA DE DOMINIO
  // ========================================================================

  /// Verifica si la dirección tiene coordenadas válidas.
  bool get hasValidCoordinates =>
      latitude != 0.0 && longitude != 0.0;

  /// Verifica si la dirección tiene referencia.
  bool get hasReference => reference != null && reference!.isNotEmpty;

  /// Verifica si la dirección tiene teléfono de contacto.
  bool get hasContactPhone => contactPhone != null && contactPhone!.isNotEmpty;

  /// Verifica si la dirección tiene instrucciones.
  bool get hasInstructions => instructions != null && instructions!.isNotEmpty;

  /// Verifica si la dirección ha sido usada recientemente (últimos 30 días).
  bool get isRecentlyUsed {
    if (lastUsed == null) return false;
    final daysSinceLastUse = DateTime.now().difference(lastUsed!).inDays;
    return daysSinceLastUse <= 30;
  }

  /// Obtiene una descripción corta de la dirección.
  ///
  /// Útil para mostrar en listas.
  /// Ejemplo: "Casa - Av. Principal #123"
  String get shortDescription {
    final parts = <String>[typeDisplay];
    if (street.isNotEmpty) {
      parts.add(street.length > 50 ? '${street.substring(0, 50)}...' : street);
    }
    return parts.join(' - ');
  }

  /// Obtiene la dirección completa con detalles adicionales.
  ///
  /// Ejemplo: "Av. Principal #123, Piso 2, Apt 201, Ref: Frente al parque"
  String get detailedAddress {
    final parts = <String>[];

    if (fullAddress != null && fullAddress!.isNotEmpty) {
      parts.add(fullAddress!);
    } else {
      parts.add(street);
    }

    if (floorApartment != null && floorApartment!.isNotEmpty) {
      parts.add(floorApartment!);
    }

    if (reference != null && reference!.isNotEmpty) {
      parts.add('Ref: $reference');
    }

    return parts.join(', ');
  }

  /// Coordenadas en formato "lat,lng" para uso en URLs de mapas.
  String get coordinatesString => '$latitude,$longitude';

  /// URL para abrir la dirección en Google Maps.
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  // ========================================================================
  // COPYWITH
  // ========================================================================

  Address copyWith({
    String? id,
    String? type,
    String? typeDisplay,
    String? label,
    String? street,
    String? reference,
    String? floorApartment,
    String? secondaryStreet,
    double? latitude,
    double? longitude,
    String? city,
    String? contactPhone,
    String? instructions,
    bool? isDefault,
    bool? active,
    int? timesUsed,
    DateTime? lastUsed,
    String? fullAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      type: type ?? this.type,
      typeDisplay: typeDisplay ?? this.typeDisplay,
      label: label ?? this.label,
      street: street ?? this.street,
      reference: reference ?? this.reference,
      floorApartment: floorApartment ?? this.floorApartment,
      secondaryStreet: secondaryStreet ?? this.secondaryStreet,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      contactPhone: contactPhone ?? this.contactPhone,
      instructions: instructions ?? this.instructions,
      isDefault: isDefault ?? this.isDefault,
      active: active ?? this.active,
      timesUsed: timesUsed ?? this.timesUsed,
      lastUsed: lastUsed ?? this.lastUsed,
      fullAddress: fullAddress ?? this.fullAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ========================================================================
  // EQUALITY Y HASH
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Address &&
        other.id == id &&
        other.label == label &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(id, label, latitude, longitude);

  @override
  String toString() {
    return 'Address(id: $id, label: $label, fullAddress: $fullAddress, isDefault: $isDefault)';
  }
}
