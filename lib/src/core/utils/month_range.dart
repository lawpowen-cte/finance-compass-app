import 'month_key.dart';

List<String> recentMonthKeys({required int count, DateTime? anchor}) {
  final base = DateTime((anchor ?? DateTime.now()).year, (anchor ?? DateTime.now()).month);
  return List.generate(count, (index) {
    final date = DateTime(base.year, base.month - (count - index - 1));
    return monthKeyFromDate(date);
  });
}

String monthLabel(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length != 2) {
    return monthKey;
  }
  return '${parts[1]}/${parts[0].substring(2)}';
}
