import 'package:flutter/material.dart';

enum RestaurantStatus { open, closingSoon, closed }

class TimeUtils {
  // Parse "10:00 - 22:00"
  // Return RestaurantStatus
  // Parse dynamic openingHours (Map or String)
  // Return RestaurantStatus
  static RestaurantStatus getRestaurantStatus(dynamic openingHours) {
    if (openingHours == null) return RestaurantStatus.open;

    // Compatibility check for String (old data)
    if (openingHours is String) {
      if (openingHours.isEmpty) return RestaurantStatus.open;
      return _getStatusFromString(openingHours);
    }

    if (openingHours is Map) {
      // Format: { mon: [{open: 'HH:mm', close: 'HH:mm'}] }
      final now = DateTime.now();
      final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      // DateTime.weekday: Mon=1 ... Sun=7. List index: 0..6
      final todayKey = weekdays[now.weekday - 1];

      // Check if there is a schedule for today
      final todaySchedule = openingHours[todayKey];

      if (todaySchedule == null ||
          (todaySchedule is List && todaySchedule.isEmpty)) {
        return RestaurantStatus.closed;
      }

      if (todaySchedule is List) {
        // Iterate through slots (usually one)
        for (var slot in todaySchedule) {
          if (slot is Map) {
            final openStr = slot['open']?.toString();
            final closeStr = slot['close']?.toString();

            if (openStr != null && closeStr != null) {
              final status = _checkTimeRange(openStr, closeStr);
              if (status != RestaurantStatus.closed) {
                return status; // Return if Open or ClosingSoon found
              }
            }
          }
        }
        return RestaurantStatus.closed; // Checked all slots, none open
      }
    }

    return RestaurantStatus.open; // Fallback
  }

  static RestaurantStatus _getStatusFromString(String range) {
    // Re-use logic for simple string "HH:mm - HH:mm"
    final parts = range.split('-');
    if (parts.length != 2) return RestaurantStatus.open;
    return _checkTimeRange(parts[0].trim(), parts[1].trim());
  }

  static RestaurantStatus _checkTimeRange(String openStr, String closeStr) {
    try {
      final now = DateTime.now();

      TimeOfDay parseTime(String t) {
        final pp = t.split(':');
        return TimeOfDay(hour: int.parse(pp[0]), minute: int.parse(pp[1]));
      }

      final openTime = parseTime(openStr);
      final closeTime = parseTime(closeStr);

      final openDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        openTime.hour,
        openTime.minute,
      );

      var closeDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        closeTime.hour,
        closeTime.minute,
      );

      // Handle closing past midnight
      if (closeDateTime.isBefore(openDateTime)) {
        closeDateTime = closeDateTime.add(const Duration(days: 1));
      }

      bool isOpen = false;

      double toDouble(TimeOfDay t) => t.hour + t.minute / 60.0;
      double nowDouble = toDouble(TimeOfDay.fromDateTime(now));
      double openDouble = toDouble(openTime);
      double closeDouble = toDouble(closeTime);

      // Since we just want to check if NOW is in range:
      // We can use the DateTime comparison directly if we handle the midnight crossover correctly for "now"
      // But let's stick to the Double Logic which was working, but refined.

      // Refined Logic:
      // If Close < Open (Crosses Midnight): Open if Now >= Open OR Now < Close
      if (closeDouble < openDouble) {
        if (nowDouble >= openDouble || nowDouble < closeDouble) {
          isOpen = true;
        }
      } else {
        // Normal
        if (nowDouble >= openDouble && nowDouble < closeDouble) {
          isOpen = true;
        }
      }

      if (!isOpen) return RestaurantStatus.closed;

      // Check closing soon logic
      // We need accurate closeDateTime relative to Now for difference
      DateTime accurateClose;
      if (closeDouble < openDouble) {
        if (nowDouble >= openDouble) {
          // Before midnight, close is tomorrow
          accurateClose = DateTime(
            now.year,
            now.month,
            now.day + 1,
            closeTime.hour,
            closeTime.minute,
          );
        } else {
          // After midnight, close is today
          accurateClose = DateTime(
            now.year,
            now.month,
            now.day,
            closeTime.hour,
            closeTime.minute,
          );
        }
      } else {
        accurateClose = DateTime(
          now.year,
          now.month,
          now.day,
          closeTime.hour,
          closeTime.minute,
        );
      }

      final diff = accurateClose.difference(now);
      if (diff.inMinutes <= 30 && diff.inMinutes > 0) {
        return RestaurantStatus.closingSoon;
      }

      return RestaurantStatus.open;
    } catch (e) {
      debugPrint("Error parsing time range: $e");
      return RestaurantStatus.open;
    }
  }
}
