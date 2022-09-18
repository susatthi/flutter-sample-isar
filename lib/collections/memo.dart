import 'package:isar/isar.dart';

import 'category.dart';

part 'memo.g.dart';

@Collection()
class Memo {
  /// 自動インクリメントする ID
  Id id = Isar.autoIncrement;

  /// カテゴリ
  final category = IsarLink<Category>();

  /// メモの内容
  late String content;

  /// 作成日時
  late DateTime createdAt;

  /// 更新日時
  @Index()
  late DateTime updatedAt;
}
