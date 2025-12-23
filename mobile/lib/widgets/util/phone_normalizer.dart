// lib/utils/phone_normalizer.dart

String normalizeUserPhoneForProfile({
  required String rawNumber,
  required String dialCode,
}) {
  final trimmed = rawNumber.trim();
  if (trimmed.isEmpty) return '';

  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  final dial = dialCode.replaceAll(RegExp(r'\D'), '');
  if (dial.isNotEmpty && digits.startsWith(dial)) {
    digits = digits.substring(dial.length);
  }
  if (dial.isEmpty) return digits;

  // Ecuador: backend espera 09xxxxxxxx (10 digitos) O +5939xxxxxxxx.
  // Preferimos enviar formato Internacional E.164 (+5939xxxxxxxx) para evitar
  // ambigüedades con el regex del backend y la librería phonenumbers.
  if (dial == '593') {
    // Si tiene 0 inicial (ej: 098...), lo quitamos para normalizar
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    // Ahora digits debería tener 9 dígitos (ej: 98...)
    // Recuperamos el formato +593...
    return '+$dial$digits';
  }

  return '+$dial$digits';
}
