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
      appointmentId: json['appointment_id'],
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? '',
      patientName: json['patient_name'] ?? '',
    );
  }
}