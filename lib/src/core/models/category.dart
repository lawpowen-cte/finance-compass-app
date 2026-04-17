enum CategoryType {
  income,
  expense,
  investment,
  transfer,
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  final String id;
  final String name;
  final CategoryType type;
  final String? parentId;
}
