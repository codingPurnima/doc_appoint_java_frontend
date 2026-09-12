import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().trim();

    Color bg;
    Color border;
    Color text;
    Color dot;
    String label;

    switch (normalized) {
      case 'available':
        bg = AppColors.availableBg;
        border = AppColors.availableBorder;
        text = AppColors.availableText;
        dot = AppColors.availableDot;
        label = 'Available';
        break;
      case 'booked':
        bg = AppColors.bookedBg;
        border = AppColors.bookedBorder;
        text = AppColors.bookedText;
        dot = AppColors.bookedDot;
        label = 'Booked';
        break;
      case 'frozen':
        bg = AppColors.frozenBg;
        border = AppColors.frozenBorder;
        text = AppColors.frozenText;
        dot = AppColors.frozenDot;
        label = 'Frozen';
        break;
      case 'completed':
        bg = AppColors.completedBg;
        border = AppColors.completedBorder;
        text = AppColors.completedText;
        dot = AppColors.completedDot;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = AppColors.bookedBg;
        border = AppColors.bookedBorder;
        text = AppColors.bookedText;
        dot = AppColors.bookedDot;
        label = 'Cancelled';
        break;
      default:
        bg = AppColors.frozenBg;
        border = AppColors.frozenBorder;
        text = AppColors.frozenText;
        dot = AppColors.frozenDot;
        label = status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
