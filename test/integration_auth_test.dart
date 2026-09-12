import 'dart:io';
import 'package:docappoint/services/api_service.dart';
import 'package:docappoint/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  FlutterSecureStorage.setMockInitialValues({});

  final authService = AuthService();
  final apiService = ApiService();

  test('Full Phase 2 Authentication Integration against Spring Boot', () async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testUsername = 'pat$timestamp';
    final testPhone = '9${(timestamp % 1000000000).toString().padLeft(9, '0')}';
    final testPassword = 'Password123!';

    // STEP 1: Register a new patient
    final regSuccess = await authService.register(
      testUsername,
      testPhone,
      testPassword,
    );
    expect(regSuccess, isTrue, reason: 'Registration should succeed');
    expect(AuthService.lastError, isNull);

    // STEP 2: Duplicate registration error handling
    final dupSuccess = await authService.register(
      testUsername,
      testPhone,
      testPassword,
    );
    expect(dupSuccess, isFalse, reason: 'Duplicate registration should fail');
    expect(AuthService.lastError, contains('already taken'));

    // STEP 3: Invalid login error handling
    final badLogin = await authService.login(testUsername, 'WrongPassword!');
    expect(badLogin, isNull);
    expect(AuthService.lastError, isNotNull);

    // STEP 4: Successful login & token persistence
    final loginResult = await authService.login(testUsername, testPassword);
    expect(loginResult, isNotNull);
    expect(loginResult!['access_token'], isNotEmpty);
    expect(loginResult['role'], equals('patient'));
    expect(AuthService.isLoggedIn, isTrue);
    expect(AuthService.accessToken, isNotEmpty);
    expect(AuthService.refreshToken, isNotEmpty);
    expect(AuthService.role, equals('patient'));

    // STEP 5: Session restoration (hasValidSession)
    final hasSession = await authService.hasValidSession();
    expect(hasSession, isTrue);

    // Simulate app restart by creating a fresh AuthService instance and calling loadTokens
    final freshAuthService = AuthService();
    await freshAuthService.loadTokens();
    expect(AuthService.isLoggedIn, isTrue);
    expect(AuthService.role, equals('patient'));

    // STEP 6: Direct /auth/refresh via AuthService
    final newAccessToken = await authService.refreshAccessToken();
    expect(newAccessToken, isNotNull);
    expect(newAccessToken, isNotEmpty);
    expect(AuthService.accessToken, equals(newAccessToken));

    // STEP 7: Authenticated ApiService request
    final appointmentsResponse = await apiService.getRequest('/appointments/me');
    expect(appointmentsResponse.statusCode, 200);

    // STEP 8: Automatic 401/403 handling & token refresh in ApiService
    // Set an invalid token in storage and memory
    const secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'access_token', value: 'invalid_expired_token');
    await authService.loadTokens();
    expect(AuthService.accessToken, equals('invalid_expired_token'));

    // ApiService request should hit 403/401, call refreshAccessToken, get a valid token, and retry
    final autoRefreshResponse = await apiService.getRequest('/appointments/me');
    expect(autoRefreshResponse.statusCode, 200, reason: 'Request should succeed after auto-refresh');
    expect(AuthService.accessToken, isNot(equals('invalid_expired_token')));

    // STEP 9: Logout & session clearing
    await authService.logout();
    expect(AuthService.isLoggedIn, isFalse);
    expect(AuthService.accessToken, isNull);
    expect(AuthService.refreshToken, isNull);
    expect(AuthService.role, isNull);
    final sessionAfterLogout = await authService.hasValidSession();
    expect(sessionAfterLogout, isFalse);
  });
}

