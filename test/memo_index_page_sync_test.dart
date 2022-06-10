import 'package:flutter/material.dart';
import 'package:flutter_sample_isar/memo_index_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memo_index_page_test.dart' as memo_index_page_test;
import 'test_utils/test_agent.dart';

void main() {
  final agent = TestAgent();
  late memo_index_page_test.MockApp mockApp;
  setUp(() async {
    await agent.setUp();
    mockApp = memo_index_page_test.MockApp(
      memoRepository: agent.getMemoRepository(sync: true),
    );
  });
  tearDown(agent.tearDown);

  group('MemoIndexPage(sync)', () {
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
        await memo_index_page_test.addMemo(
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
          await memo_index_page_test.addMemo(
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
        await memo_index_page_test.updateMemo(
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
  group('MemoUpsertDialog(sync)', () {
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
