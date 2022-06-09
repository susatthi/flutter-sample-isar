import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils/test_agent.dart';

void main() {
  final agent = TestAgent();
  late MemoRepository repository;

  setUp(() async {
    await agent.setUp();
    repository = agent.memoRepository;
  });

  tearDown(() async {
    repository.dispose();
    await agent.tearDown();
  });

  group('MemoRepository', () {
    test('カテゴリを検索できるはず', () async {
      final categories = await repository.findCategories();

      // カテゴリ数は3のはず
      expect(categories.length, 3);

      // カテゴリ名とIDが意図したとおりであるはず
      expect(categories[0].id, 1);
      expect(categories[0].name, '仕事');
      expect(categories[1].id, 2);
      expect(categories[1].name, 'プライベート');
      expect(categories[2].id, 3);
      expect(categories[2].name, 'その他');
    });
    test('メモを追加できるはず', () async {
      final categories = await repository.findCategories();
      final expectedCategory = categories.first;
      const expectedContent = 'memo content';
      await repository.addMemo(
        category: expectedCategory,
        content: expectedContent,
      );

      // メモを検索する
      final memos = await repository.findMemos();

      // 1件取得できるはず
      expect(memos.length, 1);

      // メモの値が期待したとおりの値のはず
      final memo = memos.first;
      expect(memo.category.value?.id, expectedCategory.id);
      expect(memo.content, expectedContent);
      expect(memo.createdAt, isNotNull);
      expect(memo.updatedAt, isNotNull);
      expect(memo.createdAt, memo.updatedAt);
    });
    test('メモを更新できるはず', () async {
      final categories = await repository.findCategories();
      await repository.addMemo(
        category: categories.first,
        content: 'memo content',
      );

      // メモを取得する
      final memos = await repository.findMemos();
      final memo = memos.first;

      // メモを更新する
      final expectedCategory = categories.last;
      const expectedContent = 'changed';
      await repository.updateMemo(
        memo: memo,
        category: expectedCategory,
        content: expectedContent,
      );

      // メモを取得する
      final updatedMemos = await repository.findMemos();
      final updatedMemo = updatedMemos.first;

      // メモの値が期待したとおりの値のはず
      expect(updatedMemo.category.value?.id, expectedCategory.id);
      expect(updatedMemo.content, expectedContent);
      expect(updatedMemo.createdAt, isNotNull);
      expect(updatedMemo.updatedAt, isNotNull);
      expect(updatedMemo.createdAt != updatedMemo.updatedAt, true);
    });
    test('メモを削除できるはず', () async {
      final categories = await repository.findCategories();
      await repository.addMemo(
        category: categories.first,
        content: 'memo content',
      );

      // メモを取得する
      final memos = await repository.findMemos();

      // 1件取得できるはず
      expect(memos.length, 1);

      // メモを削除する
      final result = await repository.deleteMemo(memos.first);

      // 削除に成功するはず
      expect(result, true);

      // メモを取得する
      final deletedMemos = await repository.findMemos();

      // 0件のはず
      expect(deletedMemos.length, 0);
    });
    test('メモを監視できるはず', () async {
      List<Memo>? receivedMemos;
      repository.memoStream.listen((memos) {
        receivedMemos = memos;
      });

      final categories = await repository.findCategories();

      // まだnullのはず
      expect(receivedMemos, isNull);

      // 1件追加する
      await repository.addMemo(
        category: categories.first,
        content: 'memo content',
      );

      // ストリームを受信するまで遅延させる
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 1件受信しているはず
      expect(receivedMemos, isNotNull);
      expect(receivedMemos!.length, 1);

      // 更新する
      final expectedCategory = categories.last;
      const expectedContent = 'changed';
      await repository.updateMemo(
        memo: receivedMemos!.first,
        category: expectedCategory,
        content: expectedContent,
      );

      // ストリームを受信するまで遅延させる
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 1件受信しているはず
      expect(receivedMemos, isNotNull);
      expect(receivedMemos!.length, 1);

      final receivedMemo = receivedMemos!.first;
      expect(receivedMemo.category.value!.id, expectedCategory.id);
      expect(receivedMemo.content, expectedContent);

      // 削除する
      await repository.deleteMemo(receivedMemo);

      // ストリームを受信するまで遅延させる
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 0件受信しているはず
      expect(receivedMemos, isNotNull);
      expect(receivedMemos!.length, 0);
    });
    test('メモを複数から監視できるはず', () async {
      List<Memo>? receivedMemos1;
      repository.memoStream.listen((memos) {
        receivedMemos1 = memos;
      });

      List<Memo>? receivedMemos2;
      repository.memoStream.listen((memos) {
        receivedMemos2 = memos;
      });

      final categories = await repository.findCategories();

      // まだnullのはず
      expect(receivedMemos1, isNull);
      expect(receivedMemos2, isNull);

      // 1件追加する
      await repository.addMemo(
        category: categories.first,
        content: 'memo content',
      );

      // ストリームを受信するまで遅延させる
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 1件受信しているはず
      expect(receivedMemos1, isNotNull);
      expect(receivedMemos1!.length, 1);
      expect(receivedMemos2, isNotNull);
      expect(receivedMemos2!.length, 1);
    });
  });
}
