// lib/role_switch/models/roles.dart

enum AppRole { user, provider, courier }

AppRole parseRole(String? raw) {
  final value = raw?.toUpperCase() ?? '';
  switch (value) {
    case 'PROVEEDOR':
      return AppRole.provider;
    case 'REPARTIDOR':
      return AppRole.courier;
    case 'USUARIO':
    case 'CLIENTE':
    default:
      return AppRole.user;
  }
}

String roleToApi(AppRole role) {
  switch (role) {
    case AppRole.provider:
      return 'PROVEEDOR';
    case AppRole.courier:
      return 'REPARTIDOR';
    case AppRole.user:
      return 'USUARIO';
  }
}

String roleToDisplay(AppRole role) {
  switch (role) {
    case AppRole.provider:
      return 'Proveedor';
    case AppRole.courier:
      return 'Repartidor';
    case AppRole.user:
      return 'Cliente';
  }
}
