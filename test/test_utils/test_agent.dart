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

/// テストエージェント
class TestAgent {
  final _isarTestAgent = IsarTestAgent();
  MemoRepository? _memoRepository;

  /// 開始処理
  Future<void> setUp() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Isarテストエージェントの開始処理
    await _isarTestAgent.setUp();
    await _isarTestAgent.setUpDB();
  }

  /// 終了処理
  Future<void> tearDown() async {
    _memoRepository?.dispose();
    _memoRepository = null;
    await _isarTestAgent.tearDown();
  }

  /// メモリポジトリを返す
  MemoRepository getMemoRepository({
    bool sync = false,
  }) {
    return _memoRepository ??= MemoRepository(
      _isarTestAgent.isar,
      sync: sync,
    );
  }
}

/// Isar のテストエージェント
class IsarTestAgent {
  Isar? _isar;
  Isar get isar => _isar!;

  /// 開始処理
  Future<void> setUp() async {
    // テスト時はインターネットが遮断されてしまうので一時的にインターネットに出られるようにする
    final evacuation = HttpOverrides.current;
    HttpOverrides.global = null;

    // https://github.com/isar/isar#unit-tests によるとテスト時にはIsarのライブラリを
    // ダウンロードする必要があるため、./dart_tool/ 配下にIsarコアバージョン毎にダウンロード
    // 用のディレクトリを用意する。テスト毎にライブラリをダウンロードするのは時間がかかるので削除しない。
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

    // すでにダウンロード済みの場合はダウンロードをスキップするのでライブラリファイルの
    // 存在チェックは不要
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

    // Isarインスタンスを作成する
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open(
      schemas: [
        CategorySchema,
        MemoSchema,
      ],
      directory: dir.path,
    );
  }

  /// 終了処理
  Future<void> tearDown() async {
    if (_isar?.isOpen == true) {
      await _isar?.close(deleteFromDisk: true);
    }
    _isar = null;
    final dir = await getApplicationSupportDirectory();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// DBをセットアップする
  Future<void> setUpDB() async {
    // カテゴリの初期値を書き込む
    return isar.writeTxn((isar) async {
      await isar.categorys.putAll(
        ['仕事', 'プライベート', 'その他'].map((name) => Category()..name = name).toList(),
      );
    });
  }
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
