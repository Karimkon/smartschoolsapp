/// Safe numeric parsing for API values.
///
/// MySQL DECIMAL columns (fees, scores, amounts, percentages) arrive in JSON
/// as strings ("100.00"), so `as num` casts throw TypeError at runtime —
/// in release builds that renders as a grey ErrorWidget (blank screen).
/// Always use these helpers instead of casting API values with `as num`.
library;

double toD(dynamic v, [double def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? def;
}

double? toDN(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int toI(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? def;
}
