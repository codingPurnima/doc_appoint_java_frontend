class DoctorAppointment {
  final int appointmentId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String patientName;

  DoctorAppointment({
    required this.appointmentId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.patientName,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    return DoctorAppointment(
      appointmentId: json['appointment_id'] is int
          ? json['appointment_id'] as int
          : json['appointmentId'] is int
              ? json['appointmentId'] as int
              : json['id'] is int
                  ? json['id'] as int
                  : int.tryParse(
                        '${json['appointment_id'] ?? json['appointmentId'] ?? json['id']}',
                      ) ??
                      0,
      date: json['date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ??
          json['startTime']?.toString() ??
          '',
      endTime:
          json['end_time']?.toString() ?? json['endTime']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ??
          json['patientName']?.toString() ??
          '',
    );
  }
}