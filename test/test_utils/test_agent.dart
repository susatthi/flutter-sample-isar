import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter_sample_isar/collections/category.dart';
import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
// ignore: unused_import
import 'package:isar/src/version.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

/// テストエージェント
class TestAgent {
  final isarTestAgent = IsarTestAgent();
  late MemoRepository memoRepository;

  /// 開始処理
  Future<void> setUp() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Isarテストエージェントのセットアップ
    await isarTestAgent.setUp();

    // メモリポジトリの生成
    memoRepository = MemoRepository(isarTestAgent.isar);
  }

  /// 終了処理
  Future<void> tearDown() async {
    memoRepository.dispose();
    await isarTestAgent.tearDown();
  }
}

/// Isar のテストエージェント
class IsarTestAgent {
  final testDir = TestDirectory();
  Isar? _isar;
  Isar get isar => _isar!;

  /// セットアップする
  Future<void> setUp() async {
    await testDir.open(prefix: 'isar');

    // https://github.com/isar/isar#unit-tests によるとテスト時にはIsarのライブラリを
    // ダウンロードする必要があるため、./dart_tool/ 配下にIsarコアバージョン毎にダウンロード
    // 用のディレクトリを用意する。
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

    // テスト時はインターネットが遮断されてしまうので一時的にインターネットに出られるようにする
    final evacuation = HttpOverrides.current;
    HttpOverrides.global = null;

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

    // Isarインスタンスを作成する
    _isar = await Isar.open(
      schemas: [
        CategorySchema,
        MemoSchema,
      ],
      directory: testDir.dir.path,
    );

    // カテゴリの初期データ書き込み
    await isar.writeTxn((isar) async {
      await isar.categorys.putAll(
        ['仕事', 'プライベート', 'その他'].map((name) => Category()..name = name).toList(),
      );
    });
  }

  /// 終了する
  Future<void> tearDown() async {
    await _isar?.close(deleteFromDisk: true);
    _isar = null;
    testDir.close();
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

class TestDirectory {
  /// テストルートディレクトリ
  static final rootDir = Directory(
    path.join(
      Directory.current.path,
      '.dart_tool',
      'test',
    ),
  );

  /// テストディレクトリ
  Directory? _dir;
  Directory get dir => _dir!;

  /// テストディレクトリを開く
  Future<void> open({
    String? prefix,
  }) async {
    if (_dir != null) {
      return;
    }

    final name = Random().nextInt(pow(2, 32) as int);
    final effectivePrefix = prefix ?? 'tmp';
    final dir = Directory(path.join(rootDir.path, '${effectivePrefix}_$name'));

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    _dir = dir;
  }

  /// テストディレクトリを閉じる
  void close() {
    final dir = _dir;
    if (dir == null) {
      return;
    }

    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      _dir = null;
    }
  }
}
