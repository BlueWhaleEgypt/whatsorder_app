import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerButton extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerButton({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 10),
        side: BorderSide(color: Colors.green.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        iconSize: 14,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      ),
      icon: const Icon(Icons.calendar_today_rounded, color: Colors.green),
      label: Text(
        DateFormat('dd MMM yyyy').format(selectedDate),
        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
      ),
      onPressed: () => _showModernDatePicker(context),
    );
  }

  Future<void> _showModernDatePicker(BuildContext context) async {
    DateTime tempDate = selectedDate;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          // insetPadding: const EdgeInsets.symmetric(
          //   horizontal: 16,
          //  vertical: 20,
          // ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 420,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Select Date",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // const SizedBox(height: 8),
                      CalendarDatePicker(
                        initialDate: tempDate,
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2035),
                        onDateChanged: (value) {
                          setState(() {
                            tempDate = value;
                          });
                        },
                      ),
                      // const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDateSelected(tempDate);
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Done"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
