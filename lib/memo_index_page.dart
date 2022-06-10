import 'dart:async';

import 'package:flutter/material.dart';

import 'collections/category.dart';
import 'collections/memo.dart';
import 'memo_repository.dart';

/// メモ一覧画面
class MemoIndexPage extends StatefulWidget {
  const MemoIndexPage({
    super.key,
    required this.memoRepository,
  });

  /// メモリポジトリ
  final MemoRepository memoRepository;

  @override
  State<MemoIndexPage> createState() => MemoIndexPageState();
}

@visibleForTesting
class MemoIndexPageState extends State<MemoIndexPage> {
  /// 表示するメモ一覧
  final memos = <Memo>[];

  @override
  void initState() {
    super.initState();

    // メモ一覧を取得して画面を更新する
    Future(() async {
      _refresh(await widget.memoRepository.findMemos());
    });

    /// メモ一覧を監視して変化があれば画面を更新する
    widget.memoRepository.memoStream.listen(_refresh);
  }

  /// メモ一覧画面を更新する
  void _refresh(List<Memo> memos) {
    if (!mounted) {
      return;
    }

    setState(() {
      this.memos
        ..clear()
        ..addAll(memos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final memo = memos[index];
          final category = memo.category.value;
          return ListTile(
            // タップされたらメモ更新ダイアログを表示する
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => MemoUpsertDialog(
                widget.memoRepository,
                memo: memo,
              ),
              barrierDismissible: false,
            ),
            title: Text(memo.content),
            subtitle: Text(category?.name ?? ''),
            // 削除ボタン押下されたらメモを即削除する
            trailing: IconButton(
              onPressed: () => widget.memoRepository.deleteMemo(memo),
              icon: const Icon(Icons.close),
            ),
          );
        },
        itemCount: memos.length,
      ),
      floatingActionButton: FloatingActionButton(
        // メモ追加ダイアログを表示する
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => MemoUpsertDialog(widget.memoRepository),
          barrierDismissible: false,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// メモ登録/更新ダイアログ
class MemoUpsertDialog extends StatefulWidget {
  const MemoUpsertDialog(
    this.memoRepository, {
    super.key,
    this.memo,
  });

  /// メモリポジトリ
  final MemoRepository memoRepository;

  /// 更新するメモ（登録時はnull）
  final Memo? memo;

  @override
  State<MemoUpsertDialog> createState() => MemoUpsertDialogState();
}

@visibleForTesting
class MemoUpsertDialogState extends State<MemoUpsertDialog> {
  /// 表示するカテゴリ一覧
  final categories = <Category>[];

  /// 選択中のカテゴリ
  Category? _selectedCategory;
  Category? get selectedCategory => _selectedCategory;

  /// 入力中のメモコンテンツ
  final _textController = TextEditingController();
  String get content => _textController.text;

  @override
  void initState() {
    super.initState();

    Future(() async {
      // カテゴリ一覧を取得する
      categories.addAll(await widget.memoRepository.findCategories());

      // 初期値を設定する
      _selectedCategory = categories.firstWhere(
        (category) => category.id == widget.memo?.category.value?.id,
        orElse: () => categories.first,
      );
      _textController.text = widget.memo?.content ?? '';

      // 再描画する
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            // カテゴリはドロップボタンで選択する
            DropdownButton<Category>(
              value: _selectedCategory,
              items: categories
                  .map(
                    (category) => DropdownMenuItem<Category>(
                      value: category,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              isExpanded: true,
            ),
            TextField(
              controller: _textController,
              onChanged: (_) {
                // 「保存」ボタンの活性化/非活性化を更新するために画面更新する
                setState(() {});
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          // 入力中のメモコンテンツが1文字以上あるときだけ「保存」ボタンを活性化する
          onPressed: content.isNotEmpty
              ? () async {
                  final memo = widget.memo;
                  if (memo == null) {
                    // 登録処理
                    await widget.memoRepository.addMemo(
                      category: _selectedCategory!,
                      content: content,
                    );
                  } else {
                    // 更新処理
                    await widget.memoRepository.updateMemo(
                      memo: memo,
                      category: _selectedCategory!,
                      content: content,
                    );
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
