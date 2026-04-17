T enumByName<T extends Enum>(Iterable<T> values, String name) {
  return values.firstWhere((value) => value.name == name);
}
