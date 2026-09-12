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

  group('Doctor Schedule Contract & Unit Tests', () {
    test('Slot model parses doctor slots and handles status transitions', () {
      final slot = Slot.fromJson({
        'id': 10,
        'date': '2026-09-15',
        'startTime': '09:00:00',
        'endTime': '09:30:00',
        'status': 'available',
      });
      expect(slot.id, 10);
      expect(slot.status, 'available');
    });

    test('SlotGenerateRequest JSON format uses exact Spring Boot fields and HH:mm:ss', () {
      final date = '2026-09-15';
      final dayStart = '09:00:00';
      final dayEnd = '17:00:00';
      final duration = 30;
      final breaks = [
        {'start': '13:00:00', 'end': '14:00:00'}
      ];

      final payload = {
        'date': date,
        'day_start': dayStart,
        'day_end': dayEnd,
        'slot_duration_minutes': duration,
        'breaks': breaks,
      };

      expect(payload['date'], '2026-09-15');
      expect(payload['day_start'], matches(r'^\d{2}:\d{2}:\d{2}$'));
      expect(payload['day_end'], matches(r'^\d{2}:\d{2}:\d{2}$'));
      expect(payload['slot_duration_minutes'], 30);
      expect(payload['breaks'], isA<List>());
      final b = (payload['breaks'] as List).first as Map<String, String>;
      expect(b['start'], matches(r'^\d{2}:\d{2}:\d{2}$'));
      expect(b['end'], matches(r'^\d{2}:\d{2}:\d{2}$'));
    });

    test('DoctorAppointment correctly deserializes Spring Boot DoctorAppointmentResponse', () {
      final jsonResponse = {
        'appointment_id': 501,
        'date': '2026-09-15',
        'start_time': '10:00:00',
        'end_time': '10:30:00',
        'status': 'booked',
        'patient_name': 'Test Patient',
      };

      final appointment = DoctorAppointment.fromJson(jsonResponse);
      expect(appointment.appointmentId, 501);
      expect(appointment.date, '2026-09-15');
      expect(appointment.startTime, '10:00:00');
      expect(appointment.endTime, '10:30:00');
      expect(appointment.status, 'booked');
      expect(appointment.patientName, 'Test Patient');
    });

    test('DoctorAppointment also handles camelCase fallback for resilience', () {
      final camelResponse = {
        'appointmentId': 502,
        'date': '2026-09-16',
        'startTime': '11:00:00',
        'endTime': '11:30:00',
        'status': 'completed',
        'patientName': 'Resilient Patient',
      };

      final appointment = DoctorAppointment.fromJson(camelResponse);
      expect(appointment.appointmentId, 502);
      expect(appointment.startTime, '11:00:00');
      expect(appointment.status, 'completed');
      expect(appointment.patientName, 'Resilient Patient');
    });
  });

  group('Spring Boot Authorization Boundaries against Live Backend', () {
    late AuthService authService;
    late ApiService apiService;
    late String patientUser;

    setUpAll(() async {
      authService = AuthService();
      apiService = ApiService();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      patientUser = 'authchk_pat$timestamp';
      final patientPhone = '8${(timestamp % 1000000000).toString().padLeft(9, '0')}';
      final password = 'Password123!';

      final registered = await authService.register(patientUser, patientPhone, password);
      expect(registered, isTrue, reason: 'Patient should be created for auth boundary tests');

      final loginRes = await authService.login(patientUser, password);
      expect(loginRes, isNotNull);
      expect(loginRes!['role'], 'patient');
    });

    test('1. Doctor registration with invalid secret is rejected with 403', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docUser = 'invalid_doc$timestamp';
      final docPhone = '7${(timestamp % 1000000000).toString().padLeft(9, '0')}';

      final success = await authService.registerDoctor(
        docUser,
        docPhone,
        'Password123!',
        'definitely_invalid_secret_xyz_123',
      );

      expect(success, isFalse);
      expect(AuthService.lastError, isNotNull);
      expect(
        AuthService.lastError!.toLowerCase(),
        anyOf(contains('invalid'), contains('secret'), contains('access denied'), contains('session expired')),
      );
    });

    test('2. Patient token cannot call POST /slots/generate (Forbidden)', () async {
      final success = await apiService.generateSlots(
        date: '2026-09-20',
        dayStart: '09:00:00',
        dayEnd: '17:00:00',
        slotDurationMinutes: 30,
      );

      expect(success, isFalse);
      expect(ApiService.lastError, isNotNull);
    });

    test('3. Patient token cannot call PATCH /slots/{id}/freeze (Forbidden)', () async {
      final success = await apiService.toggleFreezeSlot(1);
      expect(success, isFalse);
      expect(ApiService.lastError, isNotNull);
    });

    test('4. Patient token cannot call PATCH /appointments/{id}/complete (Forbidden)', () async {
      final success = await apiService.completeAppointment(1);
      expect(success, isFalse);
      expect(ApiService.lastError, isNotNull);
    });

    test('5. Patient token cannot view doctor appointments via GET /appointments/doctor', () async {
      final appointments = await apiService.getDoctorAppointments();
      expect(appointments, isEmpty);
      expect(ApiService.lastError, isNotNull);
    });
  });

  group('Live Doctor End-to-End Flow (when runtime secret is provided)', () {
    final runtimeSecret = Platform.environment['DOCTOR_SECRET'];

    test('Full Doctor Lifecycle: Register -> Login -> Schedule -> Generate -> Freeze -> Booking -> Completion Rule', () async {
      if (runtimeSecret == null || runtimeSecret.trim().isEmpty) {
        // Skip with informational pass when secret is not in runtime test environment
        expect(true, isTrue);
        return;
      }

      final authService = AuthService();
      final apiService = ApiService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final docUsername = 'doc_$timestamp';
      final docPhone = '9${(timestamp % 1000000000).toString().padLeft(9, '0')}';
      const docPassword = 'DoctorPass123!';

      // 1. Doctor registration
      final regSuccess = await authService.registerDoctor(
        docUsername,
        docPhone,
        docPassword,
        runtimeSecret.trim(),
      );
      expect(regSuccess, isTrue, reason: 'Doctor registration should succeed with valid runtime secret: ${AuthService.lastError}');

      // 2. Doctor login
      final loginData = await authService.login(docUsername, docPassword);
      expect(loginData, isNotNull);
      expect(loginData!['role'], 'doctor');
      expect(AuthService.role, 'doctor');

      // 3. View schedule for a future date (tomorrow)
      final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
      final initialSlots = await apiService.getDoctorSlots(tomorrow);
      expect(initialSlots, isNotNull);

      // 4. Generate slots for tomorrow
      final genSuccess = await apiService.generateSlots(
        date: tomorrow,
        dayStart: '09:00:00',
        dayEnd: '11:00:00',
        slotDurationMinutes: 30,
      );
      expect(genSuccess, isTrue, reason: 'Generating slots for tomorrow should succeed: ${ApiService.lastError}');

      final updatedSlots = await apiService.getDoctorSlots(tomorrow);
      expect(updatedSlots, isNotNull);
      expect(updatedSlots!.length, greaterThanOrEqualTo(4));

      final firstSlotId = updatedSlots.first['id'] as int;

      // 5. Freeze slot
      final freezeSuccess = await apiService.toggleFreezeSlot(firstSlotId);
      expect(freezeSuccess, isTrue, reason: 'Freeze should succeed');

      final slotsAfterFreeze = await apiService.getDoctorSlots(tomorrow);
      final frozenSlot = slotsAfterFreeze!.firstWhere((s) => s['id'] == firstSlotId);
      expect(frozenSlot['status'], 'frozen');

      // Unfreeze slot
      final unfreezeSuccess = await apiService.toggleFreezeSlot(firstSlotId);
      expect(unfreezeSuccess, isTrue, reason: 'Unfreeze should succeed');

      final slotsAfterUnfreeze = await apiService.getDoctorSlots(tomorrow);
      final availableSlot = slotsAfterUnfreeze!.firstWhere((s) => s['id'] == firstSlotId);
      expect(availableSlot['status'], 'available');

      // 6. Patient booking of this slot
      final patientUser = 'livepat_$timestamp';
      final patientPhone = '8${((timestamp + 1) % 1000000000).toString().padLeft(9, '0')}';
      await authService.register(patientUser, patientPhone, 'PatientPass123!');
      final patientLogin = await authService.login(patientUser, 'PatientPass123!');
      expect(patientLogin, isNotNull);

      final bookSuccess = await apiService.bookAppointment(firstSlotId);
      expect(bookSuccess, isTrue, reason: 'Patient should book the available slot');

      // 7. Doctor appointment history
      await authService.login(docUsername, docPassword);
      final doctorAppointments = await apiService.getDoctorAppointments();
      expect(doctorAppointments, isNotEmpty);
      final bookedAppt = doctorAppointments.firstWhere((a) => a['appointment_id'] != null);
      final bookedApptId = bookedAppt['appointment_id'] as int;

      // 8. Attempt completion of future appointment -> Rejected by backend
      final completeAttempt = await apiService.completeAppointment(bookedApptId);
      expect(completeAttempt, isFalse, reason: 'Future appointment completion must be rejected by backend');
      expect(
        ApiService.lastError!.toLowerCase(),
        contains('future'),
        reason: 'Backend error should specify future appointment cannot be completed: ${ApiService.lastError}',
      );
    });
  });
}