import 'package:flutter/material.dart';

import 'memo_index_page.dart';
import 'memo_repository.dart';

/// メモアプリ
class App extends StatelessWidget {
  const App({
    super.key,
    required this.memoRepository,
  });

  /// メモリポジトリ
  final MemoRepository memoRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'メモ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MemoIndexPage(memoRepository: memoRepository),
    );
  }
}
