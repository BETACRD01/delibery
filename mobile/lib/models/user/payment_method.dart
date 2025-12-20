// lib/models/user/payment_method.dart

/// Modelo de dominio para métodos de pago de usuario.
class PaymentMethod {
  final String id;
  final String type;
  final String typeDisplay;
  final String alias;
  final String? proofImageUrl;
  final String? notes;
  final bool hasProof;
  final bool requiresVerification;
  final bool isDefault;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.typeDisplay,
    required this.alias,
    this.proofImageUrl,
    this.notes,
    this.hasProof = false,
    this.requiresVerification = false,
    this.isDefault = false,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // ========================================================================
  // LÓGICA DE DOMINIO
  // ========================================================================

  /// Verifica si el método de pago tiene imagen de comprobante.
  bool get hasProofImage => proofImageUrl != null && proofImageUrl!.isNotEmpty;

  /// Verifica si el método de pago tiene notas/observaciones.
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Verifica si el método de pago está completamente configurado.
  ///
  /// Un método de pago está completo si:
  /// - Tiene alias
  /// - Si requiere verificación, debe tener comprobante
  bool get isComplete {
    if (requiresVerification && !hasProof) {
      return false;
    }
    return alias.isNotEmpty;
  }

  /// Verifica si el método de pago está pendiente de verificación.
  bool get isPendingVerification => requiresVerification && !hasProof;

  /// Obtiene una descripción corta del método de pago.
  ///
  /// Ejemplo: "Efectivo - Mi efectivo principal"
  String get shortDescription => '$typeDisplay - $alias';

  /// Obtiene el ícono emoji según el tipo de método de pago.
  String get icon {
    switch (type.toLowerCase()) {
      case 'efectivo':
        return '💵';
      case 'transferencia':
        return '🏦';
      case 'tarjeta':
        return '💳';
      default:
        return '💰';
    }
  }

  // ========================================================================
  // COPYWITH
  // ========================================================================

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? typeDisplay,
    String? alias,
    String? proofImageUrl,
    String? notes,
    bool? hasProof,
    bool? requiresVerification,
    bool? isDefault,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      typeDisplay: typeDisplay ?? this.typeDisplay,
      alias: alias ?? this.alias,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      notes: notes ?? this.notes,
      hasProof: hasProof ?? this.hasProof,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      isDefault: isDefault ?? this.isDefault,
      active: active ?? this.active,
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

    return other is PaymentMethod &&
        other.id == id &&
        other.type == type &&
        other.alias == alias;
  }

  @override
  int get hashCode => Object.hash(id, type, alias);

  @override
  String toString() {
    return 'PaymentMethod(id: $id, type: $typeDisplay, alias: $alias, isDefault: $isDefault)';
  }
}
