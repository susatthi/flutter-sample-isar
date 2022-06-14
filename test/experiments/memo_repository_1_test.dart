// ignore_for_file: depend_on_referenced_packages

import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter_sample_isar/collections/category.dart';
import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/version.dart';
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

    final isarLibraryDir = Directory(
      path.join(
        Directory.current.path,
        '.dart_tool',
        'test',
        'isar_core_library',
        isarCoreVersion,
      ),
    );
    if (!isarLibraryDir.existsSync()) {
      await isarLibraryDir.create(recursive: true);
    }

    await Isar.initializeIsarCore(
      libraries: <Abi, String>{
        Abi.current(): path.join(
          isarLibraryDir.path,
          Abi.current().localName,
        ),
      },
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

    // カテゴリの初期値を書き込む
    await isar.writeTxn((isar) async {
      await isar.clear();
      await isar.categorys.putAll(
        ['仕事', 'プライベート', 'その他'].map((name) => Category()..name = name).toList(),
      );
    });
    repository = MemoRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    repository.dispose();
    final dir = await getApplicationSupportDirectory();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  group('MemoRepository', () {
    test('カテゴリを検索できるはず', () async {
      final categories = await repository.findCategories();
      expect(categories.length, 3);
    });
  });
}

/// Copy from 'package:isar/src/native/isar_core.dart';
extension on Abi {
  String get localName {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidIA32:
      case Abi.androidX64:
        return 'libisar.so';
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar.dylib';
      case Abi.linuxX64:
        return 'libisar.so';
      case Abi.windowsArm64:
      case Abi.windowsX64:
        return 'isar.dll';
      default:
        // ignore: only_throw_errors
        throw 'Unsupported processor architecture "${Abi.current()}".'
            'Please open an issue on GitHub to request it.';
    }
  }
}

/// モック版のPathProviderPlatform
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  // 9桁のランダムな数字を生成する（例：355017887）
  final name = Random().nextInt(pow(2, 32) as int);

  @override
  Future<String> getApplicationSupportPath() async {
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
