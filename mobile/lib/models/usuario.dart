// lib/models/usuario.dart

import 'package:flutter/material.dart';
import '../config/api_config.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 👤 MODELO: PERFIL DE USUARIO
// ══════════════════════════════════════════════════════════════════════════════

class PerfilModel {
  final int id;
  final String usuarioEmail;
  final String usuarioNombre;
  final String firstName; 
  final String lastName;
  final String? fotoPerfil;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final int? edad;
  final double calificacion;
  final int totalResenas;
  final int totalPedidos;
  final int pedidosMesActual; // Agregado para coincidir con serializer
  final bool esClienteFrecuente;
  final bool tieneTelefono; // Campo calculado
  final bool puedeParticiparRifa;
  final bool notificacionesPedido;
  final bool notificacionesPromociones;
  final bool puedeRecibirNotificaciones; // Campo calculado
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  PerfilModel({
    required this.id,
    required this.usuarioEmail,
    required this.usuarioNombre,
    required this.firstName, // Nuevo
    required this.lastName,  // Nuevo
    this.fotoPerfil,
    this.telefono,
    this.fechaNacimiento,
    this.edad,
    required this.calificacion,
    required this.totalResenas,
    required this.totalPedidos,
    required this.pedidosMesActual,
    required this.esClienteFrecuente,
    required this.tieneTelefono,
    required this.puedeParticiparRifa,
    required this.notificacionesPedido,
    required this.notificacionesPromociones,
    required this.puedeRecibirNotificaciones,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ✅ FROM JSON CORREGIDO (Calcula campos faltantes)
  // ──────────────────────────────────────────────────────────────────────────
  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    // Helper para fechas seguras
    DateTime? parseDate(dynamic v) => 
        (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;

    // Extraemos teléfono para calcular 'tieneTelefono'
    final tel = json['telefono'] as String?;

    return PerfilModel(
      id: json['id'] as int,
      usuarioEmail: json['usuario_email'] as String? ?? '',
      usuarioNombre: json['usuario_nombre'] as String? ?? 'Usuario',
      fotoPerfil: json['foto_perfil'] as String?,
      telefono: tel,
      fechaNacimiento: parseDate(json['fecha_nacimiento']),
      edad: json['edad'] as int?,

      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      // Manejo seguro de números (int o double)
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      totalResenas: json['total_resenas'] as int? ?? 0,
      totalPedidos: json['total_pedidos'] as int? ?? 0,
      pedidosMesActual: json['pedidos_mes_actual'] as int? ?? 0,
      
      esClienteFrecuente: json['es_cliente_frecuente'] as bool? ?? false,
      puedeParticiparRifa: json['puede_participar_rifa'] as bool? ?? false,
      
      // 🛠️ CORRECCIÓN: Calculados localmente (Backend no envía estos booleanos)
      tieneTelefono: (tel != null && tel.isNotEmpty),
      
      notificacionesPedido: json['notificaciones_pedido'] as bool? ?? true,
      notificacionesPromociones: json['notificaciones_promociones'] as bool? ?? true,
      
      // 🛠️ CORRECCIÓN: Si hay fecha de token actualizado, es que tiene token activo
      puedeRecibirNotificaciones: json['fcm_token_actualizado'] != null,

      creadoEn: parseDate(json['creado_en']) ?? DateTime.now(),
      actualizadoEn: parseDate(json['actualizado_en']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_email': usuarioEmail,
      'usuario_nombre': usuarioNombre,
      'foto_perfil': fotoPerfil,
      'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'edad': edad,
      'calificacion': calificacion,
      'total_resenas': totalResenas,
      'total_pedidos': totalPedidos,
      'pedidos_mes_actual': pedidosMesActual,
      'es_cliente_frecuente': esClienteFrecuente,
      'tiene_telefono': tieneTelefono,
      'puede_participar_rifa': puedeParticiparRifa,
      'notificaciones_pedido': notificacionesPedido,
      'notificaciones_promociones': notificacionesPromociones,
      'puede_recibir_notificaciones': puedeRecibirNotificaciones,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }

  PerfilModel copyWith({
    int? id,
    String? usuarioEmail,
    String? usuarioNombre,
    String? firstName, // Agregado
    String? lastName,  // Agregado
    String? fotoPerfil,
    String? telefono,
    DateTime? fechaNacimiento,
    int? edad,
    double? calificacion,
    int? totalResenas,
    int? totalPedidos,
    int? pedidosMesActual,
    bool? esClienteFrecuente,
    bool? tieneTelefono,
    bool? puedeParticiparRifa,
    bool? notificacionesPedido,
    bool? notificacionesPromociones,
    bool? puedeRecibirNotificaciones,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return PerfilModel(
      id: id ?? this.id,
      usuarioEmail: usuarioEmail ?? this.usuarioEmail,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      // ✅ CORRECCIÓN: Se pasan los argumentos requeridos
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      edad: edad ?? this.edad,
      calificacion: calificacion ?? this.calificacion,
      totalResenas: totalResenas ?? this.totalResenas,
      totalPedidos: totalPedidos ?? this.totalPedidos,
      pedidosMesActual: pedidosMesActual ?? this.pedidosMesActual,
      esClienteFrecuente: esClienteFrecuente ?? this.esClienteFrecuente,
      tieneTelefono: tieneTelefono ?? this.tieneTelefono,
      puedeParticiparRifa: puedeParticiparRifa ?? this.puedeParticiparRifa,
      notificacionesPedido: notificacionesPedido ?? this.notificacionesPedido,
      notificacionesPromociones:
          notificacionesPromociones ?? this.notificacionesPromociones,
      puedeRecibirNotificaciones:
          puedeRecibirNotificaciones ?? this.puedeRecibirNotificaciones,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  String? get fotoPerfilUrl {
    if (fotoPerfil == null || fotoPerfil!.isEmpty) return null;
    if (fotoPerfil!.startsWith('http')) return fotoPerfil;
    
    // Construcción segura de URL
    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
        
    final path = fotoPerfil!.startsWith('/') ? fotoPerfil! : '/$fotoPerfil';
    
    return '$baseUrl$path';
  }

  @override
  String toString() =>
      'PerfilModel(id: $id, email: $usuarioEmail, nombre: $usuarioNombre)';
}

// ══════════════════════════════════════════════════════════════════════════════
// 📍 MODELO: DIRECCIÓN FAVORITA
// ══════════════════════════════════════════════════════════════════════════════

class DireccionModel {
  final String id;
  final String tipo;
  final String tipoDisplay;
  final String etiqueta;
  final String direccion;
  final String? referencia;
  final String? pisoApartamento;
  final String? calleSecundaria;
  final double latitud;
  final double longitud;
  final String? ciudad;
  final String? telefonoContacto;
  final String? indicaciones;
  final bool esPredeterminada;
  final bool activa;
  final int vecesUsada;
  final DateTime? ultimoUso;
  final String direccionCompleta;
  final DateTime createdAt;
  final DateTime updatedAt;

  DireccionModel({
    required this.id,
    required this.tipo,
    required this.tipoDisplay,
    required this.etiqueta,
    required this.direccion,
    this.referencia,
    this.pisoApartamento,
    this.calleSecundaria,
    required this.latitud,
    required this.longitud,
    this.ciudad,
    this.telefonoContacto,
    this.indicaciones,
    required this.esPredeterminada,
    required this.activa,
    required this.vecesUsada,
    this.ultimoUso,
    required this.direccionCompleta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic v) => v is String ? v : '';
    double safeDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    bool safeBool(dynamic v) => v is bool ? v : false;
    int safeInt(dynamic v) => v is int ? v : 0;

    DateTime parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return DireccionModel(
      id: safeString(json['id']),
      tipo: safeString(json['tipo']),
      tipoDisplay: safeString(json['tipo_display']),
      etiqueta: safeString(json['etiqueta']),
      direccion: safeString(json['direccion']),
      referencia: json['referencia'] as String?,
      pisoApartamento: json['piso_apartamento'] as String?,
      calleSecundaria: json['calle_secundaria'] as String?,
      latitud: safeDouble(json['latitud']),
      longitud: safeDouble(json['longitud']),
      ciudad: json['ciudad'] as String?,
      telefonoContacto: json['telefono_contacto'] as String? ?? json['telefono'] as String?,
      indicaciones: json['indicaciones'] as String? ?? json['indicaciones_entrega'] as String?,
      esPredeterminada: safeBool(json['es_predeterminada']),
      activa: safeBool(json['activa']),
      vecesUsada: safeInt(json['veces_usada']),
      ultimoUso: json['ultimo_uso'] != null
          ? DateTime.tryParse(json['ultimo_uso'])
          : null,
      direccionCompleta: safeString(json['direccion_completa']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'tipo_display': tipoDisplay,
      'etiqueta': etiqueta,
      'direccion': direccion,
      'referencia': referencia,
      'piso_apartamento': pisoApartamento,
      'calle_secundaria': calleSecundaria,
      'latitud': latitud,
      'longitud': longitud,
      'ciudad': ciudad,
      'telefono_contacto': telefonoContacto,
      'indicaciones': indicaciones,
      'es_predeterminada': esPredeterminada,
      'activa': activa,
      'veces_usada': vecesUsada,
      'ultimo_uso': ultimoUso?.toIso8601String(),
      'direccion_completa': direccionCompleta,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ✅ TO CREATE JSON (Optimizado para el backend)
  Map<String, dynamic> toCreateJson() {
    final data = <String, dynamic>{
      'tipo': tipo,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'es_predeterminada': esPredeterminada,
    };

    if (etiqueta.isNotEmpty) data['etiqueta'] = etiqueta;
    if (referencia != null && referencia!.isNotEmpty) data['referencia'] = referencia;
    if (pisoApartamento != null && pisoApartamento!.isNotEmpty) {
      data['piso_apartamento'] = pisoApartamento;
    }
    if (calleSecundaria != null && calleSecundaria!.isNotEmpty) {
      data['calle_secundaria'] = calleSecundaria;
    }
    if (ciudad != null && ciudad!.isNotEmpty) data['ciudad'] = ciudad;
    if (telefonoContacto != null && telefonoContacto!.isNotEmpty) {
      data['telefono_contacto'] = telefonoContacto;
    }
    if (indicaciones != null && indicaciones!.isNotEmpty) {
      data['indicaciones'] = indicaciones;
    }

    return data;
  }

  DireccionModel copyWith({
    String? id,
    String? tipo,
    String? tipoDisplay,
    String? etiqueta,
    String? direccion,
    String? referencia,
    String? pisoApartamento,
    String? calleSecundaria,
    double? latitud,
    double? longitud,
    String? ciudad,
    String? telefonoContacto,
    String? indicaciones,
    bool? esPredeterminada,
    bool? activa,
    int? vecesUsada,
    DateTime? ultimoUso,
    String? direccionCompleta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DireccionModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      tipoDisplay: tipoDisplay ?? this.tipoDisplay,
      etiqueta: etiqueta ?? this.etiqueta,
      direccion: direccion ?? this.direccion,
      referencia: referencia ?? this.referencia,
      pisoApartamento: pisoApartamento ?? this.pisoApartamento,
      calleSecundaria: calleSecundaria ?? this.calleSecundaria,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      ciudad: ciudad ?? this.ciudad,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
      indicaciones: indicaciones ?? this.indicaciones,
      esPredeterminada: esPredeterminada ?? this.esPredeterminada,
      activa: activa ?? this.activa,
      vecesUsada: vecesUsada ?? this.vecesUsada,
      ultimoUso: ultimoUso ?? this.ultimoUso,
      direccionCompleta: direccionCompleta ?? this.direccionCompleta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get iconoTipo {
    switch (tipo) {
      case 'casa': return '🏠';
      case 'trabajo': return '💼';
      default: return '📍';
    }
  }

  @override
  String toString() => 'DireccionModel(id: $id, etiqueta: $etiqueta, tipo: $tipo)';
}

// ══════════════════════════════════════════════════════════════════════════════
// 💳 MODELO: MÉTODO DE PAGO
// ══════════════════════════════════════════════════════════════════════════════

class MetodoPagoModel {
  final String id;
  final String tipo;
  final String tipoDisplay;
  final String alias;
  final String? comprobantePago; 
  final String? observaciones; 
  final bool tieneComprobante; 
  final bool requiereVerificacion; 
  final bool esPredeterminado;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  MetodoPagoModel({
    required this.id,
    required this.tipo,
    required this.tipoDisplay,
    required this.alias,
    this.comprobantePago,
    this.observaciones,
    required this.tieneComprobante,
    required this.requiereVerificacion,
    required this.esPredeterminado,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MetodoPagoModel.fromJson(Map<String, dynamic> json) {
    return MetodoPagoModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      tipoDisplay: json['tipo_display'] as String,
      alias: json['alias'] as String,
      comprobantePago: json['comprobante_pago'] as String?,
      observaciones: json['observaciones'] as String?,
      tieneComprobante: json['tiene_comprobante'] as bool? ?? false,
      requiereVerificacion: json['requiere_verificacion'] as bool? ?? false,
      esPredeterminado: json['es_predeterminado'] as bool,
      activo: json['activo'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'tipo_display': tipoDisplay,
      'alias': alias,
      'comprobante_pago': comprobantePago,
      'observaciones': observaciones,
      'tiene_comprobante': tieneComprobante,
      'requiere_verificacion': requiereVerificacion,
      'es_predeterminado': esPredeterminado,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'tipo': tipo,
      'alias': alias,
      if (observaciones != null && observaciones!.isNotEmpty)
        'observaciones': observaciones,
      'es_predeterminado': esPredeterminado,
    };
  }

  MetodoPagoModel copyWith({
    String? id,
    String? tipo,
    String? tipoDisplay,
    String? alias,
    String? comprobantePago,
    String? observaciones,
    bool? tieneComprobante,
    bool? requiereVerificacion,
    bool? esPredeterminado,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MetodoPagoModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      tipoDisplay: tipoDisplay ?? this.tipoDisplay,
      alias: alias ?? this.alias,
      comprobantePago: comprobantePago ?? this.comprobantePago,
      observaciones: observaciones ?? this.observaciones,
      tieneComprobante: tieneComprobante ?? this.tieneComprobante,
      requiereVerificacion: requiereVerificacion ?? this.requiereVerificacion,
      esPredeterminado: esPredeterminado ?? this.esPredeterminado,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get iconoTipo {
    switch (tipo) {
      case 'efectivo': return '💵';
      case 'transferencia': return '🏦';
      case 'tarjeta': return '💳';
      default: return '💰';
    }
  }

  // ✅ CORRECCIÓN: Construcción segura de URL con ApiConfig
  String? get urlComprobante {
    if (comprobantePago == null || comprobantePago!.isEmpty) return null;
    if (comprobantePago!.startsWith('http')) return comprobantePago;

    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final path = comprobantePago!.startsWith('/') 
        ? comprobantePago! 
        : '/$comprobantePago';

    return '$baseUrl$path';
  }

  bool get esValido {
    if (tipo == 'efectivo') return true;
    if (tipo == 'transferencia') return tieneComprobante;
    return true;
  }

  String get mensajeComprobante {
    if (tipo == 'efectivo') return 'No requiere comprobante';
    if (tipo == 'transferencia') {
      if (tieneComprobante) {
        return requiereVerificacion
            ? '⏳ Pendiente de verificación'
            : '✅ Comprobante verificado';
      }
      return '❌ Falta subir comprobante';
    }
    return '-';
  }

  Color get colorEstado {
    if (tipo == 'efectivo') return Colors.grey;
    if (tipo == 'transferencia') {
      if (tieneComprobante) {
        return requiereVerificacion ? Colors.orange : Colors.green;
      }
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData get iconoEstado {
    if (tipo == 'efectivo') return Icons.attach_money;
    if (tipo == 'transferencia') {
      if (tieneComprobante) {
        return requiereVerificacion ? Icons.pending : Icons.check_circle;
      }
      return Icons.error;
    }
    return Icons.help_outline;
  }

  bool get puedeUsarse {
    if (!activo) return false;
    if (tipo == 'efectivo') return true;
    if (tipo == 'transferencia') return tieneComprobante && !requiereVerificacion;
    return true;
  }

  String get descripcionCompleta {
    final buffer = StringBuffer();
    buffer.write('$tipoDisplay - $alias');
    if (observaciones != null && observaciones!.isNotEmpty) {
      buffer.write(' ($observaciones)');
    }
    if (!puedeUsarse) buffer.write(' [No disponible]');
    return buffer.toString();
  }

  bool get tieneProblemas => observaciones != null && observaciones!.isNotEmpty;

  @override
  String toString() => 'MetodoPagoModel(id: $id, alias: $alias, tipo: $tipo)';
}

// ══════════════════════════════════════════════════════════════════════════════
// 📊 MODELO: ESTADÍSTICAS DE USUARIO
// ══════════════════════════════════════════════════════════════════════════════

class EstadisticasModel {
  final int totalPedidos;
  final int pedidosMesActual;
  final double calificacion;
  final int totalResenas;
  final bool esClienteFrecuente;
  final bool puedeParticiparRifa;
  final int totalDirecciones;
  final int totalMetodosPago;

  EstadisticasModel({
    required this.totalPedidos,
    required this.pedidosMesActual,
    required this.calificacion,
    required this.totalResenas,
    required this.esClienteFrecuente,
    required this.puedeParticiparRifa,
    required this.totalDirecciones,
    required this.totalMetodosPago,
  });

  factory EstadisticasModel.fromJson(Map<String, dynamic> json) {
    return EstadisticasModel(
      totalPedidos: json['total_pedidos'] as int? ?? 0,
      pedidosMesActual: json['pedidos_mes_actual'] as int? ?? 0,
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      totalResenas: json['total_resenas'] as int? ?? 0,
      esClienteFrecuente: json['es_cliente_frecuente'] as bool? ?? false,
      puedeParticiparRifa: json['puede_participar_rifa'] as bool? ?? false,
      totalDirecciones: json['total_direcciones'] as int? ?? 0,
      totalMetodosPago: json['total_metodos_pago'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_pedidos': totalPedidos,
      'pedidos_mes_actual': pedidosMesActual,
      'calificacion': calificacion,
      'total_resenas': totalResenas,
      'es_cliente_frecuente': esClienteFrecuente,
      'puede_participar_rifa': puedeParticiparRifa,
      'total_direcciones': totalDirecciones,
      'total_metodos_pago': totalMetodosPago,
    };
  }

  String get nivelCliente {
    if (esClienteFrecuente) return 'Cliente VIP';
    if (totalPedidos >= 5) return 'Cliente Regular';
    return 'Cliente';
  }

  double get progresoRifa {
    if (pedidosMesActual >= 3) return 1.0;
    return pedidosMesActual / 3.0;
  }

  String get mensajeRifa {
    if (puedeParticiparRifa) return '🎉 ¡Participas en la rifa!';
    final faltantes = 3 - pedidosMesActual;
    return 'Te faltan $faltantes pedido${faltantes == 1 ? '' : 's'} para la rifa';
  }

  @override
  String toString() => 'EstadisticasModel(pedidos: $totalPedidos)';
}
