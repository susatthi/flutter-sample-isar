import 'package:flutter/material.dart';
import 'package:flutter_sample_isar/app.dart';
import 'package:flutter_sample_isar/memo_index_page.dart';
import 'package:flutter_sample_isar/memo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils/test_agent.dart';

void main() {
  final agent = TestAgent();
  late MemoRepository repository;
  late Widget app;

  setUp(() async {
    await agent.setUp();
    repository = MemoRepository(agent.isarTestAgent.isar);
    app = App(
      memoRepository: repository,
    );
  });

  tearDown(() async {
    repository.dispose();
    await agent.tearDown();
  });

  group('App', () {
    testWidgets('表示するとメモ一覧画面が表示されるはず', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(app);
      });

      // MemoIndexPage がいるはず
      expect(find.byType(MemoIndexPage), findsOneWidget);

      // メモは0件のはず
      final state =
          tester.state(find.byType(MemoIndexPage)) as MemoIndexPageState;
      expect(state.memos.length, 0);
    });
  });
}
