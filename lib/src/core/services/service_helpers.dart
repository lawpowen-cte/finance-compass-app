// 服务层共享辅助函数。
//
// 从 FinanceRepository 提取的通用工具方法，
// 供多个 Service 类复用。

/// 将 [date] 转换为 `"YYYY-MM"` 格式的月份键。
String serviceMonthKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

/// 比较两个月份键的先后顺序。
///
/// 返回值:
///   * `< 0` — [left] 在 [right] 之前
///   * `0`   — 相同月份
///   * `> 0` — [left] 在 [right] 之后
int compareMonthKeys(String left, String right) {
  final leftParts = left.split('-');
  final rightParts = right.split('-');
  if (leftParts.length != 2 || rightParts.length != 2) {
    return left.compareTo(right);
  }
  final leftYear = int.tryParse(leftParts[0]) ?? 0;
  final leftMonth = int.tryParse(leftParts[1]) ?? 0;
  final rightYear = int.tryParse(rightParts[0]) ?? 0;
  final rightMonth = int.tryParse(rightParts[1]) ?? 0;
  return DateTime(leftYear, leftMonth)
      .compareTo(DateTime(rightYear, rightMonth));
}

/// 生成从 [startMonthKey] 到 [endMonthKey]（含两端）的月份键列表。
List<String> monthKeyRange(String startMonthKey, String endMonthKey) {
  final startParts = startMonthKey.split('-');
  final endParts = endMonthKey.split('-');
  if (startParts.length != 2 || endParts.length != 2) {
    return [endMonthKey];
  }
  final start = DateTime(int.parse(startParts[0]), int.parse(startParts[1]));
  final end = DateTime(int.parse(endParts[0]), int.parse(endParts[1]));
  final result = <String>[];
  var current = start;
  while (!current.isAfter(end)) {
    result.add(serviceMonthKey(current));
    current = DateTime(current.year, current.month + 1);
  }
  return result;
}
