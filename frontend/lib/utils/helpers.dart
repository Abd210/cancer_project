/// Safely parses a timestamp from various formats (string, map, null)
/// Returns null if parsing fails
DateTime? parseFirestoreTimestamp(dynamic timestamp) {
  if (timestamp == null) {
    return null;
  }
  
  // Case 1: It's a string in ISO format
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  
  // Case 2: It's a map with seconds and nanoseconds (Firestore timestamp format)
  if (timestamp is Map<String, dynamic>) {
    if (timestamp.containsKey('seconds')) {
      try {
        final seconds = timestamp['seconds'] as int;
        final nanoseconds = (timestamp['nanoseconds'] as int?) ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      } catch (e) {
        return null;
      }
    }
  }
  
  // Case 3: It's already a DateTime
  if (timestamp is DateTime) {
    return timestamp;
  }
  
  // Failed to parse
  return null;
}

/// Format a nullable DateTime to a readable string
String formatDateTime(DateTime? dateTime, {String defaultValue = 'Not specified'}) {
  if (dateTime == null) {
    return defaultValue;
  }
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
} 