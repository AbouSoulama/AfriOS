/// The API serialises monetary `Decimal` fields as JSON strings while counters
/// come back as numbers, so every numeric field has to be read tolerantly.
double asDouble(Object? value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  if (value is String)
    return double.tryParse(value.trim())?.round() ?? fallback;
  return fallback;
}

/// Nullable variant for optional fields where "absent" and "zero" differ.
double? asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
