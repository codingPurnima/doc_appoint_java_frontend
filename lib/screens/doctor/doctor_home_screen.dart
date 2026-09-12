import 'package:docappoint/providers/doctor_home_provider.dart';
import 'package:docappoint/theme/app_theme.dart';
import 'package:docappoint/widgets/empty_state_view.dart';
import 'package:docappoint/widgets/slot_generation_dialog.dart';
import 'package:docappoint/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(doctorHomeProvider.notifier).fetchSlots();
    });
  }

  Widget buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            StatusBadge(status: "available"),
            SizedBox(width: 8),
            StatusBadge(status: "booked"),
            SizedBox(width: 8),
            StatusBadge(status: "frozen"),
            SizedBox(width: 8),
            StatusBadge(status: "completed"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorHomeProvider);
    final notifier = ref.read(doctorHomeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Welcome!"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLegend(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Schedule",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Manage today's consultation slots",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${state.slots.length} Total",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          "Loading schedule...",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : state.slots.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.calendar_today_outlined,
                        title: "No slots generated yet",
                        subtitle: "Tap the + button below to create consultation slots for today.",
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(14),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.35,
                        ),
                        itemCount: state.slots.length,
                        itemBuilder: (context, index) {
                          final slot = state.slots[index];
                          final status = slot.status.toLowerCase();

                          Color borderColor;
                          Color accentBg;
                          if (status == "available") {
                            borderColor = AppColors.availableBorder;
                            accentBg = AppColors.availableBg;
                          } else if (status == "booked") {
                            borderColor = AppColors.bookedBorder;
                            accentBg = AppColors.bookedBg;
                          } else if (status == "frozen") {
                            borderColor = AppColors.frozenBorder;
                            accentBg = AppColors.frozenBg;
                          } else {
                            borderColor = AppColors.completedBorder;
                            accentBg = AppColors.completedBg;
                          }

                          return InkWell(
                            onTap: () async {
                              if (slot.status == 'booked') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Cannot freeze a booked slot"),
                                  ),
                                );
                              } else if (slot.status == "available" ||
                                  slot.status == "frozen") {
                                try {
                                  await notifier.toggleFreezeSlot(slot.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Slot updated")),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Error updating slot")),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentBg,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(11),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        StatusBadge(status: slot.status),
                                        if (status == "available" || status == "frozen")
                                          Icon(
                                            status == "frozen"
                                                ? Icons.lock_outline
                                                : Icons.lock_open_outlined,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.zero,
                                        physics: const BouncingScrollPhysics(),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${slot.startTime} - ${slot.endTime}",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                status == "available"
                                                    ? "Tap to freeze"
                                                    : status == "frozen"
                                                        ? "Tap to unfreeze"
                                                        : status == "booked"
                                                            ? "Booked by patient"
                                                            : "Completed",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => GenerateSlotsDialog(
              onSlotsGenerated: () async {
                await notifier.fetchSlots();
              },
            ),
          );
        },
        tooltip: "Create slots",
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
