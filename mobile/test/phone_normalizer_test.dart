import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/util/phone_normalizer.dart';

void main() {
  group('normalizeUserPhoneForProfile', () {
    test('returns local Ecuador format when number already starts with 0', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '0991234567',
        dialCode: '+593',
      );

      expect(result, '0991234567');
    });

    test('adds leading 0 for Ecuador local 9-digit numbers', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '991234567',
        dialCode: '+593',
      );

      expect(result, '0991234567');
    });

    test('strips non-digits for Ecuador and keeps local format', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '099 123 4567',
        dialCode: '+593',
      );

      expect(result, '0991234567');
    });

    test('handles Ecuador numbers that already include the dial code', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '+593986666537',
        dialCode: '+593',
      );

      expect(result, '0986666537');
    });

    test('returns E.164 for non-Ecuador numbers', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '415-555-2671',
        dialCode: '+1',
      );

      expect(result, '+14155552671');
    });

    test('returns digits when dial code is empty', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '0991234567',
        dialCode: '',
      );

      expect(result, '0991234567');
    });

    test('returns empty string when number is empty', () {
      final result = normalizeUserPhoneForProfile(
        rawNumber: '',
        dialCode: '+593',
      );

      expect(result, '');
    });
  });
}
