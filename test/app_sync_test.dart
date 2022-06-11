import 'package:flutter_sample_isar/app.dart';
import 'package:flutter_sample_isar/memo_index_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils/test_agent.dart';

void main() {
  final agent = TestAgent();
  late App app;
  setUp(() async {
    await agent.setUp();
    app = App(
      memoRepository: agent.getMemoRepository(sync: true),
    );
  });

  tearDown(agent.tearDown);

  group('App(sync)', () {
    testWidgets('表示するとメモ一覧画面が表示されるはず', (tester) async {
      await tester.pumpWidget(app);

      // MemoIndexPage がいるはず
      expect(find.byType(MemoIndexPage), findsOneWidget);

      // メモは0件のはず
      final state =
          tester.state(find.byType(MemoIndexPage)) as MemoIndexPageState;
      expect(state.memos.length, 0);
    });
  });
}
