// lib/apis/mappers/user_mapper.dart

import '../dtos/user/responses/profile_response.dart';
import '../dtos/user/requests/update_profile_request.dart';
import '../dtos/user/responses/address_response.dart';
import '../dtos/user/requests/create_address_request.dart';
import '../dtos/user/requests/update_address_request.dart';
import '../dtos/user/responses/payment_method_response.dart';
import '../dtos/user/requests/create_payment_method_request.dart';
import '../dtos/user/requests/update_payment_method_request.dart';
import '../../models/user/profile.dart';
import '../../models/user/address.dart';
import '../../models/user/payment_method.dart';

/// Mapper para convertir entre DTOs y Models del dominio de usuarios.
///
/// Responsabilidades:
/// - Convertir DTOs (JSON) a Models (dominio)
/// - Convertir Models a DTOs (requests)
/// - Manejar conversiones de tipos y formatos
class UserMapper {
  UserMapper._();

  // ========================================================================
  // PROFILE RESPONSE → PROFILE MODEL
  // ========================================================================

  /// Convierte un [ProfileResponse] (DTO) a [Profile] (Model de dominio).
  ///
  /// Maneja:
  /// - Conversión de nombres snake_case a camelCase
  /// - Parse de fecha ISO 8601 a DateTime
  /// - Valores null
  static Profile profileToModel(ProfileResponse dto) {
    return Profile(
      id: dto.id,
      username: dto.username,
      email: dto.email,
      firstName: dto.nombre,
      lastName: dto.apellido,
      phone: dto.telefono,
      photoUrl: dto.fotoPerfil,
      createdAt: DateTime.parse(dto.createdAt),
      isActive: dto.isActive,
      activeRole: dto.rolActivo,
    );
  }

  // ========================================================================
  // PROFILE MODEL → UPDATE PROFILE REQUEST
  // ========================================================================

  /// Convierte un [Profile] (Model) a [UpdateProfileRequest] (DTO).
  ///
  /// Solo incluye los campos que se pueden actualizar.
  /// Campos como id, email, username no se incluyen porque no se pueden modificar.
  static UpdateProfileRequest profileToUpdateRequest(Profile model) {
    return UpdateProfileRequest(
      nombre: model.firstName,
      apellido: model.lastName,
      telefono: model.phone,
    );
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  /// Convierte un [Profile] a [UpdateProfileRequest] con solo los campos modificados.
  ///
  /// Útil para hacer PATCH requests con solo los campos que cambiaron.
  ///
  /// Ejemplo:
  /// ```dart
  /// final request = UserMapper.profileToPartialUpdateRequest(
  ///   newProfile,
  ///   original: originalProfile,
  /// );
  /// // request solo tendrá los campos que son diferentes
  /// ```
  static UpdateProfileRequest profileToPartialUpdateRequest(
    Profile model, {
    required Profile original,
  }) {
    return UpdateProfileRequest(
      nombre: model.firstName != original.firstName ? model.firstName : null,
      apellido: model.lastName != original.lastName ? model.lastName : null,
      telefono: model.phone != original.phone ? model.phone : null,
    );
  }

  // ========================================================================
  // ADDRESS RESPONSE → ADDRESS MODEL
  // ========================================================================

  /// Convierte un [AddressResponse] (DTO) a [Address] (Model de dominio).
  static Address addressToModel(AddressResponse dto) {
    return Address(
      id: dto.id,
      type: dto.tipo,
      typeDisplay: dto.tipoDisplay,
      label: dto.etiqueta,
      street: dto.direccion,
      reference: dto.referencia,
      floorApartment: dto.pisoApartamento,
      secondaryStreet: dto.calleSecundaria,
      latitude: dto.latitud,
      longitude: dto.longitud,
      city: dto.ciudad,
      contactPhone: dto.telefonoContacto,
      instructions: dto.indicaciones,
      isDefault: dto.esPredeterminada,
      active: dto.activa,
      timesUsed: dto.vecesUsada,
      lastUsed: dto.ultimoUso != null ? DateTime.parse(dto.ultimoUso!) : null,
      fullAddress: dto.direccionCompleta,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
    );
  }

  // ========================================================================
  // ADDRESS MODEL → CREATE ADDRESS REQUEST
  // ========================================================================

  /// Convierte un [Address] (Model) a [CreateAddressRequest] (DTO).
  static CreateAddressRequest addressToCreateRequest(Address model) {
    return CreateAddressRequest(
      tipo: model.type,
      etiqueta: model.label,
      direccion: model.street,
      referencia: model.reference,
      pisoApartamento: model.floorApartment,
      calleSecundaria: model.secondaryStreet,
      latitud: model.latitude,
      longitud: model.longitude,
      ciudad: model.city,
      telefonoContacto: model.contactPhone,
      indicaciones: model.instructions,
      esPredeterminada: model.isDefault,
    );
  }

  // ========================================================================
  // ADDRESS MODEL → UPDATE ADDRESS REQUEST
  // ========================================================================

  /// Convierte un [Address] (Model) a [UpdateAddressRequest] (DTO).
  static UpdateAddressRequest addressToUpdateRequest(Address model) {
    return UpdateAddressRequest(
      tipo: model.type,
      etiqueta: model.label,
      direccion: model.street,
      referencia: model.reference,
      pisoApartamento: model.floorApartment,
      calleSecundaria: model.secondaryStreet,
      latitud: model.latitude,
      longitud: model.longitude,
      ciudad: model.city,
      telefonoContacto: model.contactPhone,
      indicaciones: model.instructions,
      esPredeterminada: model.isDefault,
    );
  }

  /// Convierte un [Address] a [UpdateAddressRequest] con solo los campos modificados.
  static UpdateAddressRequest addressToPartialUpdateRequest(
    Address model, {
    required Address original,
  }) {
    return UpdateAddressRequest(
      tipo: model.type != original.type ? model.type : null,
      etiqueta: model.label != original.label ? model.label : null,
      direccion: model.street != original.street ? model.street : null,
      referencia: model.reference != original.reference ? model.reference : null,
      pisoApartamento: model.floorApartment != original.floorApartment ? model.floorApartment : null,
      calleSecundaria: model.secondaryStreet != original.secondaryStreet ? model.secondaryStreet : null,
      latitud: model.latitude != original.latitude ? model.latitude : null,
      longitud: model.longitude != original.longitude ? model.longitude : null,
      ciudad: model.city != original.city ? model.city : null,
      telefonoContacto: model.contactPhone != original.contactPhone ? model.contactPhone : null,
      indicaciones: model.instructions != original.instructions ? model.instructions : null,
      esPredeterminada: model.isDefault != original.isDefault ? model.isDefault : null,
    );
  }

  // ========================================================================
  // PAYMENT METHOD RESPONSE → PAYMENT METHOD MODEL
  // ========================================================================

  /// Convierte un [PaymentMethodResponse] (DTO) a [PaymentMethod] (Model de dominio).
  static PaymentMethod paymentMethodToModel(PaymentMethodResponse dto) {
    return PaymentMethod(
      id: dto.id,
      type: dto.tipo,
      typeDisplay: dto.tipoDisplay,
      alias: dto.alias,
      proofImageUrl: dto.comprobantePago,
      notes: dto.observaciones,
      hasProof: dto.tieneComprobante,
      requiresVerification: dto.requiereVerificacion,
      isDefault: dto.esPredeterminado,
      active: dto.activo,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
    );
  }

  // ========================================================================
  // PAYMENT METHOD MODEL → CREATE PAYMENT METHOD REQUEST
  // ========================================================================

  /// Convierte un [PaymentMethod] (Model) a [CreatePaymentMethodRequest] (DTO).
  static CreatePaymentMethodRequest paymentMethodToCreateRequest(PaymentMethod model) {
    return CreatePaymentMethodRequest(
      tipo: model.type,
      alias: model.alias,
      observaciones: model.notes,
      esPredeterminado: model.isDefault,
    );
  }

  // ========================================================================
  // PAYMENT METHOD MODEL → UPDATE PAYMENT METHOD REQUEST
  // ========================================================================

  /// Convierte un [PaymentMethod] (Model) a [UpdatePaymentMethodRequest] (DTO).
  static UpdatePaymentMethodRequest paymentMethodToUpdateRequest(PaymentMethod model) {
    return UpdatePaymentMethodRequest(
      tipo: model.type,
      alias: model.alias,
      observaciones: model.notes,
      esPredeterminado: model.isDefault,
    );
  }

  /// Convierte un [PaymentMethod] a [UpdatePaymentMethodRequest] con solo los campos modificados.
  static UpdatePaymentMethodRequest paymentMethodToPartialUpdateRequest(
    PaymentMethod model, {
    required PaymentMethod original,
  }) {
    return UpdatePaymentMethodRequest(
      tipo: model.type != original.type ? model.type : null,
      alias: model.alias != original.alias ? model.alias : null,
      observaciones: model.notes != original.notes ? model.notes : null,
      esPredeterminado: model.isDefault != original.isDefault ? model.isDefault : null,
    );
  }
}
