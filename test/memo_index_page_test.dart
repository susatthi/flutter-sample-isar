import 'package:flutter/material.dart';
import 'package:flutter_sample_isar/collections/category.dart';
import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_index_page.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils/test_agent.dart';

void main() {
  final agent = TestAgent();
  late MemoRepository repository;
  late Widget mockApp;

  setUp(() async {
    await agent.setUp();
    repository = MemoRepository(agent.isarTestAgent.isar);
    mockApp = MaterialApp(
      home: MemoIndexPage(
        memoRepository: repository,
      ),
    );
  });

  tearDown(() async {
    repository.dispose();
    await agent.tearDown();
  });

  group('MemoIndexPage', () {
    testWidgets('初期表示時はメモは0件のはず', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(mockApp);
      });

      // ListView がいるはず
      expect(find.byType(ListView), findsOneWidget);

      // メモは0件のはず
      final state =
          tester.state(find.byType(MemoIndexPage)) as MemoIndexPageState;
      expect(state.memos.length, 0);
    });
    testWidgets('メモを追加すると一覧に表示され、削除できるはず', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(mockApp);

        // メモを1件追加する
        const expectedCategoryName = 'プライベート';
        const expectedContent = 'memo content';
        await _addMemo(
          tester,
          categoryName: expectedCategoryName,
          content: expectedContent,
        );

        // メモが1件になっているはず
        final state =
            tester.state(find.byType(MemoIndexPage)) as MemoIndexPageState;

        expect(state.memos.length, 1);

        // メモの値が期待したとおりの値のはず
        final memo = state.memos.first;
        expect(memo.category.value!.name, expectedCategoryName);
        expect(memo.content, expectedContent);

        // 削除ボタンを押下
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // ストリームを受信するまで遅延させる
        await state.widget.memoRepository.memoStream.firstWhere(
          (memos) => memos.isEmpty,
        );

        // メモが0件になっているはず
        expect(state.memos.length, 0);
      });
    });
    testWidgets('メモを更新すると一番先頭に移動するはず', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(mockApp);

        final state =
            tester.state(find.byType(MemoIndexPage)) as MemoIndexPageState;

        // メモを3件登録する
        final categories = await repository.findCategories();
        for (var i = 0; i < 3; i++) {
          await _addMemo(
            tester,
            categoryName: categories.first.name,
            content: '$i',
          );
        }

        // メモが3件になっているはず
        expect(state.memos.length, 3);

        // 更新日時の降順で並んでいるはず
        expect(state.memos[0].content, '2');
        expect(state.memos[1].content, '1');
        expect(state.memos[2].content, '0');
        expect(
          state.memos[0].updatedAt.compareTo(state.memos[1].updatedAt) > 0,
          true,
        );
        expect(
          state.memos[1].updatedAt.compareTo(state.memos[2].updatedAt) > 0,
          true,
        );

        // 一番最初に登録したメモを更新する
        await _updateMemo(
          tester,
          memo: state.memos[2],
          categoryName: categories[1].name,
          content: 'changed',
        );

        // 更新日時の降順で並んでいるはず
        expect(state.memos[0].content, 'changed');
        expect(state.memos[1].content, '2');
        expect(state.memos[2].content, '1');
        expect(
          state.memos[0].updatedAt.compareTo(state.memos[1].updatedAt) > 0,
          true,
        );
        expect(
          state.memos[1].updatedAt.compareTo(state.memos[2].updatedAt) > 0,
          true,
        );
      });
    });

    testWidgets('メモ追加ダイアログを表示してキャンセルできるはず', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(mockApp);

        // メモ追加ダイアログを開く
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();

        // メモ追加ダイアログが開いているはず
        expect(find.byType(MemoUpsertDialog), findsOneWidget);

        final dialogState = tester.state(find.byType(MemoUpsertDialog))
            as MemoUpsertDialogState;

        // カテゴリが読み込まれるまで待つ
        await Future.doWhile(() async {
          await Future<void>.delayed(Duration.zero);
          return dialogState.categories.isEmpty;
        });
        await tester.pumpAndSettle();

        // キャンセルボタン押下
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();

        // メモ追加ダイアログが閉じているはず
        expect(find.byType(MemoUpsertDialog), findsNothing);
      });
    });
  });
}

/// メモを1件登録する
Future<void> _addMemo(
  WidgetTester tester, {
  required String categoryName,
  required String content,
}) async {
  // メモ追加ダイアログを開く
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  // メモ追加ダイアログが開いているはず
  expect(find.byType(MemoUpsertDialog), findsOneWidget);

  final dialogState =
      tester.state(find.byType(MemoUpsertDialog)) as MemoUpsertDialogState;

  // カテゴリが読み込まれるまで待つ
  await Future.doWhile(() async {
    await Future<void>.delayed(Duration.zero);
    return dialogState.categories.isEmpty;
  });
  await tester.pumpAndSettle();

  // カテゴリを変更する
  await tester.tap(find.byType(DropdownButton<Category>));
  await tester.pumpAndSettle();

  // DropDownButtonは実体と表示の2つが存在するので、lastをつける必要がある
  await tester.tap(find.text(categoryName).last);
  await tester.pumpAndSettle();

  expect(dialogState.selectedCategory?.name, categoryName);

  // コンテンツを入力する
  await tester.enterText(find.byType(TextField), content);
  await tester.pumpAndSettle();

  // 保存ボタン押下
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();

  // ストリームを受信するまで遅延させる
  final memos = await dialogState.widget.memoRepository.memoStream.firstWhere(
    (memos) => memos.isNotEmpty,
  );

  final memo = memos.first;
  expect(memo.category.value?.name, categoryName);
  expect(memo.content, content);

  await tester.pumpAndSettle();

  // メモ追加ダイアログが閉じているはず
  expect(find.byType(MemoUpsertDialog), findsNothing);
}

/// メモを1件更新する
Future<void> _updateMemo(
  WidgetTester tester, {
  required Memo memo,
  required String categoryName,
  required String content,
}) async {
  // メモをタップしてメモ更新ダイアログを表示する
  await tester.tap(find.text(memo.content));
  await tester.pump();

  // メモ追加ダイアログが開いているはず
  expect(find.byType(MemoUpsertDialog), findsOneWidget);

  final dialogState =
      tester.state(find.byType(MemoUpsertDialog)) as MemoUpsertDialogState;

  // カテゴリが読み込まれるまで待つ
  await Future.doWhile(() async {
    await Future<void>.delayed(Duration.zero);
    return dialogState.categories.isEmpty;
  });
  await tester.pumpAndSettle();

  // カテゴリを変更する
  await tester.tap(find.byType(DropdownButton<Category>));
  await tester.pumpAndSettle();

  // DropDownButtonは実体と表示の2つが存在するので、lastをつける必要がある
  await tester.tap(find.text(categoryName).last);
  await tester.pumpAndSettle();

  expect(dialogState.selectedCategory?.name, categoryName);

  // コンテンツを入力する
  await tester.enterText(find.byType(TextField), content);
  await tester.pumpAndSettle();

  // 保存ボタン押下
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();

  // ストリームを受信するまで遅延させる
  final memos = await dialogState.widget.memoRepository.memoStream.firstWhere(
    (memos) => memos.isNotEmpty,
  );

  final updatedMemo = memos.first;
  expect(updatedMemo.category.value?.name, categoryName);
  expect(updatedMemo.content, content);

  await tester.pumpAndSettle();

  // メモ追加ダイアログが閉じているはず
  expect(find.byType(MemoUpsertDialog), findsNothing);
}
