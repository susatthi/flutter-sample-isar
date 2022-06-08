import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'collections/category.dart';
import 'collections/memo.dart';
import 'memo_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// メモリポジトリの初期化
  final dir = await getApplicationSupportDirectory();
  final isar = await Isar.open(
    schemas: [
      CategorySchema,
      MemoSchema,
    ],
    directory: dir.path,
    inspector: true,
  );
  final memoRepository = MemoRepository(isar);

  runApp(
    App(memoRepository: memoRepository),
  );
}
