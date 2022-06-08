import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import 'collections/category.dart';
import 'collections/memo.dart';

/// メモリポジトリ
///
/// メモに関する操作はこのクラスを経由して行う
class MemoRepository {
  MemoRepository(this.isar) {
    Future(() async {
      // （デバッグ用）データを全削除する
      await isar.writeTxn((isar) async {
        final categories = await isar.categorys.where().findAll();
        await isar.categorys.deleteAll(categories.map((e) => e.id).toList());
        final memos = await isar.memos.where().findAll();
        await isar.memos.deleteAll(memos.map((e) => e.id).toList());
      });

      // 初回起動時に初期データをDBに書き込む
      if (await isar.categorys.count() == 0) {
        await isar.writeTxn((isar) async {
          // カテゴリの初期データ
          await isar.categorys.putAll(
            ['仕事', 'プライベート', 'その他']
                .map((name) => Category()..name = name)
                .toList(),
          );
        });
        await isar.writeTxn((isar) async {
          final categories = await isar.categorys.where().findAll();

          // メモの初期データはJSONから取ってくる
          final bytes = await rootBundle.load('assets/json/seed_memos.json');
          final jsonString =
              const Utf8Decoder().convert(bytes.buffer.asUint8List());
          final jsonArray = json.decode(jsonString) as List;

          final now = DateTime.now();
          final memos = <Memo>[];
          for (final jsonMap in jsonArray) {
            if (jsonMap is Map<String, dynamic>) {
              memos.add(
                Memo()
                  ..category.value = categories.firstWhere(
                    (category) => category.id == jsonMap['categoryId'] as int,
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
    });

    // メモ一覧の変化を監視してストリームに流す
    isar.memos.watchLazy().listen((_) async {
      _memoStreamController.sink.add(await findMemos());
    });
  }

  /// Isarインスタンス
  final Isar isar;

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

    // IsarLinkでリンクされているカテゴリを読み込む必要がある
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

      // IsarLinkでリンクされているカテゴリを保存する必要がある
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

      // IsarLinkでリンクされているカテゴリを保存する必要がある
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
