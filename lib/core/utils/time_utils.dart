/// Formatting utilities for converting 24-hour time strings ("HH:mm")
/// and hour integers (0-23) into clean 12-hour AM/PM formats.
class TimeUtils {
  /// Converts a 24-hour time string ("14:30", "09:05", "14:00") to 12-hour format ("2:30 PM", "9:05 AM", "2:00 PM").
  /// Returns [fallback] if [timeStr] is null or empty.
  static String formatTo12Hour(String? timeStr, {String fallback = 'Anytime'}) {
    if (timeStr == null || timeStr.trim().isEmpty) return fallback;
    final trimmed = timeStr.trim();
    if (!trimmed.contains(':')) return trimmed;

    final parts = trimmed.split(':');
    final hour = int.tryParse(parts[0]);
    if (hour == null) return trimmed;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final mStr = minute.toString().padLeft(2, '0');
    return '$h12:$mStr $period';
  }

  /// Formats an integer hour (0-23) to a concise 12-hour format ("12 AM", "9 AM", "12 PM", "2 PM").
  static String formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12 $period';
  }
}
