import 'dart:async';

import 'package:isar/isar.dart';

import 'collections/category.dart';
import 'collections/memo.dart';

/// メモリポジトリ
///
/// メモに関する操作はこのクラスを経由して行う
class MemoRepository {
  MemoRepository(
    this.isar, {
    this.sync = false,
  }) {
    // メモ一覧の変化を監視してストリームに流す
    isar.memos.watchLazy().listen((_) async {
      if (!isar.isOpen) {
        return;
      }
      if (_memoStreamController.isClosed) {
        return;
      }
      _memoStreamController.sink.add(await findMemos());
    });
  }

  /// Isarインスタンス
  final Isar isar;

  /// 非同期かどうか
  final bool sync;

  /// メモ一覧を監視したい場合はmemoStreamをlistenしてもらう
  final _memoStreamController = StreamController<List<Memo>>.broadcast();
  Stream<List<Memo>> get memoStream => _memoStreamController.stream;

  /// 終了処理
  void dispose() {
    _memoStreamController.close();
  }

  /// カテゴリを検索する
  FutureOr<List<Category>> findCategories() async {
    if (!isar.isOpen) {
      return [];
    }

    // デフォルトのソートはidの昇順
    final builder = isar.categorys.where();
    return sync ? builder.findAllSync() : await builder.findAll();
  }

  /// メモを検索する
  FutureOr<List<Memo>> findMemos() async {
    if (!isar.isOpen) {
      return [];
    }

    // 更新日時の降順で全件返す
    final builder = isar.memos.where().sortByUpdatedAtDesc();

    if (sync) {
      final memos = builder.findAllSync();
      // IsarLinkでリンクされているカテゴリを読み込む必要がある
      for (final memo in memos) {
        memo.category.loadSync();
      }
      return memos;
    }

    final memos = await builder.findAll();

    // IsarLinkでリンクされているカテゴリを読み込む必要がある
    for (final memo in memos) {
      await memo.category.load();
    }
    return memos;
  }

  /// メモを追加する
  FutureOr<void> addMemo({
    required Category category,
    required String content,
  }) {
    if (!isar.isOpen) {
      return Future<void>(() {});
    }

    final now = DateTime.now();
    final memo = Memo()
      ..category.value = category
      ..content = content
      ..createdAt = now
      ..updatedAt = now;
    if (sync) {
      isar.writeTxnSync<void>(() {
        isar.memos.putSync(memo);

        // IsarLinkでリンクされているカテゴリを保存する必要がある
        memo.category.saveSync();
      });
    } else {
      return isar.writeTxn(() async {
        await isar.memos.put(memo);

        // IsarLinkでリンクされているカテゴリを保存する必要がある
        await memo.category.save();
      });
    }
  }

  /// メモを更新する
  FutureOr<void> updateMemo({
    required Memo memo,
    required Category category,
    required String content,
  }) {
    if (!isar.isOpen) {
      return Future<void>(() {});
    }

    final now = DateTime.now();
    memo
      ..category.value = category
      ..content = content
      ..updatedAt = now;
    if (sync) {
      isar.writeTxnSync<void>(() {
        isar.memos.putSync(memo);

        // IsarLinkでリンクされているカテゴリを保存する必要がある
        memo.category.saveSync();
      });
    } else {
      return isar.writeTxn(() async {
        await isar.memos.put(memo);

        // IsarLinkでリンクされているカテゴリを保存する必要がある
        await memo.category.save();
      });
    }
  }

  /// メモを削除する
  FutureOr<bool> deleteMemo(Memo memo) async {
    if (!isar.isOpen) {
      return false;
    }

    if (sync) {
      return isar.writeTxnSync(() {
        return isar.memos.deleteSync(memo.id);
      });
    }
    return isar.writeTxn(() async {
      return isar.memos.delete(memo.id);
    });
  }
}
