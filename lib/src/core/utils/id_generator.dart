String buildId(String prefix) {
  final micros = DateTime.now().microsecondsSinceEpoch;
  return '${prefix}_$micros';
}
