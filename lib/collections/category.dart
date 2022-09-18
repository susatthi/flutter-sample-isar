import 'package:isar/isar.dart';

part 'category.g.dart';

@Collection()
class Category {
  /// 自動インクリメントする ID
  Id id = Isar.autoIncrement;

  /// カテゴリ名
  late String name;
}
