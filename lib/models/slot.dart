class Slot {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  String status; // "available", "booked", "frozen"

  Slot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      date: json['date']?.toString()?? '',
      startTime: json['start_time'] ?? json['startTime'] ?? '',
      endTime: json['end_time'] ?? json['endTime'] ?? '',
      status: json['status'] ?? 'available',
    );
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();
    final maybeIso = trimmed.endsWith('Z')
        ? trimmed.replaceFirst('Z', '+00:00')
        : trimmed;

    final parsed = DateTime.tryParse(maybeIso);
    if (parsed != null) {
      return parsed;
    }

    final timeOnlyMatch = RegExp(
      r'^\d{1,2}:\d{2}(:\d{2})?$',
    ).firstMatch(trimmed);
    if (timeOnlyMatch == null) {
      return null;
    }

    final parts = trimmed.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final second = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }

  bool get isExpired {
    final now = DateTime.now();
    final start = _parseDateTime(startTime);
    final end = _parseDateTime(endTime);

    if (start != null && now.isAfter(start)) {
      return true;
    }

    if (start == null && end != null && now.isAfter(end)) {
      return true;
    }

    return false;
  }
}
