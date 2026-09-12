import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GenerateSlotsDialog extends StatefulWidget {
  final String? initialDate;
  final VoidCallback onSlotsGenerated;

  const GenerateSlotsDialog({
    super.key,
    this.initialDate,
    required this.onSlotsGenerated,
  });

  @override
  State<GenerateSlotsDialog> createState() => _GenerateSlotsDialogState();
}

class _GenerateSlotsDialogState extends State<GenerateSlotsDialog> {
  late String _selectedDate;
  final startController = TextEditingController(text: "09:00");
  final endController = TextEditingController(text: "17:00");
  final durationController = TextEditingController(text: "30");
  final breakStartController = TextEditingController();
  final breakEndController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.initialDate ?? DateTime.now().toIso8601String().split("T")[0];
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    durationController.dispose();
    breakStartController.dispose();
    breakEndController.dispose();
    super.dispose();
  }

  String _formatTime(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(':');
    if (parts.length == 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return '$h:$m:00';
    } else if (parts.length == 3) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      final s = parts[2].padLeft(2, '0');
      return '$h:$m:$s';
    }
    return trimmed;
  }

  Future<void> _submit() async {
    final duration = int.tryParse(durationController.text.trim());
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid slot duration in minutes"),
        ),
      );
      return;
    }

    if (startController.text.trim().isEmpty ||
        endController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start and End times are required")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final breaks = breakStartController.text.trim().isNotEmpty &&
            breakEndController.text.trim().isNotEmpty
        ? [
            {
              "start": _formatTime(breakStartController.text),
              "end": _formatTime(breakEndController.text),
            },
          ]
        : <Map<String, String>>[];

    final success = await ApiService().generateSlots(
      date: _selectedDate,
      dayStart: _formatTime(startController.text),
      dayEnd: _formatTime(endController.text),
      slotDurationMinutes: duration,
      breaks: breaks,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      widget.onSlotsGenerated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Slots generated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.lastError ?? "Error generating slots. Check your slot fields.",
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: const Row(
        children: [
          Icon(Icons.more_time_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 10),
          Text("Generate Slots"),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Configure your daily consultation slots",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final initial =
                      DateTime.tryParse(_selectedDate) ?? DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate =
                          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Date: $_selectedDate",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        "Change",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: "Start Time",
                        hintText: "09:00",
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: "End Time",
                        hintText: "17:00",
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Slot Duration (minutes)",
                  hintText: "30",
                  suffixText: "min",
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Break Time (Optional)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: breakStartController,
                      decoration: const InputDecoration(
                        labelText: "Break Start",
                        hintText: "13:00",
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: breakEndController,
                      decoration: const InputDecoration(
                        labelText: "Break End",
                        hintText: "14:00",
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(110, 40),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text("Generate"),
        ),
      ],
    );
  }
}
