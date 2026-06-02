import '../database/app_database.dart'
    hide Category;
import '../models/category.dart';

/// 分类 CRUD 与查询服务。
///
/// 提供按类型筛选、排序查询以及分类的增删改操作。
class CategoryService {
  CategoryService({
    required List<Category> categories,
    required this.database,
  }) : _categories = categories;

  final List<Category> _categories;
  final AppDatabase database;

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 按 [CategoryType] 筛选分类。
  List<Category> categoriesByType(CategoryType type) {
    return _categories.where((item) => item.type == type).toList();
  }

  /// 所有分类（按类型名、分类名排序）。
  List<Category> sortedCategories() {
    final items = [..._categories]..sort((a, b) {
        final byType = a.type.name.compareTo(b.type.name);
        if (byType != 0) {
          return byType;
        }
        return a.name.compareTo(b.name);
      });
    return items;
  }

  /// 根据 [categoryId] 获取分类名称。
  ///
  /// 若找不到对应分类，返回 `'未命名类别'`。
  String categoryName(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return '未命名类别';
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> addCategory(Category category) async {
    await database.insertCategory(category);
  }

  Future<void> updateCategory(Category category) async {
    await database.updateCategory(category);
  }

  Future<bool> canDeleteCategory(String categoryId) {
    return database
        .categoryHasLinkedData(categoryId)
        .then((hasLinks) => !hasLinks);
  }

  /// 若分类无关联数据则删除，返回 `true` 表示已删除。
  Future<bool> deleteCategoryIfSafe(String categoryId) async {
    return database.deleteCategoryIfSafe(categoryId);
  }
}
