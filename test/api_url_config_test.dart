import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/core/api_client.dart';
import 'package:sentinel_app/core/constants.dart';

void main() {
  group('ApiClient URL Normalization Tests', () {
    test('appends /api if missing from domain', () {
      expect(
        ApiClient.normalizeUrl('https://knowing-terrapin.ngrok-free.app'),
        equals('https://knowing-terrapin.ngrok-free.app/api'),
      );
    });

    test('retains /api if already present', () {
      expect(
        ApiClient.normalizeUrl('https://knowing-terrapin.ngrok-free.app/api'),
        equals('https://knowing-terrapin.ngrok-free.app/api'),
      );
    });

    test('strips trailing slashes correctly', () {
      expect(
        ApiClient.normalizeUrl('https://knowing-terrapin.ngrok-free.app/api/'),
        equals('https://knowing-terrapin.ngrok-free.app/api'),
      );
      expect(
        ApiClient.normalizeUrl('https://knowing-terrapin.ngrok-free.app///'),
        equals('https://knowing-terrapin.ngrok-free.app/api'),
      );
    });

    test('prepends https:// if protocol is omitted', () {
      expect(
        ApiClient.normalizeUrl('knowing-terrapin.ngrok-free.app'),
        equals('https://knowing-terrapin.ngrok-free.app/api'),
      );
    });

    test('supports http protocol for local dev', () {
      expect(
        ApiClient.normalizeUrl('http://10.0.2.2:3000'),
        equals('http://10.0.2.2:3000/api'),
      );
    });

    test('falls back to default if string is empty', () {
      expect(
        ApiClient.normalizeUrl('   '),
        equals(AppConstants.apiBaseUrl),
      );
    });
  });
}
