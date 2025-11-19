import 'package:flutter/material.dart';

enum DayOfWeek {
  monday('Monday', 1),
  tuesday('Tuesday', 2),
  wednesday('Wednesday', 3),
  thursday('Thursday', 4),
  friday('Friday', 5),
  saturday('Saturday', 6),
  sunday('Sunday', 7);

  const DayOfWeek(this.label, this.value);
  final String label;
  final int value;
}

@immutable
class DayHours {
  const DayHours({
    required this.day,
    this.isOpen = true,
    this.openTime,
    this.closeTime,
  });

  final DayOfWeek day;
  final bool isOpen; // If false, business is closed on this day
  final TimeOfDay? openTime; // Opening time (e.g., 9:00 AM)
  final TimeOfDay? closeTime; // Closing time (e.g., 5:00 PM)

  bool get isClosed => !isOpen;

  DayHours copyWith({
    DayOfWeek? day,
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return DayHours(
      day: day ?? this.day,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      day: DayOfWeek.values.firstWhere(
        (d) => d.value == json['day'],
        orElse: () => DayOfWeek.monday,
      ),
      isOpen: json['isOpen'] as bool? ?? true,
      openTime: json['openTime'] != null
          ? TimeOfDay(
              hour: json['openTime']['hour'] as int,
              minute: json['openTime']['minute'] as int,
            )
          : null,
      closeTime: json['closeTime'] != null
          ? TimeOfDay(
              hour: json['closeTime']['hour'] as int,
              minute: json['closeTime']['minute'] as int,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.value,
      'isOpen': isOpen,
      'openTime': openTime != null
          ? {'hour': openTime!.hour, 'minute': openTime!.minute}
          : null,
      'closeTime': closeTime != null
          ? {'hour': closeTime!.hour, 'minute': closeTime!.minute}
          : null,
    };
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get displayText {
    if (!isOpen) return 'Closed';
    if (openTime == null || closeTime == null) return 'Open 24 hours';
    return '${formatTime(openTime!)} - ${formatTime(closeTime!)}';
  }
}

@immutable
class BusinessHoursModel {
  BusinessHoursModel({
    this.hours = const [],
  });

  final List<DayHours> hours;

  BusinessHoursModel copyWith({
    List<DayHours>? hours,
  }) {
    return BusinessHoursModel(
      hours: hours ?? this.hours,
    );
  }

  /// Get hours for a specific day
  DayHours? getHoursForDay(DayOfWeek day) {
    try {
      return hours.firstWhere((h) => h.day == day);
    } catch (_) {
      return null;
    }
  }

  /// Check if business is currently open
  bool isCurrentlyOpen() {
    final now = DateTime.now();
    final currentDay = _getDayOfWeek(now.weekday);
    final dayHours = getHoursForDay(currentDay);

    if (dayHours == null || !dayHours.isOpen) return false;
    if (dayHours.openTime == null || dayHours.closeTime == null) return true; // 24 hours

    final currentTime = TimeOfDay.fromDateTime(now);
    final openTime = dayHours.openTime!;
    final closeTime = dayHours.closeTime!;

    // Handle cases where close time is next day (e.g., 10 PM - 2 AM)
    if (closeTime.hour < openTime.hour) {
      // Business closes next day
      return currentTime.hour >= openTime.hour ||
          currentTime.hour < closeTime.hour ||
          (currentTime.hour == closeTime.hour && currentTime.minute < closeTime.minute);
    } else {
      // Normal case: same day
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final openMinutes = openTime.hour * 60 + openTime.minute;
      final closeMinutes = closeTime.hour * 60 + closeTime.minute;
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    }
  }

  DayOfWeek _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return DayOfWeek.monday;
      case 2:
        return DayOfWeek.tuesday;
      case 3:
        return DayOfWeek.wednesday;
      case 4:
        return DayOfWeek.thursday;
      case 5:
        return DayOfWeek.friday;
      case 6:
        return DayOfWeek.saturday;
      case 7:
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }

  factory BusinessHoursModel.fromJson(Map<String, dynamic> json) {
    final hoursList = (json['hours'] as List<dynamic>?)
            ?.map((e) => DayHours.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return BusinessHoursModel(hours: hoursList);
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours.map((h) => h.toJson()).toList(),
    };
  }

  /// Create default business hours (9 AM - 5 PM, Monday-Friday)
  factory BusinessHoursModel.defaultHours() {
    return BusinessHoursModel(
      hours: [
        DayHours(
          day: DayOfWeek.monday,
          isOpen: true,
          openTime: const TimeOfDay(hour: 9, minute: 0),
          closeTime: const TimeOfDay(hour: 17, minute: 0),
        ),
        DayHours(
          day: DayOfWeek.tuesday,
          isOpen: true,
          openTime: const TimeOfDay(hour: 9, minute: 0),
          closeTime: const TimeOfDay(hour: 17, minute: 0),
        ),
        DayHours(
          day: DayOfWeek.wednesday,
          isOpen: true,
          openTime: const TimeOfDay(hour: 9, minute: 0),
          closeTime: const TimeOfDay(hour: 17, minute: 0),
        ),
        DayHours(
          day: DayOfWeek.thursday,
          isOpen: true,
          openTime: const TimeOfDay(hour: 9, minute: 0),
          closeTime: const TimeOfDay(hour: 17, minute: 0),
        ),
        DayHours(
          day: DayOfWeek.friday,
          isOpen: true,
          openTime: const TimeOfDay(hour: 9, minute: 0),
          closeTime: const TimeOfDay(hour: 17, minute: 0),
        ),
        DayHours(
          day: DayOfWeek.saturday,
          isOpen: false,
        ),
        DayHours(
          day: DayOfWeek.sunday,
          isOpen: false,
        ),
      ],
    );
  }
}

