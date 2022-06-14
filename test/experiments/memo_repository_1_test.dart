// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math';

import 'package:flutter_sample_isar/collections/category.dart';
import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late MemoRepository repository;

  setUp(() async {
    final evacuation = HttpOverrides.current;
    HttpOverrides.global = null;

    await Isar.initializeIsarCore(
      download: true,
    );

    HttpOverrides.global = evacuation;

    PathProviderPlatform.instance = MockPathProviderPlatform();
    final dir = await getApplicationSupportDirectory();
    isar = await Isar.open(
      schemas: [
        CategorySchema,
        MemoSchema,
      ],
      directory: dir.path,
    );
    repository = MemoRepository(isar);

    await isar.writeTxn((isar) async {
      await isar.clear();
      await isar.categorys.putAll(
        ['仕事', 'プライベート', 'その他'].map((name) => Category()..name = name).toList(),
      );
    });
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

/// モック版のPathProviderPlatform
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String> getApplicationSupportPath() async {
    // 9桁のランダムな数字を生成する（例：355017887）
    final name = Random().nextInt(pow(2, 32) as int);
    return Directory(
      path.join(
        Directory.current.path,
        '.dart_tool',
        'test',
        'application_support_$name',
      ),
    ).path;
  }
}
