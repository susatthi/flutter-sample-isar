import 'dart:async';

import 'package:isar/isar.dart';

import 'collections/category.dart';
import 'collections/memo.dart';

/// メモリポジトリ
///
/// メモに関する操作をになう
class MemoRepository {
  MemoRepository(this.isar) {
    Future(() async {
      // 初回起動時にカテゴリの初期値を追加
      if (await isar.categorys.count() == 0) {
        await isar.writeTxn((isar) async {
          for (final seed in ['仕事', 'プライベート', 'その他']) {
            await isar.categorys.put(Category()..name = seed);
          }
        });
      }
    });

    // メモ一覧の変化を監視してストリームに流す
    isar.memos.watchLazy().listen((_) async {
      _memoStreamController.sink.add(await findMemos());
    });
  }

  /// Isarインスタンス
  Isar isar;

  /// メモ一覧を監視したい場合はmemoStreamをlistenしてもらう
  final _memoStreamController = StreamController<List<Memo>>();
  Stream<List<Memo>> get memoStream => _memoStreamController.stream;

  /// 終了処理
  void dispose() {
    _memoStreamController.close();
  }

  /// カテゴリを検索する
  Future<List<Category>> findCategories() async {
    // デフォルトのソートはidの昇順
    return isar.categorys.where().findAll();
  }

  /// メモを検索する
  Future<List<Memo>> findMemos() async {
    // 更新日時の降順で全件返す
    final memos = await isar.memos.where().sortByUpdatedAtDesc().findAll();
    for (final memo in memos) {
      await memo.category.load();
    }
    return memos;
  }

  /// メモを追加する
  Future<void> addMemo({
    required Category category,
    required String content,
  }) {
    final now = DateTime.now();
    final memo = Memo()
      ..category.value = category
      ..content = content
      ..createdAt = now
      ..updatedAt = now;
    return isar.writeTxn((isar) async {
      await isar.memos.put(memo);
      await memo.category.save();
    });
  }

  /// メモを更新する
  Future<void> updateMemo({
    required Memo memo,
    required Category category,
    required String content,
  }) {
    final now = DateTime.now();
    memo
      ..category.value = category
      ..content = content
      ..updatedAt = now;
    return isar.writeTxn((isar) async {
      await isar.memos.put(memo);
      await memo.category.save();
    });
  }

  /// メモを削除する
  Future<bool> deleteMemo(Memo memo) async {
    return isar.writeTxn((isar) async {
      return isar.memos.delete(memo.id);
    });
  }
}
