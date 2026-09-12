import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:docappoint/models/slot.dart';
import 'package:docappoint/models/appointment.dart';
import 'package:docappoint/services/auth_service.dart';
import 'package:docappoint/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  FlutterSecureStorage.setMockInitialValues({});

  group('Slot Model and Expiration Tests', () {
    test('Slot parses both camelCase and snake_case correctly', () {
      final slotSnake = Slot.fromJson({
        'id': 1,
        'date': '2026-09-15',
        'start_time': '10:00:00',
        'end_time': '10:30:00',
        'status': 'available',
      });
      expect(slotSnake.id, 1);
      expect(slotSnake.date, '2026-09-15');
      expect(slotSnake.startTime, '10:00:00');
      expect(slotSnake.endTime, '10:30:00');
      expect(slotSnake.status, 'available');

      final slotCamel = Slot.fromJson({
        'id': '2',
        'date': '2026-09-15',
        'startTime': '11:00:00',
        'endTime': '11:30:00',
        'status': 'booked',
      });
      expect(slotCamel.id, 2);
      expect(slotCamel.startTime, '11:00:00');
      expect(slotCamel.endTime, '11:30:00');
      expect(slotCamel.status, 'booked');
    });

    test('Slot.isExpired correctly checks date and time', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];

      // Past date is always expired
      final pastSlot = Slot(
        id: 1,
        date: yesterdayStr,
        startTime: '10:00:00',
        endTime: '10:30:00',
        status: 'available',
      );
      expect(pastSlot.isExpired, isTrue);

      // Future date is not expired even if the time of day has passed today
      final futureSlot = Slot(
        id: 2,
        date: tomorrowStr,
        startTime: '01:00:00',
        endTime: '01:30:00',
        status: 'available',
      );
      expect(futureSlot.isExpired, isFalse);

      // Today with past time
      final pastTimeHour = (now.hour - 2).clamp(0, 23).toString().padLeft(2, '0');
      final todayPastSlot = Slot(
        id: 3,
        date: todayStr,
        startTime: '$pastTimeHour:00:00',
        endTime: '$pastTimeHour:30:00',
        status: 'available',
      );
      if (now.hour >= 2) {
        expect(todayPastSlot.isExpired, isTrue);
      }

      // Today with future time
      if (now.hour < 22) {
        final futureTimeHour = (now.hour + 1).toString().padLeft(2, '0');
        final todayFutureSlot = Slot(
          id: 4,
          date: todayStr,
          startTime: '$futureTimeHour:00:00',
          endTime: '$futureTimeHour:30:00',
          status: 'available',
        );
        expect(todayFutureSlot.isExpired, isFalse);
      }
    });
  });

  group('DoctorAppointment Model Tests', () {
    test('Parses snake_case and camelCase attributes cleanly', () {
      final apptSnake = DoctorAppointment.fromJson({
        'appointment_id': 101,
        'date': '2026-09-15',
        'start_time': '09:00:00',
        'end_time': '09:30:00',
        'status': 'booked',
        'patient_name': 'Alice Patient',
      });
      expect(apptSnake.appointmentId, 101);
      expect(apptSnake.date, '2026-09-15');
      expect(apptSnake.startTime, '09:00:00');
      expect(apptSnake.endTime, '09:30:00');
      expect(apptSnake.status, 'booked');
      expect(apptSnake.patientName, 'Alice Patient');

      final apptCamel = DoctorAppointment.fromJson({
        'appointmentId': '102',
        'date': '2026-09-16',
        'startTime': '14:00:00',
        'endTime': '14:30:00',
        'status': 'completed',
        'patientName': 'Bob Patient',
      });
      expect(apptCamel.appointmentId, 102);
      expect(apptCamel.date, '2026-09-16');
      expect(apptCamel.startTime, '14:00:00');
      expect(apptCamel.endTime, '14:30:00');
      expect(apptCamel.status, 'completed');
      expect(apptCamel.patientName, 'Bob Patient');
    });
  });

  group('Phase 3 Live Patient API Flow against Spring Boot', () {
    late AuthService authService;
    late ApiService apiService;
    late String testUsername;
    late String testPassword;

    setUpAll(() async {
      authService = AuthService();
      apiService = ApiService();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      testUsername = 'phase3pat$timestamp';
      final testPhone = '9${(timestamp % 1000000000).toString().padLeft(9, '0')}';
      testPassword = 'Password123!';

      // Register new patient
      final registered = await authService.register(testUsername, testPhone, testPassword);
      expect(registered, isTrue, reason: 'Patient registration should succeed: ${AuthService.lastError}');

      // Login patient
      final loginResult = await authService.login(testUsername, testPassword);
      expect(loginResult, isNotNull, reason: 'Patient login should succeed: ${AuthService.lastError}');
      expect(loginResult!['role'], 'patient');
      expect(AuthService.username, testUsername);
    });

    test('1. Get available slots for today via ApiService', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final slots = await apiService.getAvailableSlots(today);
      expect(slots, isNotNull);
      expect(slots, isA<List>());
    });

    test('2. Get patient appointments via ApiService', () async {
      final appts = await apiService.getPatientAppointments();
      expect(appts, isA<List>());
    });

    test('3. Booking non-existent slot captures Spring Boot error message', () async {
      final success = await apiService.bookAppointment(999999);
      expect(success, isFalse);
      expect(ApiService.lastError, isNotNull);
      expect(
        ApiService.lastError!.toLowerCase(),
        contains('not found'),
        reason: 'Error message from Spring Boot should indicate slot not found: ${ApiService.lastError}',
      );
    });

    test('4. Cancelling non-existent appointment captures Spring Boot error message', () async {
      final success = await apiService.cancelAppointment(999999);
      expect(success, isFalse);
      expect(ApiService.lastError, isNotNull);
      expect(
        ApiService.lastError!.toLowerCase(),
        contains('not found'),
        reason: 'Error message from Spring Boot should indicate appointment not found: ${ApiService.lastError}',
      );
    });
  });
}
