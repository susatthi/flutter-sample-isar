import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'collections/category.dart';
import 'collections/memo.dart';
import 'memo_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // メモリポジトリの初期化
  // path_provider は Web に非対応
  var path = '';
  if (!foundation.kIsWeb) {
    final dir = await getApplicationSupportDirectory();
    path = dir.path;
  }

  final isar = await Isar.open(
    schemas: [
      CategorySchema,
      MemoSchema,
    ],
    directory: path,
    inspector: true,
  );

  // 初期データ書き込み
  // forceプロパティをtrueにすると既存データを全削除して初期データを書き込み直す
  await _writeSeedIfNeed(
    isar,
    force: true,
  );

  // syncプロパティをtrueにするとDB操作を同期的に処理する
  runApp(
    App(
      memoRepository: MemoRepository(
        isar,
        // sync: true,
      ),
    ),
  );
}

/// 必要なら初期データを書き込む
Future<void> _writeSeedIfNeed(
  Isar isar, {
  bool force = false,
}) async {
  if (force) {
    // 強制的にデータを全削除する
    await isar.writeTxn((isar) async {
      await isar.clear();
    });
  }

  // データがあれば何もしない
  if (await isar.categorys.count() > 0) {
    return;
  }

  // 初期データを書き込む
  await isar.writeTxn((isar) async {
    // カテゴリの初期データ
    await isar.categorys.putAll(
      ['仕事', 'プライベート', 'その他'].map((name) => Category()..name = name).toList(),
    );
    final categories = await isar.categorys.where().findAll();

    // メモの初期データはJSONから取ってくる
    final bytes = await rootBundle.load('assets/json/seed_memos.json');
    final jsonString = const Utf8Decoder().convert(bytes.buffer.asUint8List());
    final jsonArray = json.decode(jsonString) as List;

    final memos = <Memo>[];
    for (final jsonMap in jsonArray) {
      if (jsonMap is Map<String, dynamic>) {
        final now = DateTime.now();
        memos.add(
          Memo()
            ..category.value = categories.firstWhere(
              (category) => category.name == jsonMap['categoryName'] as String,
            )
            ..content = jsonMap['content'] as String
            ..createdAt = now
            ..updatedAt = now,
        );
      }
    }

    await isar.memos.putAll(memos);
    final saveCategories = memos.map((memo) => memo.category).toList();
    for (final saveCategory in saveCategories) {
      await saveCategory.save();
    }
  });
}
