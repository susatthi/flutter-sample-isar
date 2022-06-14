import 'dart:io';
import 'dart:math';

import 'package:flutter_sample_isar/collections/category.dart';
import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoRepository repository;

  setUp(() async {
    final name = Random().nextInt(pow(2, 32) as int);
    final dir = Directory(
      path.join(
        Directory.current.path,
        '.dart_tool',
        'test',
        'isar_$name',
      ),
    );
    await dir.create(recursive: true);
    // final dir = await getApplicationSupportDirectory();
    isar = await Isar.open(
      schemas: [
        CategorySchema,
        MemoSchema,
      ],
      directory: dir.path,
    );
    repository = MemoRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    repository.dispose();
  });

  group('MemoRepository', () {
    test('カテゴリを検索できるはず', () async {
      final categories = await repository.findCategories();
      expect(categories.length, 3);
    });
  });
}
