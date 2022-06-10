import 'package:flutter/material.dart';
import 'package:flutter_sample_isar/collections/category.dart';
import 'package:flutter_sample_isar/collections/memo.dart';
import 'package:flutter_sample_isar/memo_index_page.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils/test_agent.dart';

class MockApp extends StatelessWidget {
  const MockApp({
    super.key,
    required this.memoRepository,
  });

  final MemoRepository memoRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MemoIndexPage(
        memoRepository: memoRepository,
      ),
    );
  }
}

void main() {
  final agent = TestAgent();
  late MockApp mockApp;
  setUp(() async {
    await agent.setUp();
    mockApp = MockApp(memoRepository: agent.getMemoRepository());
  });
  tearDown(agent.tearDown);

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
        await addMemo(
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

        // メモが更新されるまで待つ
        await state.widget.memoRepository.memoStream.first;

        // メモが0件になっているはず
        expect(state.memos.length, 0);
      });
    });
    testWidgets('メモを更新すると一番先頭に移動するはず', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(mockApp);

        // メモを3件登録する
        final state =
            tester.state(find.byType(MemoIndexPage)) as MemoIndexPageState;
        final categories = await state.widget.memoRepository.findCategories();
        for (var i = 0; i < 3; i++) {
          await addMemo(
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
        await updateMemo(
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
  });
  group('MemoUpsertDialog', () {
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
Future<void> addMemo(
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

  // 現在のメモ数を控えておく
  final memoRepository = dialogState.widget.memoRepository;
  final firstMemos = await memoRepository.findMemos();

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

  // メモ一覧が更新されるまで待つ
  final secondMemos = await memoRepository.memoStream.first;

  // メモ数が1増えているはず
  expect(firstMemos.length + 1, secondMemos.length);

  // 1番目にメモが登録されているはず
  final memo = secondMemos.first;
  expect(memo.category.value?.name, categoryName);
  expect(memo.content, content);

  // ダイアログが閉じるまで待つ
  await tester.pumpAndSettle();

  // メモ追加ダイアログが閉じているはず
  expect(find.byType(MemoUpsertDialog), findsNothing);
}

/// メモを1件更新する
Future<void> updateMemo(
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

  // 現在のメモ数を控えておく
  final memoRepository = dialogState.widget.memoRepository;
  final firstMemos = await memoRepository.findMemos();

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

  // メモ一覧が更新されるまで待つ
  final secondMemos = await memoRepository.memoStream.first;

  // メモ数は同じはず
  expect(firstMemos.length, secondMemos.length);

  // 更新したメモが1番目にきているはず
  final updatedMemo = secondMemos.first;
  expect(updatedMemo.category.value?.name, categoryName);
  expect(updatedMemo.content, content);

  // ダイアログが閉じるまで待つ
  await tester.pumpAndSettle();

  // メモ追加ダイアログが閉じているはず
  expect(find.byType(MemoUpsertDialog), findsNothing);
}
